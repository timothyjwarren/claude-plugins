#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--user <id>] <path-to-apk>" >&2
}

parse_args() {
  # Sets globals APK and USER_ID ("" means default/personal profile).
  APK=""
  USER_ID=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user)
        if [[ $# -lt 2 ]]; then
          echo "error: --user requires an argument" >&2
          return 1
        fi
        USER_ID="$2"
        shift 2
        ;;
      --user=*)
        USER_ID="${1#--user=}"
        shift
        ;;
      -*)
        echo "error: unknown option: $1" >&2
        return 1
        ;;
      *)
        if [[ -n "$APK" ]]; then
          echo "error: unexpected extra argument: $1" >&2
          return 1
        fi
        APK="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$APK" ]]; then
    usage
    return 1
  fi
}

main() {
  parse_args "$@" || exit 1

  if [[ ! -f "$APK" ]]; then
    echo "error: file not found: $APK" >&2
    exit 1
  fi

  local apk_abs remote_apk script_dir
  apk_abs="$(cd "$(dirname "$APK")" && pwd)/$(basename "$APK")"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  remote_apk="/tmp/install-$$.apk"

  local -a install_args=(install)
  if [[ -n "$USER_ID" ]]; then
    install_args+=(--user "$USER_ID")
  fi
  install_args+=("$remote_apk")

  echo "Installing $(basename "$apk_abs") via the adb-server container${USER_ID:+, user $USER_ID}..."

  docker cp "$apk_abs" "adb-server:$remote_apk"
  local rc=0
  "$script_dir/android-installer-adb" "${install_args[@]}" || rc=$?
  docker exec adb-server rm -f "$remote_apk" >/dev/null 2>&1 || true
  exit "$rc"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
