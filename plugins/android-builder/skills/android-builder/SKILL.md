---
name: android-builder
description: Build Kotlin/JVM and Android projects via Docker without local SDK installation
---

## Prerequisites

Before building:
- Docker must be running
- `setup-claude.sh` must have been run in this project (configures hooks)
- Hooks are active: direct `gradle`, `./gradlew`, `javac`, `kotlinc` calls will be blocked

This skill directory contains all necessary scripts. When invoked, the base directory is shown in the skill header.

## Project Bootstrap

Run once per project before first build:

```bash
<skill-base-dir>/setup-claude.sh
```

If the project has no `gradlew` yet (new project, not cloned with existing wrapper):

```bash
<skill-base-dir>/gradle-init.sh
```

`gradle-init.sh` is idempotent — safe to run if unsure whether a wrapper exists.

## Building

**Standard Kotlin/JVM build** (compile, test, package JAR):
```bash
<skill-base-dir>/build-for-agent.sh --mode=standard
```

**Standard build with explicit Gradle tasks:**
```bash
<skill-base-dir>/build-for-agent.sh --mode=standard test
<skill-base-dir>/build-for-agent.sh --mode=standard build -x test
```

**Android APK build:**
```bash
<skill-base-dir>/build-for-agent.sh --mode=android
```

**Android with explicit tasks:**
```bash
<skill-base-dir>/build-for-agent.sh --mode=android assembleRelease
<skill-base-dir>/build-for-agent.sh --mode=android installDebug
<skill-base-dir>/build-for-agent.sh --mode=android connectedAndroidTest
```

Default tasks if none specified: `build` (standard), `assembleDebug` (android).

All stdout/stderr is suppressed. Script reports only:
- `build succeeded` — exit 0
- `build failed` — exit non-zero; log path written to stderr

## On Build Failure

The script writes `log: /path/to/log` to stderr. Read the log:

```bash
cat <log-path>
```

Common issues:
- Compilation errors: full error in the log
- Missing dependencies: check `build.gradle.kts` repositories block
- Android SDK version mismatch: check `compileSdk`/`targetSdk` in `build.gradle.kts`; verify against SDK versions in the Android image

## gradle-init.sh Failures

If `gradle-init.sh` fails, it also writes `log: /path/to/log` to stderr. Read the log the same way:

```bash
cat <log-path>
```

Common issues:
- Network failure downloading gradle: check internet connection
- Corrupt download: delete gradle/wrapper/ directory and try again

## adb / Device Deployment (Android mode)

`build-for-agent.sh --mode=android` connects to the host's adb server via `host.docker.internal:5037`. The host adb server must be running (starts automatically when a device is connected or an emulator launched). `installDebug` and `connectedAndroidTest` tasks work without any additional setup.

## Environment Variables

- `TEMP` — directory for build logs (defaults to `/tmp`). If set, logs go to `$TEMP/jvm-build-*.log`
