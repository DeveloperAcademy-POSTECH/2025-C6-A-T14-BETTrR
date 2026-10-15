#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-Bettr/Bettr.xcodeproj}"
SCHEME="${SCHEME:-Bettr}"
TEST_PLAN="${TEST_PLAN:-GeminiContract}"
SOURCE_PACKAGES="${SOURCE_PACKAGES:-${RUNNER_TEMP:-/tmp}/SourcePackages}"
DERIVED_DATA="${DERIVED_DATA:-${RUNNER_TEMP:-/tmp}/BettrGeminiContractDerivedData}"
RESULT_BUNDLE="${RESULT_BUNDLE:-${RUNNER_TEMP:-/tmp}/BettrGeminiContract.xcresult}"
SUMMARY_JSON="${SUMMARY_JSON:-${RUNNER_TEMP:-/tmp}/BettrGeminiContract-summary.json}"
RAW_SUMMARY_JSON=""
OWN_RESULT_BUNDLE=0
CREATED_SIMULATOR=""
RUN_DERIVED_DATA=""
GOOGLE_SERVICE_PLIST="${GOOGLE_SERVICE_PLIST:-Bettr/Bettr/GoogleService-Info.plist}"
EXPECTED_PASSED=2
EXPECTED_SKIPPED=0
XCODEBUILD_BIN="${XCODEBUILD_BIN:-xcodebuild}"
XCRUN_BIN="${XCRUN_BIN:-xcrun}"
RESTORED_GOOGLE_SERVICE_PLIST=0

check_config() {
  if [[ "${GEMINI_CONTRACT_ENABLED:-}" != "1" ]]; then
    echo "GEMINI_CONTRACT_ENABLED=1 is required for live Gemini contract tests."
    return 2
  fi

  if [[ -z "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" && ! -f "$GOOGLE_SERVICE_PLIST" ]]; then
    echo "GOOGLE_SERVICE_INFO_PLIST_BASE64 or an existing GoogleService-Info.plist is required."
    return 2
  fi

  if [[ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" && -e "$GOOGLE_SERVICE_PLIST" ]]; then
    echo "Refusing to overwrite an existing GoogleService-Info.plist."
    return 2
  fi

  if [[ ! "${FIREBASE_APP_CHECK_DEBUG_TOKEN:-}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
    echo "FIREBASE_APP_CHECK_DEBUG_TOKEN is required."
    return 2
  fi
}

cleanup() {
  rm -f "${RAW_XCODEBUILD_LOG:-}" "$RAW_SUMMARY_JSON"
  if [[ "$OWN_RESULT_BUNDLE" == "1" ]]; then
    rm -rf "$RESULT_BUNDLE"
  fi
  if [[ -n "$CREATED_SIMULATOR" ]]; then
    "$XCRUN_BIN" simctl delete "$CREATED_SIMULATOR" >/dev/null 2>&1 || true
  fi
  if [[ -n "$RUN_DERIVED_DATA" ]]; then
    rm -rf "$RUN_DERIVED_DATA"
  fi
  if [[ "$RESTORED_GOOGLE_SERVICE_PLIST" == "1" ]]; then
    rm -f "$GOOGLE_SERVICE_PLIST"
  fi
}

run_xcodebuild_sanitized() {
  local phase="$1"
  shift
  RAW_XCODEBUILD_LOG="$(mktemp)"
  set +e
  "$@" > "$RAW_XCODEBUILD_LOG" 2>&1
  local status=$?
  set -e
  if [[ "$status" != "0" ]]; then
    echo "xcodebuild exit code: $status ($phase)"
    python3 scripts/gemini-contract/sanitize_xcodebuild_failure.py "$RAW_XCODEBUILD_LOG"
    return "$status"
  fi
  if [[ "$phase" == "Gemini contract test" ]]; then
    if ! grep -Fq '** TEST SUCCEEDED **' "$RAW_XCODEBUILD_LOG"; then
      echo "GeminiContract failure: missing XCTest success marker"
      return 3
    fi
    echo "xcodebuild exit code: 0 (Gemini contract test)"
    echo "** TEST SUCCEEDED **"
  fi
  rm -f "$RAW_XCODEBUILD_LOG"
  RAW_XCODEBUILD_LOG=""
}

create_simulator_destination() {
  local runtime_id device_type_id
  runtime_id="$("$XCRUN_BIN" simctl list runtimes --json | jq -r '
    .runtimes[]
    | select(.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-2" and .isAvailable)
    | .identifier
  ')"
  device_type_id="$("$XCRUN_BIN" simctl list devicetypes --json | jq -r '
    .devicetypes[]
    | select(.name == "iPad Pro 11-inch (M4)")
    | .identifier
  ')"

  if [[ -z "$runtime_id" ]]; then
    echo "iOS 26.2 Simulator runtime is unavailable."
    return 3
  fi

  if [[ -z "$device_type_id" ]]; then
    echo "iPad Pro 11-inch (M4) device type is unavailable."
    return 3
  fi

  CREATED_SIMULATOR="$("$XCRUN_BIN" simctl create "BETTrR Gemini Contract iPad" "$device_type_id" "$runtime_id")"
  destination="platform=iOS Simulator,id=$CREATED_SIMULATOR"
}

run_contract_tests() {
  local destination="${DESTINATION:-}"
  if [[ -e "$RESULT_BUNDLE" || -e "$SUMMARY_JSON" ]]; then
    echo "Refusing to overwrite an existing contract result or summary."
    return 2
  fi
  trap cleanup EXIT
  RAW_SUMMARY_JSON="$(mktemp)"
  mkdir -p "$DERIVED_DATA"
  RUN_DERIVED_DATA="$(mktemp -d "$DERIVED_DATA/GeminiContract.XXXXXX")"
  OWN_RESULT_BUNDLE=1
  if [[ -z "$destination" ]]; then
    create_simulator_destination
  fi

  if [[ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]]; then
    python3 scripts/gemini-contract/restore_google_service_info.py \
      --output "$GOOGLE_SERVICE_PLIST"
    RESTORED_GOOGLE_SERVICE_PLIST=1
  fi

  local app_check_debug_token="$FIREBASE_APP_CHECK_DEBUG_TOKEN"
  export -n FIREBASE_APP_CHECK_DEBUG_TOKEN || true
  unset SIMCTL_CHILD_AppCheckDebugToken FIRAAppCheckDebugToken TEST_RUNNER_FIRAAppCheckDebugToken
  export TEST_RUNNER_AppCheckDebugToken="$app_check_debug_token"

  run_xcodebuild_sanitized "package resolution" \
    "$XCODEBUILD_BIN" -resolvePackageDependencies \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES"

  run_xcodebuild_sanitized "Gemini contract test" \
    "$XCODEBUILD_BIN" test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -testPlan "$TEST_PLAN" \
    -only-testing:BettrTests/GeminiContractTests/test_scriptAnalysis_preservesStructuralContract \
    -only-testing:BettrTests/GeminiContractTests/test_wordExtraction_preservesStructuralContract \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 90 \
    -maximum-test-execution-time-allowance 90 \
    -collect-test-diagnostics never \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES" \
    -derivedDataPath "$RUN_DERIVED_DATA" \
    -resultBundlePath "$RESULT_BUNDLE" \
    CODE_SIGNING_ALLOWED=NO

  "$XCRUN_BIN" xcresulttool get test-results summary \
    --path "$RESULT_BUNDLE" \
    --compact > "$RAW_SUMMARY_JSON"

  python3 scripts/gemini-contract/validate_xcresult_summary.py \
    "$RAW_SUMMARY_JSON" \
    --expected-passed "$EXPECTED_PASSED" \
    --expected-skipped "$EXPECTED_SKIPPED" \
    --write-sanitized "$SUMMARY_JSON"

  cat "$SUMMARY_JSON"
}

case "${1:-run}" in
  --check-config)
    check_config
    ;;
  run)
    check_config
    run_contract_tests
    ;;
  *)
    echo "usage: $0 [run|--check-config]"
    exit 64
    ;;
esac
