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

BLOCKED_CMDS=("gradle" "./gradlew" "gradlew" "javac" "kotlinc" "mvn" "./mvnw" "mvnw")

for blocked in "${BLOCKED_CMDS[@]}"; do
  if [ "$CMD" = "$blocked" ]; then
    echo "ERROR: Direct use of '$CMD' is blocked in this project." >&2
    echo "Use android-builder-build.sh --mode=standard|android [gradle tasks] instead." >&2
    exit 2
  fi
done

exit 0
