# claude-plugins

A personal collection of Claude Code plugins.

## Plugins

| Plugin | What it does |
|--------|-------------|
| [agent-directory](plugins/agent-directory/) | Standard place for agent-authored files (context, docs, scripts) — kept separate from human project files. |
| [android-builder](plugins/android-builder/) | Build Kotlin/JVM and Android projects -- no local SDK, no Gradle installation, no JDK version juggling. Runs in Docker. |
| [android-installer](plugins/android-installer/) | Install APKs on Android devices wirelessly. No USB cable, no Android Studio, no local ADB. Runs in Docker. |
| [golang-builder](plugins/golang-builder/) | Build, test, and vet Go projects across multiple Go versions, including cross-compilation. No local Go installation needed. Runs in Docker. |
| [npm-builder](plugins/npm-builder/) | Run npm/bun scripts without a local Node.js installation. Runs in Docker. |
| [readme-writer](plugins/readme-writer/) | Write user-focused README files. Reads the codebase, confirms a few things with you, then writes in one pass. |

## Installing

Add this marketplace to Claude Code:

```
/marketplace add https://github.com/timothyjwarren/claude-plugins
```

Then install individual plugins:

```
/plugin install android-builder
/plugin install android-installer
/plugin install golang-builder
/plugin install npm-builder
/plugin install readme-writer
```
