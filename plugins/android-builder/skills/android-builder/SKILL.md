---
name: android-builder
description: Build Kotlin/JVM and Android projects via Docker without local SDK installation
---

## Prerequisites

Before building:
- Docker must be running
- Direct `gradle`, `./gradlew`, `javac`, `kotlinc` calls are blocked by the plugin hook — use `build-for-agent.sh` instead

## Project Bootstrap

If the project has no `gradlew` yet (new project, not cloned with existing wrapper):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/gradle-init.sh
```

`gradle-init.sh` is idempotent — safe to run if unsure whether a wrapper exists.

## Building

**Standard Kotlin/JVM build** (compile, test, package JAR):
```bash
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=standard
```

**Standard build with explicit Gradle tasks:**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=standard test
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=standard build -x test
```

**Android APK build:**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=android
```

**Android with explicit tasks:**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=android assembleRelease
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=android installDebug
${CLAUDE_PLUGIN_ROOT}/skills/android-builder/build-for-agent.sh --mode=android connectedAndroidTest
```

Default tasks if none specified: `build` (standard), `assembleDebug` (android).

All stdout/stderr is suppressed. Script reports only:
- `build succeeded` — exit 0
- `build failed` — exit non-zero; log path written to stderr

This output is one or two short lines — run the script directly and read its output as-is. Don't redirect stderr to a file and `cat` it afterward; that's unnecessary extra steps for output this small.

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

## APK Naming

Configure the APK output filename to match the project name. In `app/build.gradle.kts`:

```kotlin
android {
    applicationVariants.all {
        outputs.all {
            (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName =
                "${rootProject.name}-${buildType.name}.apk"
        }
    }
}
```

This produces `foo-debug.apk`, `foo-release.apk`, etc. After a build, check `outputFileName` in the build config to know exactly what APK to look for under `app/build/outputs/apk/`.

## adb / Device Deployment (Android mode)

`build-for-agent.sh --mode=android` connects to the host's adb server via `host.docker.internal:5037`. The host adb server must be running (starts automatically when a device is connected or an emulator launched). `installDebug` and `connectedAndroidTest` tasks work without any additional setup.

## Environment Variables

- `TEMP` — directory for build logs (defaults to `/tmp`). If set, logs go to `$TEMP/jvm-build-*.log`
