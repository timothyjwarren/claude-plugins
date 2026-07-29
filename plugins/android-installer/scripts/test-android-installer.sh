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

# --- android-installer-install.sh: parse_args() ---

# shellcheck disable=SC1091
source "$BIN_DIR/android-installer-install.sh"

test_parse_args_ok() {
  local desc="$1" expected_apk="$2" expected_user="$3"
  shift 3
  APK=""
  USER_ID=""
  if parse_args "$@" && [[ "$APK" == "$expected_apk" && "$USER_ID" == "$expected_user" ]]; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc (APK=$APK USER_ID=$USER_ID)"
    fail=1
  fi
}

test_parse_args_fails() {
  local desc="$1"
  shift
  APK=""
  USER_ID=""
  if parse_args "$@" 2>/dev/null; then
    echo "FAIL: $desc (expected parse_args to fail)"
    fail=1
  else
    echo "PASS: $desc"
  fi
}

test_parse_args_ok "apk only" "app.apk" "" app.apk
test_parse_args_ok "--user before apk" "app.apk" "10" --user 10 app.apk
test_parse_args_ok "--user after apk" "app.apk" "10" app.apk --user 10
test_parse_args_fails "missing apk path" --user 10
test_parse_args_fails "--user with no value" app.apk --user
test_parse_args_fails "unknown flag" --bogus app.apk

exit $fail
