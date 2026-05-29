---
name: npm-builder
description: Run npm/bun scripts without a local Node.js installation — runs entirely in Docker. Use when asked to execute, run, or invoke npm/bun commands or package.json scripts in a Node.js or Bun project — including installing dependencies, building, testing, linting, typechecking, or running any custom script. Trigger on: "npm install", "npm ci", "npm run <script>", "bun install", "bun run <script>", "run the build", "run the tests", "run the dev server", "build the project", or any request to actually execute something in a Node.js/Bun project. Do not trigger just for editing package.json without running anything.
---

## Prerequisites

Before building:
- Docker must be running
- `setup-claude.sh` must have been run in this project (configures hooks)
- Hooks are active: direct `npm`, `npx`, `node`, `bun`, `bunx` calls will be blocked

This skill directory contains all necessary scripts. When invoked, the base directory is shown in the skill header.

## Project Setup

Run once per project before first use:

```bash
<skill-base-dir>/setup-claude.sh
```

## Running Scripts

**Install dependencies:**
```bash
<skill-base-dir>/run-for-agent.sh install
```

**Build:**
```bash
<skill-base-dir>/run-for-agent.sh run build
```

**Test:**
```bash
<skill-base-dir>/run-for-agent.sh run test
```

**Any package.json script:**
```bash
<skill-base-dir>/run-for-agent.sh run <script-name>
```

**Any direct npm/bun command:**
```bash
<skill-base-dir>/run-for-agent.sh <npm-or-bun-args>
```

Default command if none specified: `run build`.

All stdout/stderr is suppressed. Script reports only:
- `run succeeded` — exit 0
- `run failed` — exit non-zero; log path written to stderr

## On Run Failure

The script writes `log: /path/to/log` to stderr. Read the log:

```bash
cat <log-path>
```

Common issues:
- Missing `node_modules`: run `install` first
- Script not found in package.json: check `scripts` block in `package.json`
- TypeScript errors: full output in the log

## Package Manager Auto-Detection

The script detects which package manager to use:
- `bun.lockb` present → Bun (`oven/bun:latest`)
- Otherwise → npm (`node:lts-alpine`)

Override with `--pm=npm`, `--pm=bun`, or `--pm=auto`:

```bash
<skill-base-dir>/run-for-agent.sh --pm=bun install
<skill-base-dir>/run-for-agent.sh --pm=npm run build
```

## Dev Servers (Port Forwarding)

For scripts that start a long-running server (e.g., `dev`, `start`, `preview`), use `--port` to forward ports and `--stream` to see output in real time instead of capturing to a log:

```bash
<skill-base-dir>/run-for-agent.sh --port=3000 --stream run dev
```

**`--port=SPEC`** — Forward a port from the container to the host. `SPEC` is either `PORT` (same port on both sides, e.g. `--port=3000`) or `HOST_PORT:CONTAINER_PORT`. Repeat the flag for multiple ports:

```bash
<skill-base-dir>/run-for-agent.sh --port=3000 --port=4000 --stream run dev
```

**`--stream`** — Stream stdout/stderr directly instead of capturing to a log file. Use this for dev servers so you can see startup messages. In `--stream` mode, the script exits with Docker's exit code directly (no `run succeeded` / `run failed` wrapper).

> **Dev server host binding**: Most dev servers (Vite, webpack-dev-server, etc.) bind to `127.0.0.1` inside the container by default, which blocks Docker port forwarding. Pass `--host` (or `--host 0.0.0.0`) to the dev server so it binds to all interfaces. For Vite: `npm run dev -- --host`. For `react-scripts`: set `HOST=0.0.0.0` in the environment.

To run a dev server in the background so other commands can proceed:

```bash
<skill-base-dir>/run-for-agent.sh --port=3000 --stream run dev &
DEV_PID=$!
# ... do other things ...
kill $DEV_PID
```

## Environment Variables

- `TEMP` — directory for run logs (defaults to `/tmp`). If set, logs go to `$TEMP/npm-build-*.log`
