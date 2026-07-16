#!/bin/bash
set -uo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'USAGE'
Usage: git-cli-permissions-test.sh

Runs the git-cli-permissions plugin's test suite:
  - Python unit tests for the classification/parsing logic
    (plugins/git-cli-permissions/scripts/test_git_cli_guard_logic.py)
  - Bash script-level harness that exercises the real hook entrypoint
    (plugins/git-cli-permissions/scripts/test-git-cli-guard.sh)

No parameters or options. Must be run from the repository root.

Output: "success" or "failure" (details written to a temp log file).
Exit codes: 0 on success, non-zero on failure.
USAGE
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/git-cli-permissions"

TEMP="${TEMP:-/tmp}"
LOG_FILE="$TEMP/git-cli-permissions-test-$(date +%Y%m%d-%H%M%S).log"

{
  echo "=== unit tests ==="
  python3 "$PLUGIN_DIR/scripts/test_git_cli_guard_logic.py" -v
  UNIT_EXIT=$?

  echo ""
  echo "=== script harness ==="
  "$PLUGIN_DIR/scripts/test-git-cli-guard.sh"
  HARNESS_EXIT=$?
} > "$LOG_FILE" 2>&1

if [ "$UNIT_EXIT" -eq 0 ] && [ "$HARNESS_EXIT" -eq 0 ]; then
  echo "success"
  exit 0
else
  echo "failure"
  echo "log: $LOG_FILE" >&2
  exit 1
fi
