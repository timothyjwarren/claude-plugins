#!/bin/bash
set -uo pipefail

GO_VERSION=""
TARGET=""
GO_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      cat <<'USAGE'
Usage: run-for-agent.sh [OPTIONS] [GO_ARGS...]

Options:
  --go-version=X.Y      Force Go version (default: read from go.mod, else "latest")
  --target=host         Cross-compile for the host OS/arch (sets GOOS/GOARCH, CGO_ENABLED=0)
  --target=GOOS/GOARCH  Cross-compile for an explicit OS/arch (sets CGO_ENABLED=0)
  --help, -h            Show this help

Default command if no GO_ARGS given: build ./...

Examples:
  run-for-agent.sh build ./...
  run-for-agent.sh test ./...
  run-for-agent.sh --go-version=1.21 vet ./...
  run-for-agent.sh --target=host build -o myapp ./cmd/myapp
USAGE
      exit 0
      ;;
    --go-version=*) GO_VERSION="${arg#--go-version=}" ;;
    --target=*)     TARGET="${arg#--target=}" ;;
    *)              GO_ARGS+=("$arg") ;;
  esac
done

if [ -z "$GO_VERSION" ]; then
  if [ -f "./go.mod" ]; then
    GO_VERSION=$(awk '/^go [0-9]+\.[0-9]+/ {print $2; exit}' go.mod)
  fi
  if [ -z "$GO_VERSION" ]; then
    GO_VERSION="latest"
  fi
fi

IMAGE="golang:${GO_VERSION}"

if [ ${#GO_ARGS[@]} -eq 0 ]; then
  GO_ARGS=("build" "./...")
fi

ENV_FLAGS=()
if [ -n "$TARGET" ]; then
  if [ "$TARGET" = "host" ]; then
    HOST_OS=$(uname -s)
    HOST_ARCH=$(uname -m)
    case "$HOST_OS" in
      Darwin) GOOS="darwin" ;;
      Linux)  GOOS="linux" ;;
      *)      GOOS=$(echo "$HOST_OS" | tr '[:upper:]' '[:lower:]') ;;
    esac
    case "$HOST_ARCH" in
      arm64|aarch64) GOARCH="arm64" ;;
      x86_64)        GOARCH="amd64" ;;
      *)             GOARCH="$HOST_ARCH" ;;
    esac
  else
    GOOS="${TARGET%/*}"
    GOARCH="${TARGET#*/}"
  fi
  ENV_FLAGS+=("-e" "GOOS=$GOOS" "-e" "GOARCH=$GOARCH" "-e" "CGO_ENABLED=0")
fi

TEMP="${TEMP:-/tmp}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$TEMP/go-build-$TIMESTAMP.log"

MOD_CACHE="$HOME/go/pkg/mod"
BUILD_CACHE="$HOME/.cache/go-build"
mkdir -p "$MOD_CACHE" "$BUILD_CACHE"

docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  -v "$MOD_CACHE:/go/pkg/mod" \
  -v "$BUILD_CACHE:/root/.cache/go-build" \
  "${ENV_FLAGS[@]+"${ENV_FLAGS[@]}"}" \
  "$IMAGE" \
  go "${GO_ARGS[@]}" \
  > "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "run succeeded"
else
  echo "run failed" >&2
  echo "log: $LOG_FILE" >&2
  exit "$EXIT_CODE"
fi
