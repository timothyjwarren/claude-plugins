#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/scripts/adb-wireless"

if [[ ! -x "$BIN" ]]; then
  echo "error: $BIN not found. Run scripts/build-adb-wireless.sh first." >&2
  exit 1
fi

# Make scripts/adb visible to adb-wireless
export PATH="$ROOT/scripts:$PATH"

echo "Scan the QR code from: Settings → Developer options → Wireless debugging → Pair device with QR code"
echo

"$BIN" pair
