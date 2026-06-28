# agent-directory Plugin Design

**Date:** 2026-06-28
**Status:** Approved

## Problem

Agents that produce documentation, context files, or scripts have nowhere project-specific to put them. Dropping things in `docs/` or `scripts/` mingles agent-authored content with human-authored content, making both harder to find and maintain. There is also no standard place for local-only (gitignored) agent working files.

## Goals

- Define a standard `.agent/` directory layout agents can rely on across projects
- Keep agent content discoverable but not auto-scanned on startup
- Provide a gitignored `local/` area for ephemeral or sensitive agent files
- Define a script contract so any agent-written script is usable by any other agent
- Prompt agents to review new local/ content with the user at session end

## Non-Goals

- Setup scripts or initialization commands (directories created lazily)
- Script templates (scripts may be bash, python, Go binaries, etc.)
- Automatic scanning of `.agent/` content on skill load

---

## Directory Layout

```
.agent/
  .gitignore        # contains: local/
  context/          # progressive disclosure items; typically referenced from CLAUDE.md
  docs/             # agent-authored documentation
  scripts/          # agent-friendly scripts
  local/            # gitignored — local-only context, docs, scripts
    context/
    docs/
    scripts/
```

All directories are created lazily as content is added. When an agent first writes to `local/`, it creates `local/` and ensures `.agent/.gitignore` contains `local/`.

---

## Conventions

### Frontmatter

All content files (in `context/`, `docs/`, `local/context/`, and `local/docs/`) must include YAML frontmatter with at minimum a `date` field so agents can assess staleness. Scripts are exempt.

```yaml
---
date: 2026-06-28
---
```

When an agent modifies an existing file, it must update the `date` field to the current date.

### Directory usage

| Directory | Use for |
|-----------|---------|
| `context/` | Progressive disclosure context — facts, summaries, decisions agents should know but only load on demand |
| `docs/` | Agent-authored documentation — architecture notes, how-to guides, reference material |
| `scripts/` | Agent-friendly scripts (see Script Contract below) |
| `local/context/` | Same as `context/`, but local-only (e.g. secrets, machine-specific paths) |
| `local/docs/` | Same as `docs/`, but local-only |
| `local/scripts/` | Same as `scripts/`, but local-only |

### Script Contract

Every script in `scripts/` or `local/scripts/` must follow this contract so any agent can safely invoke it:

- **`--help`** — describes purpose, parameters, and options; always exits 0; exempt from the minimal output rule below
- **Minimal output** — outside of `--help`, stdout and stderr contain only a terminal status indicator: `success` on exit 0, `failure` on non-zero exit
- **Details in temp files** — any structured output, logs, or additional information is written to a temp file; the path is printed to stdout or stderr so the invoking agent knows where to look
- **Exit codes** — 0 for success, non-zero for failure

### End-of-session review

If the agent wrote new files to `local/` during the session, it should offer to review those specific files with the user before the session ends, to decide whether any should be promoted to checked-in files.

---

## Plugin Structure

```
plugins/agent-directory/
  .claude-plugin/
    plugin.json
  skills/
    agent-directory/
      SKILL.md
```

No scripts or Dockerfiles — this plugin is a convention document only.

---

## Skill Trigger

The skill description targets two moments:

1. **Save** — agent produces something worth keeping (docs, context, a script) and needs to know where to put it
2. **Lookup** — agent wants project-specific context, documentation, or scripts before proceeding
