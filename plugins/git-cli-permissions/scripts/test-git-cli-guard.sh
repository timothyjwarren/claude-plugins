#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/git-cli-guard.sh"

PASS=0
FAIL=0

# check_allow COMMAND
check_allow() {
  local cmd="$1"
  local payload
  payload=$(python3 -c 'import json,sys; print(json.dumps({"command": sys.argv[1]}))' "$cmd")
  local output
  output=$(echo "$payload" | "$GUARD")
  if echo "$output" | grep -q '"permissionDecision": *"allow"'; then
    PASS=$((PASS + 1))
  else
    echo "FAIL (expected allow): $cmd"
    echo "  got: $output"
    FAIL=$((FAIL + 1))
  fi
}

# check_defer COMMAND
check_defer() {
  local cmd="$1"
  local payload
  payload=$(python3 -c 'import json,sys; print(json.dumps({"command": sys.argv[1]}))' "$cmd")
  local output
  output=$(echo "$payload" | "$GUARD")
  if [ -z "$output" ]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL (expected defer): $cmd"
    echo "  got: $output"
    FAIL=$((FAIL + 1))
  fi
}

check_allow "git status"
check_allow "git add ."
check_allow "git commit -m msg"
check_allow "git fetch"
check_allow "git pull"
check_allow "git diff"
check_allow "git remote -v"
check_allow "gh pr view 123"
check_allow "gh pr list"
check_allow "gh issue view 5"
check_allow "git add . && git commit -m x"

check_defer "git remote add origin url"
check_defer "git clone url"
check_defer "git push"
check_defer "gh pr create"
check_defer "gh pr comment 1 --body hi"
check_defer "gh api repos/x/y"
check_defer "gh auth login"
check_defer "git add . && git push"
check_defer "git status && rm -rf foo"
check_defer "rm -rf foo"

echo ""
echo "$PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
