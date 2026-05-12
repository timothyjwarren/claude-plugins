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

echo "Opening a new Terminal window to display the QR code..."
echo "Scan it from: Settings → Developer options → Wireless debugging → Pair device with QR code"
echo

# Claude Code's TUI mangles Unicode block characters, so the QR code must render
# in a separate terminal window that has direct control over its own output.
TMP=$(mktemp "${TMPDIR:-/tmp}/pair-qr.XXXXXX.sh")
cat > "$TMP" <<EOF
#!/usr/bin/env bash
export PATH="$ROOT/scripts:\$PATH"
echo "Scan the QR code from: Settings → Developer options → Wireless debugging → Pair device with QR code"
echo
"$BIN" pair
rm -f "$TMP"
EOF
chmod +x "$TMP"
osascript -e "tell application \"Terminal\" to do script \"'$TMP'\""
