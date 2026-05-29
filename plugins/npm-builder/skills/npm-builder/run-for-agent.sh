#!/bin/bash
set -uo pipefail

PM="auto"
STREAM=0
PORT_FLAGS=()
NPM_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --pm=npm)    PM="npm" ;;
    --pm=bun)    PM="bun" ;;
    --pm=auto)   PM="auto" ;;
    --stream)    STREAM=1 ;;
    --port=*)
      SPEC="${arg#--port=}"
      # bare number → HOST:CONTAINER (same port on both sides)
      [[ "$SPEC" == *:* ]] || SPEC="$SPEC:$SPEC"
      PORT_FLAGS+=("-p" "$SPEC")
      ;;
    *)           NPM_ARGS+=("$arg") ;;
  esac
done

if [ "$PM" = "auto" ]; then
  if [ -f "./bun.lockb" ]; then
    PM="bun"
  else
    PM="npm"
  fi
fi

if [ "$PM" = "bun" ]; then
  IMAGE="oven/bun:latest"
  CACHE_DIR="$HOME/.bun"
  CACHE_MOUNT="/root/.bun"
else
  IMAGE="node:lts-alpine"
  CACHE_DIR="$HOME/.npm"
  CACHE_MOUNT="/root/.npm"
fi

if [ ${#NPM_ARGS[@]} -eq 0 ]; then
  NPM_ARGS=("run" "build")
fi

PLATFORM_FLAG="--platform linux/amd64"
if [ "$(uname -m)" = "arm64" ]; then
  PLATFORM_FLAG="--platform linux/arm64"
fi

TEMP="${TEMP:-/tmp}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$TEMP/npm-build-$TIMESTAMP.log"

mkdir -p "$CACHE_DIR"

if [ "$STREAM" -eq 1 ]; then
  docker run --rm $PLATFORM_FLAG \
    "${PORT_FLAGS[@]+"${PORT_FLAGS[@]}"}" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    -v "$CACHE_DIR:$CACHE_MOUNT" \
    "$IMAGE" \
    "$PM" "${NPM_ARGS[@]}"
  exit $?
fi

docker run --rm $PLATFORM_FLAG \
  "${PORT_FLAGS[@]+"${PORT_FLAGS[@]}"}" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  -v "$CACHE_DIR:$CACHE_MOUNT" \
  "$IMAGE" \
  "$PM" "${NPM_ARGS[@]}" \
  > "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "run succeeded"
else
  echo "run failed" >&2
  echo "log: $LOG_FILE" >&2
  exit "$EXIT_CODE"
fi
