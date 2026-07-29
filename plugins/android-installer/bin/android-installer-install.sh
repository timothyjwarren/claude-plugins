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

  local apk_abs adb_host
  apk_abs="$(cd "$(dirname "$APK")" && pwd)/$(basename "$APK")"

  # Docker Desktop (Mac/Windows) exposes the host via host.docker.internal.
  # Linux Docker uses the docker bridge gateway (host-gateway alias or 172.17.0.1).
  if [[ "$(uname)" == "Darwin" || "$(uname)" == "MINGW"* || "$(uname)" == "MSYS"* ]]; then
    adb_host="host.docker.internal"
  else
    adb_host="host-gateway"
  fi

  local -a install_args=(install)
  if [[ -n "$USER_ID" ]]; then
    install_args+=(--user "$USER_ID")
  fi
  install_args+=(/app.apk)

  echo "Installing $(basename "$apk_abs") via dockerized adb (server: $adb_host:5037)${USER_ID:+, user $USER_ID}..."

  docker run --rm \
    --add-host=host-gateway:"$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}' 2>/dev/null || echo 172.17.0.1)" \
    -e ANDROID_ADB_SERVER_ADDRESS="$adb_host" \
    -e ANDROID_ADB_SERVER_PORT=5037 \
    -v "$apk_abs":/app.apk \
    mingc/android-build-box:latest \
    adb "${install_args[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
