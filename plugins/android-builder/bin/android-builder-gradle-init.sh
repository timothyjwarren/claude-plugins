#!/bin/bash
set -uo pipefail

GRADLE_VERSION="8.13"
GRADLE_IMAGE="gradle:${GRADLE_VERSION}-jdk21"

TEMP="${TEMP:-/tmp}"
LOG_FILE="$TEMP/jvm-gradle-init-$(date +%Y%m%d-%H%M%S).log"

if [ -f "./gradlew" ]; then
  echo "gradle wrapper already present"
  exit 0
fi

docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  "$GRADLE_IMAGE" \
  gradle wrapper --gradle-version="$GRADLE_VERSION" \
  > "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "gradle wrapper initialized"
else
  echo "gradle init failed" >&2
  echo "log: $LOG_FILE" >&2
  exit "$EXIT_CODE"
fi
