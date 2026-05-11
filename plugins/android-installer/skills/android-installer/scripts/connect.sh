#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <device-ip>:<port>" >&2
  echo "  The IP and port are shown on the device under Wireless debugging." >&2
  exit 1
fi

"$ROOT/scripts/adb" connect "$1"
echo
"$ROOT/scripts/adb" devices
