#!/usr/bin/env bash
# Lists Android user IDs (profiles) and the device's hardware serial on the
# connected device. Use before installing to a work profile or other
# non-default user via `android-installer-install.sh --user <id>`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

parse_users() {
  # $1: raw `pm list users` output. Prints "<id>  <name>" per line.
  echo "$1" | grep -oE 'UserInfo\{[0-9]+:[^:]*:[0-9a-fA-F]+\}' | while IFS= read -r entry; do
    body="${entry#UserInfo\{}"
    body="${body%\}}"
    id="${body%%:*}"
    rest="${body#*:}"
    name="${rest%%:*}"
    printf '%-8s %s\n' "$id" "$name"
  done
}

main() {
  local raw_users serial
  raw_users="$("$ROOT/android-installer-adb" shell pm list users)"
  serial="$("$ROOT/android-installer-adb" shell getprop ro.serialno | tr -d '\r\n')"

  echo "Device serial: $serial"
  echo
  echo "User ID  Name"
  parse_users "$raw_users"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
