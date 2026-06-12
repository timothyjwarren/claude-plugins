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

BLOCKED_CMDS=("go" "gofmt")

for blocked in "${BLOCKED_CMDS[@]}"; do
  if [ "$CMD" = "$blocked" ]; then
    echo "ERROR: Direct use of '$CMD' is blocked in this project." >&2
    echo "Use run-for-agent.sh [--go-version=X.Y] [--target=host|GOOS/GOARCH] [go args] instead." >&2
    exit 2
  fi
done

exit 0
