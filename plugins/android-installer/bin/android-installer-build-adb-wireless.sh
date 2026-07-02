#!/usr/bin/env bash
# Cross-compiles adb-wireless for macOS inside a Linux Docker container using
# cargo-zigbuild, then extracts the native binary to ${CLAUDE_PLUGIN_DATA}/adb-wireless.
# CLAUDE_PLUGIN_DATA persists across plugin updates, unlike the plugin's own install dir.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${CLAUDE_PLUGIN_DATA:?CLAUDE_PLUGIN_DATA not set}"
BIN="$DATA_DIR/adb-wireless"
mkdir -p "$DATA_DIR"

# Detect host CPU to pick the right macOS target triple
case "$(uname -m)" in
  arm64|aarch64) TARGET="aarch64-apple-darwin" ;;
  x86_64)        TARGET="x86_64-apple-darwin" ;;
  *)
    echo "error: unsupported host architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

echo "Building adb-wireless for $TARGET ..."

# --output exports the final image's filesystem to the dest directory.
# The scratch stage contains only /adb-wireless, so the result is $DATA_DIR/adb-wireless.
docker build \
  --build-arg TARGET="$TARGET" \
  --output "type=local,dest=$DATA_DIR" \
  -f "$ROOT/android-installer-adb-wireless.Dockerfile" \
  "$ROOT"

chmod +x "$BIN"
echo "Done: $BIN"
