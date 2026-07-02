---
date: 2026-06-28
---

# Plugin Hooks, Scripts, and Persistent Data

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
- `${CLAUDE_PLUGIN_DATA}` — persistent directory at `~/.claude/plugins/data/{plugin-id}/` that survives updates. Use for anything the plugin writes at runtime — build artifacts, user state, caches. Created automatically the first time the variable is referenced.

Example: `android-installer`'s `bin/android-installer-build-adb-wireless.sh` compiles a native binary. It writes the result to `${CLAUDE_PLUGIN_DATA}/adb-wireless`, not into the plugin's own tree — writing into `${CLAUDE_PLUGIN_ROOT}` would silently lose the binary on the next plugin update.

## bin/ for agent-invoked scripts

Scripts the agent runs directly (per a SKILL.md instruction) should live in a `bin/` directory at the plugin root, not under `skills/`. The harness adds `bin/` to the Bash tool's `PATH` while the plugin is enabled, so scripts become invokable as bare commands (`my-script.sh args`) with no path at all.

This matters for permission rules: a `${CLAUDE_PLUGIN_ROOT}/...` reference still resolves to a literal version-hashed cache path when the Bash tool actually runs the command, and "don't ask again" bakes in that literal string — so the approval breaks on the next plugin update. A bare command name never encodes the hash, so `Bash(my-script.sh:*)` survives updates.

Since `bin/` is a single flat namespace shared by every enabled plugin, prefix script names with the plugin name (`npm-builder-run.sh`, not `run-for-agent.sh`) even when nothing collides today — a later plugin can easily pick the same generic name.

Hook scripts (referenced from `hooks/hooks.json`, never invoked directly by the agent) don't need this — `${CLAUDE_PLUGIN_ROOT}` inside `hooks.json` is fine, since permission approval doesn't apply to hook execution the same way.

Don't have a skill capture the resolved path from the "Base directory for this skill: ..." line the harness prints when a skill loads (e.g. `SKILL_ROOT="$path"`). It's the same version-hashed cache path, just captured a different way, and it reintroduces the exact problem `${CLAUDE_PLUGIN_ROOT}`/`bin/` are meant to solve.

## Known Issues (as of June 2026)

`${CLAUDE_PLUGIN_ROOT}` is not injected for all hook types. `PreToolUse` and `PostToolUse` work reliably. `SessionStart` and stop hooks have reported injection failures (GitHub issues #27145, #36585, #66557). The superpowers plugin works around this in its session-start script by deriving `PLUGIN_ROOT` from `$(dirname "$0")` rather than relying on the env var.

## References

- [Plugins reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [hook-development/SKILL.md · anthropics/claude-code](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md)
- [Issue #18517: Plugin hooks in settings.json not updated when plugin version changes](https://github.com/anthropics/claude-code/issues/18517)
