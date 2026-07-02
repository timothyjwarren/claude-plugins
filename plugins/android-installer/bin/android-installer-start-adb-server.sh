#!/usr/bin/env bash
# Starts a persistent adb server container. All adb commands (pair, connect,
# install) route through this container so they share device connections and keys.
set -euo pipefail

CONTAINER="adb-server"

if docker inspect "$CONTAINER" &>/dev/null; then
  if [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" == "true" ]]; then
    echo "adb-server is already running."
    exit 0
  fi
  docker rm "$CONTAINER" >/dev/null
fi

docker run -d \
  --name "$CONTAINER" \
  -p 5037:5037 \
  -v adb-keys:/root/.android \
  mingc/android-build-box:latest \
  adb -a -P 5037 nodaemon server

echo "adb-server started."
