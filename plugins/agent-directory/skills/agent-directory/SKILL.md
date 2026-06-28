---
name: agent-directory
description: Use when you want to save something to the project (documentation, context, a script), or when you want to look for project-specific context, documentation, or scripts. Defines and manages the .agent/ directory convention.
---

# Agent Directory

The `.agent/` directory is the standard location for agent-authored content in a project. Use it instead of `docs/`, `scripts/`, or other human-oriented directories — this keeps agent content separate and findable without polluting human-authored project files.

## Directory Layout

```
.agent/
  .gitignore        # contains: local/
  context/          # progressive disclosure items
  docs/             # agent-authored documentation
  scripts/          # agent-friendly scripts
  local/            # gitignored — local-only content
    context/
    docs/
    scripts/
```

All directories are created lazily — only make directories when you have content to put in them. When writing to `local/` for the first time, create `local/` and ensure `.agent/.gitignore` contains `local/`.

## Where to Put Things

| Content type | Directory |
|---|---|
| Facts, summaries, decisions agents load on demand | `context/` |
| Architecture notes, how-to guides, reference material | `docs/` |
| Agent-friendly scripts | `scripts/` |
| Local-only versions of the above (secrets, machine-specific paths) | `local/context/`, `local/docs/`, `local/scripts/` |

## Frontmatter

All content files (in `context/`, `docs/`, `local/context/`, and `local/docs/`) must include YAML frontmatter with at minimum a `date` field. Scripts are exempt.

```yaml
---
date: 2026-06-28
---
```

When modifying an existing file, update `date` to today's date. This lets agents assess staleness at a glance.

## Script Contract

Every script in `scripts/` or `local/scripts/` must follow this contract so any agent can safely invoke it without reading its source:

- **`--help`** — print purpose, parameters, and options; always exit 0; exempt from the output rule below
- **Minimal output** — outside of `--help`, stdout and stderr contain only a terminal status indicator: `success` on exit 0, `failure` on non-zero exit
- **Temp files for details** — write logs, structured output, and any additional information to a temp file; print the path so the invoking agent knows where to look
- **Exit codes** — 0 for success, non-zero for failure

Scripts may be written in any language (bash, Python, Go binaries, etc.) as long as they satisfy the contract above.

## Discoverable, Not Auto-Scanned

Do not scan `.agent/` wholesale on startup. Load files from `context/` or `docs/` only when you have a specific reason to look for them.

## End-of-Session Review

If you wrote new files to `local/` during the current session, offer to review those specific files with the user before ending the session — to decide whether any should be promoted to checked-in files in `context/`, `docs/`, or `scripts/`.
