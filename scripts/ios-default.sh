#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/ios-default.sh --destination DESTINATION --source-packages PATH \
  --derived-data PATH --results PATH

Resolve packages, build the iPad app, and run the Default Test Plan.
Paths are relative to the caller's working directory. Results must not contain
previous resolve.log/build.log/test.log or BettrBuild/BettrTest.xcresult files.
Xcode selection (DEVELOPER_DIR) and Simulator availability are caller responsibilities.
USAGE
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

destination=''
source_packages=''
derived_data=''
results=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --destination|--source-packages|--derived-data|--results)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1."
      case "$1" in
        --destination) destination="$2" ;;
        --source-packages) source_packages="$2" ;;
        --derived-data) derived_data="$2" ;;
        --results) results="$2" ;;
      esac
      shift 2
      ;;
    *) usage >&2; fail "Unknown argument: $1" ;;
  esac
done
[[ -n "$destination" && -n "$source_packages" && -n "$derived_data" && -n "$results" ]] || {
  usage >&2
  fail 'All four inputs are required.'
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="$repo_root/Bettr/Bettr.xcodeproj"
[[ -d "$project" ]] || fail 'Bettr Xcode project is missing.'
[[ -f "$project/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]] || fail 'Package.resolved is missing.'
command -v xcodebuild >/dev/null || fail 'xcodebuild is unavailable. Select a full Xcode installation.'
xcodebuild -version

mkdir -p -- "$source_packages" "$derived_data" "$results"
source_packages="$(cd -- "$source_packages" && pwd)"
derived_data="$(cd -- "$derived_data" && pwd)"
results="$(cd -- "$results" && pwd)"
for name in resolve.log build.log test.log BettrBuild.xcresult BettrTest.xcresult; do
  [[ ! -e "$results/$name" && ! -L "$results/$name" ]] || fail "Existing result: $results/$name. Choose a fresh results path."
done
cd "$repo_root"

# Capture both statuses immediately: tee must not hide an Xcode failure, and an
# incomplete log cannot serve as successful verification evidence.
run_xcode() {
  local phase="$1" marker="$2"
  shift 2
  local statuses
  set +e
  xcodebuild "$@" 2>&1 | tee "$results/$phase.log"
  statuses=("${PIPESTATUS[@]}")
  set -e
  if [[ "${statuses[0]}" -ne 0 ]]; then
    echo "Error: $phase failed (xcodebuild exit ${statuses[0]}). See $results/$phase.log." >&2
    exit "${statuses[0]}"
  fi
  if [[ "${statuses[1]}" -ne 0 ]]; then
    echo "Error: Could not save $phase output (tee exit ${statuses[1]})." >&2
    exit "${statuses[1]}"
  fi
  if [[ -n "$marker" ]] && ! grep -Fxq "$marker" "$results/$phase.log"; then
    fail "$phase exited 0 without $marker. Verification is incomplete; see $results/$phase.log."
  fi
}

common=(-project "$project" -scheme Bettr -clonedSourcePackagesDirPath "$source_packages")
run_xcode resolve '' -resolvePackageDependencies "${common[@]}"
run_xcode build '** BUILD SUCCEEDED **' build "${common[@]}" \
  -configuration Debug -destination "$destination" -derivedDataPath "$derived_data" \
  -resultBundlePath "$results/BettrBuild.xcresult" CODE_SIGNING_ALLOWED=NO
run_xcode test '** TEST SUCCEEDED **' test "${common[@]}" \
  -testPlan Default -destination "$destination" -derivedDataPath "$derived_data" \
  -resultBundlePath "$results/BettrTest.xcresult" CODE_SIGNING_ALLOWED=NO

echo "Default verification succeeded. Logs and result bundles: $results"
