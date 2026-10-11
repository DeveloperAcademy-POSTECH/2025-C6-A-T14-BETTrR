#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_SOURCE="$REPO_ROOT/scripts/ios-default.sh"

pass_count=0
fail_count=0
current_test=""

fail() {
  echo "not ok - $current_test: $*" >&2
}

pass() {
  echo "ok - $current_test"
  pass_count=$((pass_count + 1))
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "$message: expected [$expected], got [$actual]"
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if [[ ! -f "$file" ]]; then
    fail "$message: missing file $file"
    return 1
  fi

  if ! grep -Fq -- "$needle" "$file"; then
    fail "$message: [$needle] not found in $file"
    return 1
  fi
}

assert_file_missing() {
  local file="$1"
  local message="$2"

  if [[ -e "$file" || -L "$file" ]]; then
    fail "$message: unexpected file $file"
    return 1
  fi
}

assert_file_lacks() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  if grep -Fq -- "$needle" "$file"; then
    fail "$message: unexpected [$needle] in $file"
    return 1
  fi
}

make_fixture() {
  local tmpdir="$1"

  mkdir -p "$tmpdir/fake-bin" "$tmpdir/repo/scripts" "$tmpdir/repo/Bettr/Bettr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
  cp "$SCRIPT_SOURCE" "$tmpdir/repo/scripts/ios-default.sh"
  chmod +x "$tmpdir/repo/scripts/ios-default.sh"
  touch "$tmpdir/repo/Bettr/Bettr.xcodeproj/project.pbxproj"
  touch "$tmpdir/repo/Bettr/Bettr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

  cat > "$tmpdir/fake-bin/xcodebuild" <<'FAKE_XCODEBUILD'
#!/usr/bin/env bash
set -u

mode="unknown"
for arg in "$@"; do
  case "$arg" in
    -version)
      if [[ "${FAKE_VERSION_EXIT:-0}" -ne 0 ]]; then
        echo "xcodebuild version failed" >&2
        exit "$FAKE_VERSION_EXIT"
      fi
      echo "Xcode 26.6"
      echo "Build version 17G45"
      exit 0
      ;;
    -resolvePackageDependencies)
      mode="resolve"
      ;;
    build)
      mode="build"
      ;;
    test)
      mode="test"
      ;;
  esac
done

record="${FAKE_RECORD:?}"
{
  printf 'MODE=%s\n' "$mode"
  printf 'ARGS='
  printf '<%s>' "$@"
  printf '\n'
} >> "$record"

case "$mode" in
  resolve)
    exit "${FAKE_RESOLVE_EXIT:-0}"
    ;;
  build)
    if [[ "${FAKE_BUILD_MARKER:-1}" == "1" ]]; then
      echo "** BUILD SUCCEEDED **"
    fi
    exit "${FAKE_BUILD_EXIT:-0}"
    ;;
  test)
    if [[ "${FAKE_TEST_MARKER:-1}" == "1" ]]; then
      echo "** TEST SUCCEEDED **"
    fi
    exit "${FAKE_TEST_EXIT:-0}"
    ;;
  *)
    echo "unexpected xcodebuild mode: $mode" >&2
    exit 99
    ;;
esac
FAKE_XCODEBUILD
  chmod +x "$tmpdir/fake-bin/xcodebuild"

  cat > "$tmpdir/fake-bin/tee" <<'FAKE_TEE'
#!/usr/bin/env bash
set -u

target="${1:?}"
cat > "$target"
if [[ "${FAKE_TEE_EXIT:-0}" -ne 0 ]]; then
  exit "$FAKE_TEE_EXIT"
fi
cat "$target"
FAKE_TEE
  chmod +x "$tmpdir/fake-bin/tee"
}

run_script() {
  local tmpdir="$1"
  shift

  export FAKE_RECORD="$tmpdir/xcodebuild.record"
  PATH="$tmpdir/fake-bin:$PATH" "$tmpdir/repo/scripts/ios-default.sh" "$@" > "$tmpdir/stdout" 2> "$tmpdir/stderr"
  return $?
}

run_default() {
  local tmpdir="$1"
  shift

  run_script "$tmpdir" \
    --destination "platform=iOS Simulator,id=SIM" \
    --source-packages "$tmpdir/spm" \
    --derived-data "$tmpdir/derived" \
    --results "$tmpdir/results" \
    "$@"
}

run_case() {
  current_test="$1"
  shift

  local tmpdir
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/ios-default-test.XXXXXX")"
  tmpdir="$(cd "$tmpdir" && pwd)"
  make_fixture "$tmpdir"

  if "$@" "$tmpdir"; then
    pass
  else
    fail_count=$((fail_count + 1))
  fi

  rm -rf "$tmpdir"
}

case_happy_path() {
  local tmpdir="$1"
  local other_cwd="$tmpdir/other cwd"
  mkdir -p "$other_cwd"

  (
    cd "$other_cwd" || exit 97
    run_script "$tmpdir" \
      --destination "platform=iOS Simulator,name=iPad Pro 11-inch (M4)" \
      --source-packages "source packages" \
      --derived-data "derived data" \
      --results "results with spaces"
  )
  local status=$?
  local expected_repo expected_results expected_source_packages expected_derived_data
  expected_repo="$(cd "$tmpdir/repo" && pwd)"
  expected_results="$(cd "$other_cwd/results with spaces" && pwd)"
  expected_source_packages="$(cd "$other_cwd/source packages" && pwd)"
  expected_derived_data="$(cd "$other_cwd/derived data" && pwd)"

  assert_eq "0" "$status" "script exits successfully" || return 1
  assert_file_contains "$tmpdir/stdout" "Xcode 26.6" "version is printed before resolve" || return 1
  assert_file_contains "$expected_results/build.log" "** BUILD SUCCEEDED **" "build success marker is logged" || return 1
  assert_file_contains "$expected_results/test.log" "** TEST SUCCEEDED **" "test success marker is logged" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "MODE=resolve" "resolve command ran" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "MODE=build" "build command ran" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "MODE=test" "test command ran" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-project><$expected_repo/Bettr/Bettr.xcodeproj>" "project path is absolute" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-scheme><Bettr>" "scheme is Bettr" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-testPlan><Default>" "test plan is Default" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-configuration><Debug>" "build uses Debug configuration" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-destination><platform=iOS Simulator,name=iPad Pro 11-inch (M4)>" "destination is passed through" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-clonedSourcePackagesDirPath><$expected_source_packages>" "source package cache path is passed" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-derivedDataPath><$expected_derived_data>" "derived data path is passed" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-resultBundlePath><$expected_results/BettrBuild.xcresult>" "build result bundle path is fixed" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<-resultBundlePath><$expected_results/BettrTest.xcresult>" "test result bundle path is fixed" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "<CODE_SIGNING_ALLOWED=NO>" "codesigning is disabled" || return 1
}

case_missing_required_arg() {
  local tmpdir="$1"

  run_script "$tmpdir" \
    --source-packages "$tmpdir/spm" \
    --derived-data "$tmpdir/derived" \
    --results "$tmpdir/results"
  local status=$?

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "All four inputs are required." "missing argument is reported" || return 1
  assert_file_missing "$tmpdir/xcodebuild.record" "xcodebuild should not run for invalid arguments" || return 1
}

case_unknown_arg() {
  local tmpdir="$1"

  run_script "$tmpdir" --bogus
  local status=$?

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "Unknown argument: --bogus" "unknown argument is reported" || return 1
  assert_file_missing "$tmpdir/xcodebuild.record" "xcodebuild should not run for invalid arguments" || return 1
}

case_missing_package_resolved() {
  local tmpdir="$1"
  rm "$tmpdir/repo/Bettr/Bettr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

  run_default "$tmpdir"
  local status=$?

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "Package.resolved is missing." "missing package lock is reported" || return 1
  assert_file_missing "$tmpdir/xcodebuild.record" "xcodebuild should not run without Package.resolved" || return 1
}

case_version_failure_propagates() {
  local tmpdir="$1"
  export FAKE_VERSION_EXIT=22

  run_default "$tmpdir"
  local status=$?
  unset FAKE_VERSION_EXIT

  assert_eq "22" "$status" "xcodebuild -version exit propagates" || return 1
  assert_file_missing "$tmpdir/xcodebuild.record" "xcodebuild commands should not run after version failure" || return 1
}

case_existing_result_rejected() {
  local tmpdir="$1"
  local result_dir="$tmpdir/results"
  mkdir -p "$result_dir/BettrBuild.xcresult"

  run_script "$tmpdir" \
    --destination "platform=iOS Simulator,id=SIM" \
    --source-packages "$tmpdir/spm" \
    --derived-data "$tmpdir/derived" \
    --results "$result_dir"
  local status=$?

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "BettrBuild.xcresult" "existing build result is rejected" || return 1
  assert_file_missing "$tmpdir/xcodebuild.record" "xcodebuild should not run with stale result bundle" || return 1
}

case_existing_log_rejected() {
  local tmpdir="$1"
  local result_dir="$tmpdir/results"
  mkdir -p "$result_dir"
  touch "$result_dir/test.log"

  run_script "$tmpdir" \
    --destination "platform=iOS Simulator,id=SIM" \
    --source-packages "$tmpdir/spm" \
    --derived-data "$tmpdir/derived" \
    --results "$result_dir"
  local status=$?

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "test.log" "existing log is rejected" || return 1
  assert_file_missing "$tmpdir/xcodebuild.record" "xcodebuild should not run with stale log" || return 1
}

case_resolve_failure_propagates() {
  local tmpdir="$1"
  export FAKE_RESOLVE_EXIT=23

  run_default "$tmpdir"
  local status=$?
  unset FAKE_RESOLVE_EXIT

  assert_eq "23" "$status" "resolve exit propagates" || return 1
  assert_file_contains "$tmpdir/stderr" "resolve failed (xcodebuild exit 23)" "resolve failure is reported" || return 1
  assert_file_lacks "$tmpdir/xcodebuild.record" "MODE=build" "build should not run after resolve failure" || return 1
  assert_file_lacks "$tmpdir/xcodebuild.record" "MODE=test" "test should not run after resolve failure" || return 1
}

case_build_failure_propagates() {
  local tmpdir="$1"
  export FAKE_BUILD_EXIT=24

  run_default "$tmpdir"
  local status=$?
  unset FAKE_BUILD_EXIT

  assert_eq "24" "$status" "build exit propagates" || return 1
  assert_file_contains "$tmpdir/stderr" "build failed (xcodebuild exit 24)" "build failure is reported" || return 1
  assert_file_lacks "$tmpdir/xcodebuild.record" "MODE=test" "test should not run after build failure" || return 1
}

case_test_failure_propagates() {
  local tmpdir="$1"
  export FAKE_TEST_EXIT=25

  run_default "$tmpdir"
  local status=$?
  unset FAKE_TEST_EXIT

  assert_eq "25" "$status" "test exit propagates" || return 1
  assert_file_contains "$tmpdir/stderr" "test failed (xcodebuild exit 25)" "test failure is reported" || return 1
}

case_build_marker_required() {
  local tmpdir="$1"
  export FAKE_BUILD_MARKER=0

  run_default "$tmpdir"
  local status=$?
  unset FAKE_BUILD_MARKER

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "build exited 0 without ** BUILD SUCCEEDED **" "missing build marker is rejected" || return 1
  assert_file_lacks "$tmpdir/xcodebuild.record" "MODE=test" "test should not run after missing build marker" || return 1
}

case_test_marker_required() {
  local tmpdir="$1"
  export FAKE_TEST_MARKER=0

  run_default "$tmpdir"
  local status=$?
  unset FAKE_TEST_MARKER

  [[ "$status" -ne 0 ]] || { fail "script unexpectedly succeeded"; return 1; }
  assert_file_contains "$tmpdir/stderr" "test exited 0 without ** TEST SUCCEEDED **" "missing test marker is rejected" || return 1
}

case_nonzero_with_success_marker_fails() {
  local tmpdir="$1"
  export FAKE_BUILD_EXIT=26
  export FAKE_BUILD_MARKER=1

  run_default "$tmpdir"
  local status=$?
  unset FAKE_BUILD_EXIT
  unset FAKE_BUILD_MARKER

  assert_eq "26" "$status" "nonzero build exit wins even with success marker" || return 1
  assert_file_contains "$tmpdir/stderr" "build failed (xcodebuild exit 26)" "nonzero build failure is reported" || return 1
}

case_tee_failure_propagates() {
  local tmpdir="$1"
  export FAKE_TEE_EXIT=29

  run_default "$tmpdir"
  local status=$?
  unset FAKE_TEE_EXIT

  assert_eq "29" "$status" "tee exit propagates" || return 1
  assert_file_contains "$tmpdir/stderr" "Could not save resolve output (tee exit 29)" "tee failure is reported" || return 1
  assert_file_contains "$tmpdir/xcodebuild.record" "MODE=resolve" "resolve ran before tee failure" || return 1
  assert_file_lacks "$tmpdir/xcodebuild.record" "MODE=build" "build should not run after tee failure" || return 1
  assert_file_lacks "$tmpdir/xcodebuild.record" "MODE=test" "test should not run after tee failure" || return 1
}

run_case "happy path uses CI Default build and test contract" case_happy_path
run_case "missing required arguments fail before xcodebuild" case_missing_required_arg
run_case "unknown arguments fail before xcodebuild" case_unknown_arg
run_case "missing Package.resolved fails before xcodebuild" case_missing_package_resolved
run_case "xcodebuild version failure propagates" case_version_failure_propagates
run_case "existing result bundles are rejected" case_existing_result_rejected
run_case "existing logs are rejected" case_existing_log_rejected
run_case "resolve exit code propagates" case_resolve_failure_propagates
run_case "build exit code propagates" case_build_failure_propagates
run_case "test exit code propagates" case_test_failure_propagates
run_case "build success marker is required" case_build_marker_required
run_case "test success marker is required" case_test_marker_required
run_case "nonzero exit fails even with success marker" case_nonzero_with_success_marker_fails
run_case "tee failure propagates and stops later phases" case_tee_failure_propagates

if (( fail_count > 0 )); then
  echo "$fail_count failed, $pass_count passed" >&2
  exit 1
fi

echo "$pass_count passed"
