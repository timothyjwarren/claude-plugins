#!/usr/bin/env bash
# Cross-compiles adb-wireless for macOS inside a Linux Docker container using
# cargo-zigbuild, then extracts the native binary to ./scripts/adb-wireless.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/scripts/adb-wireless"

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
# The scratch stage contains only /adb-wireless, so the result is ./scripts/adb-wireless.
docker build \
  --build-arg TARGET="$TARGET" \
  --output "type=local,dest=$ROOT/scripts" \
  -f "$ROOT/scripts/adb-wireless.Dockerfile" \
  "$ROOT"

chmod +x "$BIN"
echo "Done: $BIN"
