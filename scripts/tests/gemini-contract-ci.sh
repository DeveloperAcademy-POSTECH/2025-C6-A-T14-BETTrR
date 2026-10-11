#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

assert_success() {
  local description="$1"
  local output
  shift
  output="$(mktemp)"
  if ! "$@" > "$output" 2>&1; then
    echo "FAIL: $description"
    cat "$output"
    rm -f "$output"
    exit 1
  fi
  rm -f "$output"
}

assert_failure() {
  local description="$1"
  local output
  shift
  output="$(mktemp)"
  if "$@" > "$output" 2>&1; then
    echo "FAIL: $description"
    cat "$output"
    rm -f "$output"
    exit 1
  fi
  rm -f "$output"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_success "Gemini adapter changes run contract CI" \
  python3 scripts/gemini-contract/impact.py Bettr/Bettr/Presentation/Services/Gemini/FirebaseGeminiAdapter.swift

assert_success "Package resolution changes run contract CI" \
  python3 scripts/gemini-contract/impact.py Bettr/Bettr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

assert_success ".github workflow changes keep leading dot and run contract CI" \
  python3 scripts/gemini-contract/impact.py .github/workflows/ios-gemini-contract.yml

assert_success "AI domain contract changes run contract CI" \
  python3 scripts/gemini-contract/impact.py Bettr/Bettr/Domain/AI/AIContracts.swift

assert_failure "Pure GRDB integration changes do not run contract CI" \
  python3 scripts/gemini-contract/impact.py Bettr/BettrTests/DatabaseIntegration/WordRepositoryTests.swift

assert_failure "Pure UI changes do not run contract CI" \
  python3 scripts/gemini-contract/impact.py Bettr/Bettr/Presentation/Features/Onboarding/OnboardingView.swift

assert_failure "Missing config fails instead of skipping" \
  env -i PATH="$PATH" bash scripts/gemini-contract/run.sh --check-config

cat > "$tmpdir/mock-xcodebuild" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_XCODEBUILD_LOG"
if [[ "${1:-}" == "test" ]]; then
  if [[ "${TEST_RUNNER_AppCheckDebugToken:-}" != "$MOCK_EXPECTED_APP_CHECK_TOKEN" ]]; then
    echo "GeminiContract failure: test runner AppCheckDebugToken was not forwarded"
    exit 66
  fi
  if [[ -n "${FIREBASE_APP_CHECK_DEBUG_TOKEN:-}" ]]; then
    echo "GeminiContract failure: raw Firebase App Check secret leaked into xcodebuild environment"
    exit 67
  fi
fi
if [[ "${MOCK_XCODEBUILD_FAIL_TEST:-}" == "1" && "${1:-}" == "test" ]]; then
  echo "raw SDK error with token $TEST_RUNNER_AppCheckDebugToken"
  echo "GeminiContract failure: responseContract"
  exit 37
fi
if [[ "${1:-}" == "test" ]]; then
  echo '** TEST SUCCEEDED **'
fi
exit 0
SH
chmod +x "$tmpdir/mock-xcodebuild"

cat > "$tmpdir/mock-xcrun" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_XCRUN_LOG"
if [[ "${1:-}" == "simctl" && "${2:-}" == "list" && "${3:-}" == "runtimes" ]]; then
  cat <<'JSON'
{"runtimes":[{"identifier":"com.apple.CoreSimulator.SimRuntime.iOS-26-2","isAvailable":true}]}
JSON
  exit 0
fi
if [[ "${1:-}" == "simctl" && "${2:-}" == "list" && "${3:-}" == "devicetypes" ]]; then
  cat <<'JSON'
{"devicetypes":[{"name":"iPad Pro 11-inch (M4)","identifier":"com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4"}]}
JSON
  exit 0
fi
if [[ "${1:-}" == "simctl" && "${2:-}" == "create" ]]; then
  echo "SIM-0000"
  exit 0
fi
if [[ "${1:-}" == "simctl" && "${2:-}" == "delete" ]]; then
  exit 0
fi
if [[ "${1:-}" == "xcresulttool" && "${2:-}" == "get" && "${3:-}" == "test-results" && "${4:-}" == "summary" ]]; then
  cat <<'JSON'
{"result":"Passed","totalTestCount":2,"passedTests":2,"failedTests":0,"skippedTests":0,"expectedFailures":0}
JSON
  exit 0
fi
exit 64
SH
chmod +x "$tmpdir/mock-xcrun"

touch "$tmpdir/GoogleService-Info.plist"
mkdir -p "$tmpdir/DerivedData/Build/Products"
touch "$tmpdir/DerivedData/Build/Products/BettrTests.xctestrun"

assert_success "Full runner accepts existing plist and writes sanitized summary" \
  env \
    PATH="$PATH" \
    GEMINI_CONTRACT_ENABLED=1 \
    FIREBASE_APP_CHECK_DEBUG_TOKEN=00000000-0000-0000-0000-000000000000 \
    GOOGLE_SERVICE_PLIST="$tmpdir/GoogleService-Info.plist" \
    RUNNER_TEMP="$tmpdir" \
    DERIVED_DATA="$tmpdir/DerivedData" \
    SUMMARY_JSON="$tmpdir/sanitized-summary.json" \
    RESULT_BUNDLE="$tmpdir/raw.xcresult" \
    MOCK_XCODEBUILD_LOG="$tmpdir/xcodebuild.log" \
    MOCK_XCRUN_LOG="$tmpdir/xcrun.log" \
    MOCK_EXPECTED_APP_CHECK_TOKEN=00000000-0000-0000-0000-000000000000 \
    XCODEBUILD_BIN="$tmpdir/mock-xcodebuild" \
    XCRUN_BIN="$tmpdir/mock-xcrun" \
    bash scripts/gemini-contract/run.sh

assert_success "Sanitized summary artifact is produced" \
  test -s "$tmpdir/sanitized-summary.json"

assert_success "Existing local plist is preserved" \
  test -f "$tmpdir/GoogleService-Info.plist"

assert_success "Raw result bundle is cleaned up" \
  test ! -e "$tmpdir/raw.xcresult"

assert_success "Pre-existing user build manifests are preserved" \
  test -e "$tmpdir/DerivedData/Build/Products/BettrTests.xctestrun"

assert_success "xcodebuild disables parallel contract execution" \
  grep -F -- "-parallel-testing-enabled NO" "$tmpdir/xcodebuild.log"

assert_failure "xcodebuild uses the default single test execution" \
  grep -F -- "-test-iterations" "$tmpdir/xcodebuild.log"

assert_success "xcodebuild enables per-test timeout safety" \
  grep -F -- "-test-timeouts-enabled YES" "$tmpdir/xcodebuild.log"

assert_success "xcodebuild caps default per-test timeout at 90 seconds" \
  grep -F -- "-default-test-execution-time-allowance 90" "$tmpdir/xcodebuild.log"

assert_success "xcodebuild caps maximum per-test timeout at 90 seconds" \
  grep -F -- "-maximum-test-execution-time-allowance 90" "$tmpdir/xcodebuild.log"

assert_failure "xcodebuild does not enable retry-on-failure" \
  grep -F -- "-retry-tests-on-failure" "$tmpdir/xcodebuild.log"

assert_success "xcodebuild runs only the two live contract methods" \
  grep -F -- "-only-testing:BettrTests/GeminiContractTests/test_scriptAnalysis_preservesStructuralContract" "$tmpdir/xcodebuild.log"

assert_success "xcodebuild runs the word extraction contract method" \
  grep -F -- "-only-testing:BettrTests/GeminiContractTests/test_wordExtraction_preservesStructuralContract" "$tmpdir/xcodebuild.log"

set +e
env \
  PATH="$PATH" \
  GEMINI_CONTRACT_ENABLED=1 \
  FIREBASE_APP_CHECK_DEBUG_TOKEN=11111111-1111-1111-1111-111111111111 \
  GOOGLE_SERVICE_PLIST="$tmpdir/GoogleService-Info.plist" \
  RUNNER_TEMP="$tmpdir" \
  SUMMARY_JSON="$tmpdir/failure-summary.json" \
  RESULT_BUNDLE="$tmpdir/failure.xcresult" \
  MOCK_XCODEBUILD_LOG="$tmpdir/failing-xcodebuild.log" \
  MOCK_XCRUN_LOG="$tmpdir/failing-xcrun.log" \
  MOCK_EXPECTED_APP_CHECK_TOKEN=11111111-1111-1111-1111-111111111111 \
  MOCK_XCODEBUILD_FAIL_TEST=1 \
  XCODEBUILD_BIN="$tmpdir/mock-xcodebuild" \
  XCRUN_BIN="$tmpdir/mock-xcrun" \
  bash scripts/gemini-contract/run.sh > "$tmpdir/failing-runner.out" 2>&1
status=$?
set -e
if [[ "$status" != "37" ]]; then
  echo "FAIL: Runner must preserve xcodebuild exit 37, got $status"
  cat "$tmpdir/failing-runner.out"
  exit 1
fi
assert_success "Runner emits sanitized failure category" \
  grep -F -- "GeminiContract failure: responseContract" "$tmpdir/failing-runner.out"
assert_success "Runner emits exact xcodebuild exit code" \
  grep -F -- "xcodebuild exit code: 37" "$tmpdir/failing-runner.out"
assert_failure "Runner output does not leak App Check token" \
  grep -F -- "11111111-1111-1111-1111-111111111111" "$tmpdir/failing-runner.out"
assert_failure "Runner output does not leak raw SDK error" \
  grep -F -- "raw SDK error" "$tmpdir/failing-runner.out"

python3 - <<'PY'
import importlib.util
import re
from pathlib import Path

spec = importlib.util.spec_from_file_location("impact", "scripts/gemini-contract/impact.py")
impact = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(impact)

workflow = Path(".github/workflows/ios-gemini-contract.yml").read_text(encoding="utf-8")
patterns = set(impact.RUN_PATTERNS)
for block in [workflow.split("  pull_request:", 1)[1].split("  push:", 1)[0],
              workflow.split("  push:", 1)[1].split("permissions:", 1)[0]]:
    paths = set(re.findall(r'^\s+- "([^"]+)"$', block, re.MULTILINE))
    # Only push has an extra quoted release branch pattern.
    paths.discard("release/**")
    if paths != patterns:
        raise SystemExit("workflow and impact selector paths differ")
PY

cat > "$tmpdir/passed.json" <<'JSON'
{
  "result": "Passed",
  "totalTestCount": 2,
  "passedTests": 2,
  "failedTests": 0,
  "skippedTests": 0,
  "expectedFailures": 0
}
JSON

assert_success "Two passed and zero skipped is accepted" \
  python3 scripts/gemini-contract/validate_xcresult_summary.py "$tmpdir/passed.json" --expected-passed 2 --expected-skipped 0

cat > "$tmpdir/empty.json" <<'JSON'
{
  "result": "Passed",
  "totalTestCount": 0,
  "passedTests": 0,
  "failedTests": 0,
  "skippedTests": 0,
  "expectedFailures": 0
}
JSON

assert_failure "Empty test summaries are rejected" \
  python3 scripts/gemini-contract/validate_xcresult_summary.py "$tmpdir/empty.json" --expected-passed 2 --expected-skipped 0

cat > "$tmpdir/skipped.json" <<'JSON'
{
  "result": "Passed",
  "totalTestCount": 2,
  "passedTests": 2,
  "failedTests": 0,
  "skippedTests": 1,
  "expectedFailures": 0
}
JSON

assert_failure "Skipped contract tests are rejected" \
  python3 scripts/gemini-contract/validate_xcresult_summary.py "$tmpdir/skipped.json" --expected-passed 2 --expected-skipped 0

cat > "$tmpdir/name-only.json" <<'JSON'
{
  "result": "Passed",
  "tests": [
    {"name": "GeminiContractTests/test_scriptAnalysis_preservesStructuralContract"},
    {"name": "GeminiContractTests/test_wordExtraction_preservesStructuralContract"}
  ]
}
JSON

assert_failure "Name-only summaries are rejected" \
  python3 scripts/gemini-contract/validate_xcresult_summary.py "$tmpdir/name-only.json" --expected-passed 2 --expected-skipped 0

cat > "$tmpdir/private-log.txt" <<'LOG'
GeminiContract failure: authentication secret-suffix-123
Raw SDK payload must never escape
GeminiContract failure: unexpected-provider-payload
LOG
python3 scripts/gemini-contract/sanitize_xcodebuild_failure.py "$tmpdir/private-log.txt" > "$tmpdir/safe-log.txt"
assert_success "Sanitizer emits a fixed category" grep -Fx "GeminiContract failure: authentication" "$tmpdir/safe-log.txt"
assert_failure "Sanitizer never copies error suffixes" grep -F "secret-suffix" "$tmpdir/safe-log.txt"
assert_failure "Sanitizer never copies unknown payloads" grep -F "provider-payload" "$tmpdir/safe-log.txt"

python3 - <<'PYTHON'
import importlib.util
spec = importlib.util.spec_from_file_location("summary", "scripts/gemini-contract/validate_xcresult_summary.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
valid = dict(result="Passed", totalTestCount=2, passedTests=2, failedTests=0, skippedTests=0, expectedFailures=0)
for malformed in [dict(valid, failedTests=False), dict(valid, expectedFailures=1),
                  dict(valid, passedTests="2"), dict(valid, result="Failed"),
                  dict(children=[valid]), {}, []]:
    try:
        module.validated_summary(malformed, 2, 0)
    except ValueError:
        continue
    raise SystemExit("Malformed result was accepted")
PYTHON

fixture_plist="$(python3 -c 'import base64, plistlib; print(base64.b64encode(plistlib.dumps(dict(PROJECT_ID="public-fixture"))).decode())')"
assert_success "Restoration writes a private plist" \
  env GOOGLE_SERVICE_INFO_PLIST_BASE64="$fixture_plist" python3 scripts/gemini-contract/restore_google_service_info.py --output "$tmpdir/restored.plist"
assert_success "Restored plist permissions are private" \
  python3 -c 'import os, sys; sys.exit(0 if os.stat(sys.argv[1]).st_mode & 0o777 == 0o600 else 1)' "$tmpdir/restored.plist"
assert_failure "Restoration cannot overwrite an existing plist" \
  env GOOGLE_SERVICE_INFO_PLIST_BASE64="$fixture_plist" python3 scripts/gemini-contract/restore_google_service_info.py --output "$tmpdir/GoogleService-Info.plist"
assert_success "Pre-existing plist remains untouched" test ! -s "$tmpdir/GoogleService-Info.plist"
assert_success "Created simulator is removed" grep -F "simctl delete SIM-0000" "$tmpdir/xcrun.log"
assert_success "Per-run build data is removed" test -z "$(find "$tmpdir/DerivedData" -name 'GeminiContract.*' -type d -print)"

echo "Gemini contract CI script tests passed."
