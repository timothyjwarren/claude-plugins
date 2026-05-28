# npm-builder Plugin Design

**Date:** 2026-05-28
**Status:** Approved

## Problem

Node.js tooling (npm, npx, node, bun) must not run directly on the host. The npm-builder plugin provides a Docker-based execution layer so Claude can install dependencies and run package scripts without requiring any local Node.js or Bun installation.

## Goals

- Run `npm`/`bun` scripts entirely inside Docker
- Suppress noisy output — return only `run succeeded` or `run failed` + log path
- Block direct host invocations of npm/node/npx/bun/bunx via a PreToolUse guard hook
- Auto-detect package manager from lockfiles; support manual override
- Mirror the android-builder plugin's structure and conventions exactly

## Non-Goals

- yarn, pnpm support
- Multi-stage Docker builds or custom Dockerfiles
- Publishing packages

---

## Structure

```
plugins/npm-builder/
├── .claude-plugin/plugin.json
└── skills/npm-builder/
    ├── SKILL.md
    ├── setup-claude.sh        # installs guard hook into project .claude/settings.json
    ├── npm-build-guard.sh     # PreToolUse hook — blocks npm/node/npx/bun/bunx
    └── run-for-agent.sh       # main script: runs any npm/bun script in Docker
```

---

## Scripts

### `run-for-agent.sh [--pm=npm|bun|auto] [script] [args...]`

**Package manager detection** (when `--pm=auto` or omitted):
- `bun.lockb` present → use Bun (`oven/bun:latest`)
- otherwise → use npm (`node:lts-alpine`)

**Default script:** `build` (if no script argument given)

**Docker execution:**
- Mounts workspace at `/workspace`
- Mounts cache dir for repeated-run speed:
  - npm: `~/.npm` → `/root/.npm`
  - bun: `~/.bun` → `/root/.bun`
- Platform: `linux/arm64` on Apple Silicon, `linux/amd64` otherwise
- All stdout/stderr redirected to a timestamped log file under `$TEMP` (defaults to `/tmp`)

**Output:**
- Success: `run succeeded` (exit 0)
- Failure: `run failed` + `log: <path>` on stderr (exit non-zero)

### `npm-build-guard.sh`

PreToolUse hook. Reads the Bash tool's JSON input, extracts the command, and blocks: `npm`, `npx`, `node`, `bun`, `bunx`. Directs user to `run-for-agent.sh`.

### `setup-claude.sh`

Idempotent. Patches `.claude/settings.json` in the current project to register `npm-build-guard.sh` as a `PreToolUse` hook on the `Bash` matcher. Same Python-based patcher as android-builder.

---

## Docker Images

| Condition | Image |
|---|---|
| `bun.lockb` present | `oven/bun:latest` |
| `package-lock.json` or no lockfile | `node:lts-alpine` |

---

## SKILL.md Sections

1. Prerequisites (Docker running, `setup-claude.sh` run once per project)
2. Setup: `setup-claude.sh`
3. Running scripts: explicit examples (`install`, `build`, `test`, arbitrary)
4. On failure: read the log with `cat <log-path>`
5. Package manager auto-detection and `--pm` override
6. `TEMP` env var

---

## Validation

After implementation, validate with the `skill-creator` skill and its eval tooling to confirm the skill triggers correctly and the scripts behave as documented.

---

## Marketplace Entry

Add to `.claude-plugin/marketplace.json`:
```json
{ "name": "npm-builder", "source": "./plugins/npm-builder", "description": "Run npm/bun scripts without a local Node.js installation — runs entirely in Docker" }
```
