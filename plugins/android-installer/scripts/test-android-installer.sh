#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

fail=0

# --- android-installer-list-users.sh: parse_users() ---

# shellcheck disable=SC1091
source "$BIN_DIR/android-installer-list-users.sh"

test_parse_users() {
  local desc="$1" fixture="$2" expected="$3"
  local actual
  actual="$(parse_users "$fixture")"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc"
    echo "  expected: $(printf '%q' "$expected")"
    echo "  actual:   $(printf '%q' "$actual")"
    fail=1
  fi
}

FIXTURE_TWO_USERS=$'Users:\n\tUserInfo{0:Owner:c13} running\n\tUserInfo{10:Work profile:1030} running'
EXPECTED_TWO_USERS=$'0        Owner\n10       Work profile'
test_parse_users "two users (owner + work profile)" "$FIXTURE_TWO_USERS" "$EXPECTED_TWO_USERS"

FIXTURE_ONE_USER=$'Users:\n\tUserInfo{0:Owner:c13} running'
EXPECTED_ONE_USER='0        Owner'
test_parse_users "single user" "$FIXTURE_ONE_USER" "$EXPECTED_ONE_USER"

exit $fail
