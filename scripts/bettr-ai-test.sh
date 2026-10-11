#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: scripts/bettr-ai-test.sh --scratch-path PATH --results PATH'
  echo 'Run credential-free BettrAI XCTest tests on macOS without an app host.'
  echo 'Paths are relative to the caller. Results must not contain test.log.'
}
fail() { echo "Error: $*" >&2; exit 1; }

scratch_path=''
results=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --scratch-path|--results)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1."
      case "$1" in
        --scratch-path) scratch_path="$2" ;;
        --results) results="$2" ;;
      esac
      shift 2 ;;
    *) usage >&2; fail "Unknown argument: $1" ;;
  esac
done
[[ -n "$scratch_path" && -n "$results" ]] || { usage >&2; fail 'Both inputs are required.'; }
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package="$repo_root/Bettr/BettrAI"
[[ -f "$package/Package.swift" ]] || fail 'BettrAI Package.swift is missing.'
[[ -f "$package/Package.resolved" ]] || fail 'BettrAI Package.resolved is missing.'
command -v swift >/dev/null || fail 'swift is unavailable. Select a full Xcode installation.'
command -v python3 >/dev/null || fail 'python3 is unavailable.'
mkdir -p -- "$scratch_path" "$results"
scratch_path="$(cd -- "$scratch_path" && pwd)"
results="$(cd -- "$results" && pwd)"
for name in test.log; do
  [[ ! -e "$results/$name" && ! -L "$results/$name" ]] || fail "Existing result: $results/$name. Choose a fresh results path."
done

set +e
swift test --package-path "$package" --force-resolved-versions \
  --scratch-path "$scratch_path" --filter '^BettrAITests\.' 2>&1 | tee "$results/test.log"
statuses=("${PIPESTATUS[@]}")
set -e
if [[ "${statuses[0]}" -ne 0 ]]; then
  echo "Error: BettrAI tests failed (swift exit ${statuses[0]}). See $results/test.log." >&2
  exit "${statuses[0]}"
fi
if [[ "${statuses[1]}" -ne 0 ]]; then
  echo "Error: Could not save test output (tee exit ${statuses[1]})." >&2
  exit "${statuses[1]}"
fi

# Exit zero alone is insufficient: a mismatched filter can run zero tests.
# swiftbuild does not consistently emit --xunit-output, so inspect the final
# selected XCTest suite's success marker and nonempty, failure/skip-free summary.
python3 - "$results/test.log" <<'PYTHON'
import re
import sys
from pathlib import Path

log = Path(sys.argv[1]).read_text(encoding="utf-8")
summary = re.search(
    r"Test Suite 'Selected tests' passed at [^\n]+\n"
    r"\s*Executed ([1-9][0-9]*) tests?, with 0 failures \(0 unexpected\)",
    log,
)
if summary is None:
    raise SystemExit("Error: Missing, empty, failed, or skipped BettrAI test results.")
print(f"BettrAI verification succeeded: {summary.group(1)} tests passed without an app host.")
PYTHON
