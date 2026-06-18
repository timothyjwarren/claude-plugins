---
name: golang-builder
description: Build, test, and vet Go projects across multiple Go versions — runs entirely in Docker. Use when asked to build, test, vet, run "go mod" commands, or compile a Go project — including cross-compiling binaries. Trigger on: "go build", "go test", "go vet", "go mod tidy", "build the project", "run the tests", "cross-compile", or any request to actually execute `go`/`gofmt` in a Go project. Do not trigger just for editing .go files without building or testing.
---

## Prerequisites

Before building:
- Docker must be running
- `setup-claude.sh` must have been run in this project (configures hooks)
- Hooks are active: direct `go` and `gofmt` calls will be blocked

This skill directory contains all necessary scripts. When invoked, the base directory is shown in the skill header.

## Project Setup

Run once per project before first use:

```bash
<skill-base-dir>/setup-claude.sh
```

By default this writes the guard hook to `.claude/settings.local.json` (gitignored, local to you — not shared via git). If the user wants this hook enforced for everyone working on this project, ask them, then run:

```bash
<skill-base-dir>/setup-claude.sh --shared
```

This writes to `.claude/settings.json` instead, which is committed to the repo.

## Running Commands

**Build everything:**
```bash
<skill-base-dir>/run-for-agent.sh build ./...
```

**Test everything:**
```bash
<skill-base-dir>/run-for-agent.sh test ./...
```

**Vet:**
```bash
<skill-base-dir>/run-for-agent.sh vet ./...
```

**Module commands:**
```bash
<skill-base-dir>/run-for-agent.sh mod tidy
<skill-base-dir>/run-for-agent.sh mod download
```

**Any `go` subcommand:**
```bash
<skill-base-dir>/run-for-agent.sh <go args>
```

Default command if none specified: `build ./...`.

All stdout/stderr is suppressed. Script reports only:
- `run succeeded` — exit 0
- `run failed` — exit non-zero; log path written to stderr

This output is one or two short lines — run the script directly and read its output as-is. Don't redirect stderr to a file and `cat` it afterward; that's unnecessary extra steps for output this small.

## On Run Failure

The script writes `log: /path/to/log` to stderr. Read the log:

```bash
cat <log-path>
```

Common issues:
- No `go.mod`: run `<skill-base-dir>/run-for-agent.sh mod init <module-path>`
- Missing dependencies: run `mod download` or `mod tidy` first
- Compile errors: full output in the log

## Go Version Selection

The script auto-detects the Go version from the `go` directive in `./go.mod` (e.g. `go 1.22` → `golang:1.22`). If there's no `go.mod`, it falls back to `golang:latest`.

Override with `--go-version`:

```bash
<skill-base-dir>/run-for-agent.sh --go-version=1.21 test ./...
```

**Note:** `--go-version` must be >= the version required by `go.mod`'s `go` directive. Go's toolchain enforcement (`GOTOOLCHAIN`) will fail the run if you specify an older version than `go.mod` requires.

## Cross-Compilation

Use `--target` to set `GOOS`/`GOARCH` (and `CGO_ENABLED=0`) for the build, producing a binary for a different platform than the build container:

```bash
# Build a binary for the host machine (e.g. macOS arm64) and run it directly — no Docker needed
<skill-base-dir>/run-for-agent.sh --target=host build -o myapp ./cmd/myapp
./myapp

# Build for an explicit GOOS/GOARCH
<skill-base-dir>/run-for-agent.sh --target=linux/amd64 build -o myapp-linux ./cmd/myapp
```

`--target=host` detects the host OS/arch via `uname` so the resulting binary runs natively on the host.

## Environment Variables

- `TEMP` — directory for run logs (defaults to `/tmp`). If set, logs go to `$TEMP/go-build-*.log`
