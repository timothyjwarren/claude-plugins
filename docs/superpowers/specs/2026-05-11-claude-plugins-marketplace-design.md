# claude-plugins Marketplace Design

**Date:** 2026-05-11

## Overview

A personal Claude Code plugin marketplace hosted as a public GitHub repo. Consolidates three custom skills into a single installable marketplace following the official `claude-plugins-official` layout convention.

## Repo Structure

```
claude-plugins/
  .claude-plugin/
    marketplace.json
  plugins/
    android-builder/
      .claude-plugin/
        plugin.json
      skills/
        android-builder/
          SKILL.md
      dockerfiles/
      scripts/
      docs/
    android-installer/
      .claude-plugin/
        plugin.json
      skills/
        android-installer/
          SKILL.md
      docker/
      bin/
      scripts/
      docs/
    readme-writer/
      .claude-plugin/
        plugin.json
      skills/
        readme-writer/
          SKILL.md
      docs/
  README.md
```

## Plugins

### android-builder
- **Description:** Build Kotlin/JVM and Android projects without a local SDK — runs entirely in Docker
- **Category:** development
- **Source:** migrated from dev-jvm repo

### android-installer
- **Description:** Install APKs on Android devices wirelessly — no USB, no local Android SDK, runs entirely in Docker
- **Category:** development
- **Source:** migrated from devhelper-adb-install repo

### readme-writer
- **Description:** Write user-focused README files tailored to how the project actually works
- **Category:** productivity
- **Source:** migrated from writing-readmes skill

## Manifests

### `.claude-plugin/marketplace.json`
```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "claude-plugins",
  "description": "Personal Claude Code plugin marketplace",
  "plugins": [
    { "name": "android-builder",   "source": { "source": "local" } },
    { "name": "android-installer", "source": { "source": "local" } },
    { "name": "readme-writer",     "source": { "source": "local" } }
  ]
}
```

### `plugins/<name>/.claude-plugin/plugin.json`
```json
{
  "name": "<plugin-name>",
  "description": "<see above>",
  "category": "<see above>"
}
```

## Migration

Source files are copied (not moved) — existing repos are left untouched.

| Destination | Source |
|-------------|--------|
| `plugins/android-builder/skills/android-builder/SKILL.md` | `dev-jvm/skill/jvm-android-build/SKILL.md` |
| `plugins/android-builder/dockerfiles/` | `dev-jvm/dockerfiles/` |
| `plugins/android-builder/scripts/` | `dev-jvm/` (scripts extracted) |
| `plugins/android-builder/docs/` | `dev-jvm/docs/` |
| `plugins/android-installer/skills/android-installer/SKILL.md` | `devhelper-adb-install/skills/adb-install/SKILL.md` |
| `plugins/android-installer/docker/` | `devhelper-adb-install/docker/` |
| `plugins/android-installer/bin/` | `devhelper-adb-install/bin/` |
| `plugins/android-installer/scripts/` | `devhelper-adb-install/scripts/` |
| `plugins/android-installer/docs/` | `devhelper-adb-install/docs/` |
| `plugins/readme-writer/skills/readme-writer/SKILL.md` | `writing-readmes/SKILL.md` |
| `plugins/readme-writer/docs/` | `writing-readmes/docs/` |

## SKILL.md Updates

The `name:` frontmatter field in each SKILL.md is updated to match the new plugin name. No other content changes.

| File | Old name | New name |
|------|----------|----------|
| `android-builder/skills/android-builder/SKILL.md` | `jvm-kotlin-android-build` | `android-builder` |
| `android-installer/skills/android-installer/SKILL.md` | `adb-install` | `android-installer` |
| `readme-writer/skills/readme-writer/SKILL.md` | `writing-readmes` | `readme-writer` |

## Privacy

No personal identifiers in any committed files. Paths in skill scripts use `$HOME` or `~` rather than literal usernames. Do not expose any internal paths (such as `~/r`).

## Out of Scope

- Evals and workspace directories from source repos are not migrated
- `skills-builder`, `writing-prd-items`, `create-agent`, `golang`, `running-code` are not included in this iteration
