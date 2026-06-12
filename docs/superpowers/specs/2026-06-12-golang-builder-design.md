# golang-builder Plugin Design

**Date:** 2026-06-12
**Status:** Approved

## Problem

Go tooling (`go`, `gofmt`) must not run directly on the host. The golang-builder plugin provides a Docker-based execution layer so Claude can build, test, and vet Go projects without requiring any local Go installation, while supporting multiple Go versions (not hardcoded to one).

## Goals

- Run `go` subcommands (`build`, `test`, `vet`, `mod tidy`, etc.) entirely inside Docker
- Support multiple Go versions: auto-detect from `go.mod`'s `go` directive, with manual override
- Suppress noisy output — return only `run succeeded` or `run failed` + log path
- Block direct host invocations of `go` and `gofmt` via a PreToolUse guard hook
- Support cross-compilation so a build produces a binary runnable directly on the host (e.g. build a macOS arm64 binary from a Linux container)
- Mirror the android-builder/npm-builder plugins' structure and conventions

## Non-Goals

- `go run` support (build a binary, then run it directly on host instead)
- Port forwarding / streaming for long-running servers (not needed — built binaries run natively on host, outside Docker)
- Custom Dockerfiles or multi-stage builds

---

## Structure

```
plugins/golang-builder/
├── .claude-plugin/plugin.json
└── skills/golang-builder/
    ├── SKILL.md
    ├── setup-claude.sh        # installs guard hook into project .claude/settings.json
    ├── go-build-guard.sh      # PreToolUse hook — blocks go/gofmt
    └── run-for-agent.sh       # main script: runs any go subcommand in Docker
```

---

## Scripts

### `run-for-agent.sh [OPTIONS] [GO_ARGS...]`

**Go version selection:**
- `--go-version=X.Y` — force a specific version, image becomes `golang:X.Y`
- Default (no flag): parse the `go X.Y` directive from `./go.mod`; image becomes `golang:X.Y`
- If no `go.mod` is found and no override given: image is `golang:latest`

**Cross-compilation:**
- `--target=host` — detect the host OS/arch via `uname -s`/`uname -m` and set `GOOS`/`GOARCH` env vars accordingly in the container (e.g. `darwin/arm64` on Apple Silicon), so `go build` output runs natively on the host without Docker
- `--target=GOOS/GOARCH` — set `GOOS`/`GOARCH` explicitly (e.g. `--target=linux/amd64`)
- Without `--target`: no GOOS/GOARCH override; build output matches the container's native platform

**Default command:** `build ./...` (if no `GO_ARGS` given)

**Docker execution:**
- Image: `golang:<version>` (multi-arch; Docker selects the matching platform for the container automatically — no explicit `--platform` flag needed)
- Mounts workspace at `/workspace`, working dir `/workspace`
- Mounts caches for repeated-run speed:
  - module cache: `~/go/pkg/mod` → `/go/pkg/mod`
  - build cache: `~/.cache/go-build` → `/root/.cache/go-build`
- `GOOS`/`GOARCH` env vars set when `--target` is given
- All stdout/stderr redirected to a timestamped log file under `$TEMP` (defaults to `/tmp`)

**Output:**
- Success: `run succeeded` (exit 0)
- Failure: `run failed` + `log: <path>` on stderr (exit non-zero)

### `go-build-guard.sh`

PreToolUse hook. Reads the Bash tool's JSON input, extracts the command, and blocks: `go`, `gofmt`. Directs user to `run-for-agent.sh`. Running a built binary directly (e.g. `./myapp`) is not blocked.

### `setup-claude.sh`

Idempotent. Patches `.claude/settings.json` in the current project to register `go-build-guard.sh` as a `PreToolUse` hook on the `Bash` matcher. Same Python-based patcher as npm-builder/android-builder.

---

## Docker Images

| Condition | Image |
|---|---|
| `--go-version=X.Y` given | `golang:X.Y` |
| `go.mod` present, no override | `golang:<version from go.mod>` |
| No `go.mod`, no override | `golang:latest` |

---

## SKILL.md Sections

1. Prerequisites (Docker running, `setup-claude.sh` run once per project)
2. Setup: `setup-claude.sh`
3. Running commands: explicit examples (`build ./...`, `test ./...`, `vet ./...`, `mod tidy`, arbitrary `go` args)
4. On failure: read the log with `cat <log-path>`
5. Go version detection (`go.mod`) and `--go-version` override
6. Cross-compilation with `--target=host` / `--target=GOOS/GOARCH`, and how to run the resulting binary directly on the host
7. `TEMP` env var

---

## Validation

After implementation, validate with the `skill-creator` skill and its eval tooling to confirm the skill triggers correctly and the scripts behave as documented.

---

## Marketplace Entry

Add to `.claude-plugin/marketplace.json`:
```json
{ "name": "golang-builder", "source": "./plugins/golang-builder", "description": "Build, test, and vet Go projects across multiple Go versions — runs entirely in Docker" }
```

Add to `README.md` plugin table and install instructions.
