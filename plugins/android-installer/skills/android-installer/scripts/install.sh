#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <path-to-apk>" >&2
  exit 1
fi

APK="$1"

if [[ ! -f "$APK" ]]; then
  echo "error: file not found: $APK" >&2
  exit 1
fi

APK_ABS="$(cd "$(dirname "$APK")" && pwd)/$(basename "$APK")"

# Docker Desktop (Mac/Windows) exposes the host via host.docker.internal.
# Linux Docker uses the docker bridge gateway (host-gateway alias or 172.17.0.1).
if [[ "$(uname)" == "Darwin" || "$(uname)" == "MINGW"* || "$(uname)" == "MSYS"* ]]; then
  ADB_HOST="host.docker.internal"
else
  ADB_HOST="host-gateway"
fi

echo "Installing $(basename "$APK_ABS") via dockerized adb (server: $ADB_HOST:5037)..."

docker run --rm \
  --add-host=host-gateway:"$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}' 2>/dev/null || echo 172.17.0.1)" \
  -e ANDROID_ADB_SERVER_ADDRESS="$ADB_HOST" \
  -e ANDROID_ADB_SERVER_PORT=5037 \
  -v "$APK_ABS":/app.apk \
  mingc/android-build-box:latest \
  adb install /app.apk
