#!/bin/bash

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import sys, json, shlex
try:
    d = json.load(sys.stdin)
    cmd = d.get('command', '').strip()
    parts = shlex.split(cmd)
    print(parts[0] if parts else '')
except Exception:
    print('')
" 2>/dev/null)

BLOCKED_CMDS=("npm" "npx" "node" "bun" "bunx")

for blocked in "${BLOCKED_CMDS[@]}"; do
  if [ "$CMD" = "$blocked" ]; then
    echo "ERROR: Direct use of '$CMD' is blocked in this project." >&2
    echo "Use npm-builder-run.sh [--pm=npm|bun|auto] [npm/bun args] instead." >&2
    exit 2
  fi
done

exit 0
