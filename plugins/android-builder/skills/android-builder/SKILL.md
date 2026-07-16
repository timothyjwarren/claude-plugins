---
name: android-builder
description: Build Kotlin/JVM and Android projects via Docker without local SDK installation
---

## Prerequisites

Before building:
- Docker must be running
- Direct `gradle`, `./gradlew`, `javac`, `kotlinc` calls are blocked by the plugin hook — use `android-builder-build.sh` instead

`android-builder-build.sh` is a thin wrapper around `./gradlew` in a container — it passes tasks straight through and doesn't alter Gradle's task graph. Standard Gradle semantics apply, including task dependencies: e.g. by default `testDebugUnitTest` does not depend on `assembleDebug`, so running it after an edit doesn't tell you anything about whether `app-debug.apk` was rebuilt — unless the project's own build config wires that dependency. Check the project's task graph (`./gradlew :app:testDebugUnitTest --dry-run` via the wrapper, or the build files) if unsure which tasks a given task actually triggers.

## Project Bootstrap

If the project has no `gradlew` yet (new project, not cloned with existing wrapper):

```bash
android-builder-gradle-init.sh
```

`android-builder-gradle-init.sh` is idempotent — safe to run if unsure whether a wrapper exists.

## Building

**Standard Kotlin/JVM build** (compile, test, package JAR):
```bash
android-builder-build.sh --mode=standard
```

**Standard build with explicit Gradle tasks:**
```bash
android-builder-build.sh --mode=standard test
android-builder-build.sh --mode=standard build -x test
```

**Android APK build:**
```bash
android-builder-build.sh --mode=android
```

**Android with explicit tasks:**
```bash
android-builder-build.sh --mode=android assembleRelease
android-builder-build.sh --mode=android installDebug
android-builder-build.sh --mode=android connectedAndroidTest
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

### Test Failures

The build log's console output is often terse for test failures (e.g. just an exception class name, no message or stack trace). The full report is on the host, not just inside the container — the project directory is bind-mounted to `/workspace`, so everything Gradle writes under `app/build/` (including test reports) lands back at the same path on the host. Never `docker run` to inspect build output; read it directly:

```bash
cat app/build/reports/tests/testDebugUnitTest/classes/<ClassName>.html   # or open in a browser
cat app/build/test-results/testDebugUnitTest/TEST-<ClassName>.xml
```

## android-builder-gradle-init.sh Failures

If `android-builder-gradle-init.sh` fails, it also writes `log: /path/to/log` to stderr. Read the log the same way:

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

`android-builder-build.sh --mode=android` connects to the host's adb server via `host.docker.internal:5037`. The host adb server must be running (starts automatically when a device is connected or an emulator launched). `installDebug` and `connectedAndroidTest` tasks work without any additional setup.

## Environment Variables

- `TEMP` — directory for build logs (defaults to `/tmp`). If set, logs go to `$TEMP/jvm-build-*.log`
