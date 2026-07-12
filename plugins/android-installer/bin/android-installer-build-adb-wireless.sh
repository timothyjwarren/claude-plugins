#!/usr/bin/env bash
# Cross-compiles adb-wireless for macOS inside a Linux Docker container using
# cargo-zigbuild, then extracts the native binary to <data-dir>/adb-wireless.
# The data dir persists across plugin updates, unlike the plugin's own install dir.
set -euo pipefail

if [[ $# -ne 2 || "$1" != "--data-dir" ]]; then
  echo "Usage: $0 --data-dir <path>" >&2
  exit 1
fi
DATA_DIR="$2"

ROOT="$(cd "$(dirname "$0")" && pwd)"
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
