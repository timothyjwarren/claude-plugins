---
date: 2026-06-28
---

# Plugin Hooks

## Configuration

Hooks belong in `hooks/hooks.json` at the plugin root (alongside `.claude-plugin/`). The harness manages registration and updates automatically.

Use `${CLAUDE_PLUGIN_ROOT}` to reference scripts — the harness substitutes it with the plugin's current install directory wherever it appears in hook commands, skill content, MCP/LSP config, etc. In SKILL.md bodies, write script paths as `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<script>` directly; the model executes this literally, so it always resolves through the stable path rather than the resolved absolute cache path shown when the skill loads.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/skills/android-builder/jvm-build-guard.sh"
          }
        ]
      }
    ]
  }
}
```

## Variables

- `${CLAUDE_PLUGIN_ROOT}` — plugin's current install/cache directory. Treat as read-only; contents are wiped on update.
- `${CLAUDE_PLUGIN_DATA}` — persistent directory at `~/.claude/plugins/data/{plugin-id}/` that survives updates. Use for user state or caches.

## Known Issues (as of June 2026)

`${CLAUDE_PLUGIN_ROOT}` is not injected for all hook types. `PreToolUse` and `PostToolUse` work reliably. `SessionStart` and stop hooks have reported injection failures (GitHub issues #27145, #36585, #66557). The superpowers plugin works around this in its session-start script by deriving `PLUGIN_ROOT` from `$(dirname "$0")` rather than relying on the env var.

## References

- [Plugins reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [hook-development/SKILL.md · anthropics/claude-code](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md)
- [Issue #18517: Plugin hooks in settings.json not updated when plugin version changes](https://github.com/anthropics/claude-code/issues/18517)
