#!/bin/bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(pwd)
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
GUARD_SCRIPT="$SCRIPT_DIR/go-build-guard.sh"

if [ ! -f "$GUARD_SCRIPT" ]; then
  echo "ERROR: go-build-guard.sh not found at $GUARD_SCRIPT" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/.claude"

python3 - "$SETTINGS_FILE" "$GUARD_SCRIPT" <<'PYEOF'
import sys, json, os

settings_file = sys.argv[1]
guard_script = sys.argv[2]

if os.path.exists(settings_file):
    with open(settings_file) as f:
        settings = json.load(f)
else:
    settings = {}

hook_entry = {
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": guard_script}]
}

pre_hooks = settings.setdefault("hooks", {}).setdefault("PreToolUse", [])

already_present = any(
    any(h.get("command") == guard_script for h in entry.get("hooks", []))
    for entry in pre_hooks
    if entry.get("matcher") == "Bash"
)

if not already_present:
    pre_hooks.append(hook_entry)

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF

echo "setup complete"
echo ""
echo "PreToolUse hook configured: $GUARD_SCRIPT"
echo ""
echo "To build:"
echo "  $SCRIPT_DIR/run-for-agent.sh build ./..."
echo ""
echo "To test:"
echo "  $SCRIPT_DIR/run-for-agent.sh test ./..."
