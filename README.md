# claude-plugins

Claude Code is useful out of the box, but it can't build your Android app, deploy an APK to your phone, or write a README that actually sells your project. Getting those things working requires the right tooling -- and the right tooling usually means installing SDKs, configuring environment variables, and hoping everything plays nicely together on every machine you use.

This is a personal Claude Code plugin marketplace that sidesteps that setup entirely. The Android plugins run entirely in Docker, so there's nothing to install locally. Claude handles builds and deployments end-to-end.

## Plugins

| Plugin | What it does |
|--------|-------------|
| [android-builder](plugins/android-builder/) | Build Kotlin/JVM and Android projects -- no local SDK, no Gradle installation, no JDK version juggling. Runs in Docker. |
| [android-installer](plugins/android-installer/) | Install APKs on Android devices wirelessly. No USB cable, no Android Studio, no local ADB. Runs in Docker. |
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
/plugin install readme-writer
```

## Requirements

- **Docker** -- required for android-builder and android-installer. No other local dependencies needed for those plugins.
- **readme-writer** -- no dependencies beyond Claude Code itself.
