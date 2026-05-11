#!/bin/bash
set -uo pipefail

KOTLIN_IMAGE="eclipse-temurin:21.0.5_11-jdk-noble"
ANDROID_IMAGE="dev-jvm-android:1.0"

MODE=""
GRADLE_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --mode=standard) MODE="standard" ;;
    --mode=android)  MODE="android"  ;;
    *)               GRADLE_ARGS+=("$arg") ;;
  esac
done

if [ -z "$MODE" ]; then
  echo "build failed: --mode=standard or --mode=android required" >&2
  exit 1
fi

if [ ! -f "./gradlew" ]; then
  echo "build failed: ./gradlew not found; run gradle-init.sh first" >&2
  exit 1
fi

if [ ${#GRADLE_ARGS[@]} -eq 0 ]; then
  if [ "$MODE" = "android" ]; then
    GRADLE_ARGS=("assembleDebug")
  else
    GRADLE_ARGS=("build")
  fi
fi

STANDARD_PLATFORM_FLAG=""
ANDROID_PLATFORM_FLAG="--platform linux/amd64"
if [ "$(uname -m)" = "arm64" ]; then
  STANDARD_PLATFORM_FLAG="--platform linux/arm64"
fi

TEMP="${TEMP:-/tmp}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$TEMP/jvm-build-$TIMESTAMP.log"

mkdir -p "$HOME/.gradle"
WORKSPACE="$(pwd)"

if [ "$MODE" = "standard" ]; then
  docker run -i --rm $STANDARD_PLATFORM_FLAG \
    -v "$WORKSPACE:/workspace" \
    -w /workspace \
    -v "$HOME/.gradle:/root/.gradle" \
    "$KOTLIN_IMAGE" \
    ./gradlew "${GRADLE_ARGS[@]}" \
    > "$LOG_FILE" 2>&1
  EXIT_CODE=$?
else
  mkdir -p "$HOME/.android"
  if [ ! -f "$HOME/.android/debug.keystore" ]; then
    if ! docker run --rm $ANDROID_PLATFORM_FLAG \
        -v "$HOME/.android:/root/.android" \
        "$ANDROID_IMAGE" \
        keytool -genkeypair \
          -keystore /root/.android/debug.keystore \
          -storepass android -keypass android \
          -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
          -dname "CN=Android Debug,O=Android,C=US" \
        > /dev/null 2>&1; then
      echo "build failed: could not generate debug keystore" >&2
      exit 1
    fi
  fi
  docker run -i --rm $ANDROID_PLATFORM_FLAG \
    -v "$WORKSPACE:/workspace" \
    -w /workspace \
    -v "$HOME/.gradle:/root/.gradle" \
    -v "$HOME/.android:/root/.android" \
    -e ANDROID_ADB_SERVER_ADDRESS=host.docker.internal \
    -e ANDROID_ADB_SERVER_PORT=5037 \
    "$ANDROID_IMAGE" \
    ./gradlew "${GRADLE_ARGS[@]}" \
    > "$LOG_FILE" 2>&1
  EXIT_CODE=$?
fi

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "build succeeded"
else
  echo "build failed" >&2
  echo "log: $LOG_FILE" >&2
  exit "$EXIT_CODE"
fi
