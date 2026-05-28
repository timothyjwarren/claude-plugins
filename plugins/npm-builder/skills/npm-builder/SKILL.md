---
name: npm-builder
description: Run npm/bun scripts without a local Node.js installation — runs entirely in Docker. Use when asked to install dependencies, build, test, or run any package.json script in a Node.js or Bun project. Trigger on: "npm install", "run the build", "run tests", "bun install", "build the project", or any npm/bun script invocation.
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

## Environment Variables

- `TEMP` — directory for run logs (defaults to `/tmp`). If set, logs go to `$TEMP/npm-build-*.log`
