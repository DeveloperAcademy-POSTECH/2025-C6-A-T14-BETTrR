#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/repo/scripts" "$tmpdir/repo/Bettr/BettrAI" "$tmpdir/bin" "$tmpdir/other cwd"
cp "$repo_root/scripts/bettr-ai-test.sh" "$tmpdir/repo/scripts/"
touch "$tmpdir/repo/Bettr/BettrAI/Package.swift" "$tmpdir/repo/Bettr/BettrAI/Package.resolved"
cat > "$tmpdir/bin/swift" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '<%s>\n' "$@" > "$MOCK_ARGUMENTS"
case "${MOCK_REPORT:-passed}" in
  passed) printf "Test Suite 'Selected tests' passed at fixture.\n\t Executed 1 test, with 0 failures (0 unexpected) in 0.001 seconds\n" ;;
  empty) printf "Test Suite 'Selected tests' passed at fixture.\n\t Executed 0 tests, with 0 failures (0 unexpected) in 0.001 seconds\n" ;;
  failed) printf "Test Suite 'Selected tests' failed at fixture.\n\t Executed 1 test, with 1 failure (1 unexpected) in 0.001 seconds\n" ;;
  skipped) printf "Test Suite 'Selected tests' passed at fixture.\n\t Executed 1 test, with 1 test skipped and 0 failures (0 unexpected) in 0.001 seconds\n" ;;
  summary-failure) printf "Test Suite 'Selected tests' passed at fixture.\n\t Executed 1 test, with 1 failure (1 unexpected) in 0.001 seconds\n" ;;
  malformed) echo "Test Suite 'Selected tests' passed at fixture." ;;
  missing) ;;
esac
exit "${MOCK_EXIT:-0}"
MOCK
chmod +x "$tmpdir/bin/swift"
cat > "$tmpdir/bin/tee" <<'MOCK'
#!/usr/bin/env bash
cat > "$1"
cat "$1"
exit "${MOCK_TEE_EXIT:-0}"
MOCK
chmod +x "$tmpdir/bin/tee"
export PATH="$tmpdir/bin:$PATH" MOCK_ARGUMENTS="$tmpdir/arguments"
script="$tmpdir/repo/scripts/bettr-ai-test.sh"
count=0
run_case() {
  local description="$1" expected="$2"
  shift 2
  count=$((count + 1))
  local status=0
  env "$@" "$script" --scratch-path "$tmpdir/scratch with spaces" --results "$tmpdir/results-$count" > "$tmpdir/output-$count" 2>&1 || status=$?
  if [[ "$status" != "$expected" ]]; then
    echo "FAIL: $description expected $expected got $status"
    cat "$tmpdir/output-$count"
    exit 1
  fi
  if [[ "$expected" != 0 ]] && grep -Fq 'BettrAI verification succeeded:' "$tmpdir/output-$count"; then
    echo "FAIL: $description published success evidence"
    exit 1
  fi
  echo "ok - $description"
}
cd "$tmpdir/other cwd"
run_case 'Non-hosted package tests from another working directory' 0
for arg in test --package-path "$tmpdir/repo/Bettr/BettrAI" --force-resolved-versions --scratch-path "$tmpdir/scratch with spaces" '^BettrAITests\.'; do
  grep -Fxq -- "<$arg>" "$tmpdir/arguments"
done
grep -Fq 'BettrAI verification succeeded: 1 tests passed without an app host.' "$tmpdir/output-1"
run_case 'swift exit propagates even with a success report' 37 MOCK_EXIT=37
run_case 'tee exit propagates' 29 MOCK_TEE_EXIT=29
for report in empty failed skipped summary-failure malformed missing; do
  run_case "$report test report cannot pass" 1 MOCK_REPORT="$report"
done
status=0
"$script" --scratch-path "$tmpdir/scratch" --results "$tmpdir/results-1" > "$tmpdir/stale-output" 2>&1 || status=$?
[[ "$status" == 1 ]]
grep -Fq 'Existing result:' "$tmpdir/stale-output"
status=0
"$script" --results "$tmpdir/invalid" > "$tmpdir/invalid-output" 2>&1 || status=$?
[[ "$status" == 1 ]]
grep -Fq 'Both inputs are required.' "$tmpdir/invalid-output"
rm "$tmpdir/repo/Bettr/BettrAI/Package.resolved"
run_case 'Missing lockfile fails before swift test' 1
grep -Fq 'BettrAI Package.resolved is missing.' "$tmpdir/output-$count"
echo 'BettrAI runner regression tests passed.'
