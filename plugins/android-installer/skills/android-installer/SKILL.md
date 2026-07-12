---
name: android-installer
description: Use when a user wants to install an APK on an Android device — including sideloading, wireless install, testing a build on a physical device, or any situation without Android Studio, a local Android SDK, or USB. Everything runs in Docker; the only host requirement is Docker. Trigger on phrases like "install apk", "sideload", "push to my phone", "test on my Android device", or "deploy to device", even if the user doesn't mention Docker or wireless explicitly.
---

# adb-install skill

Follow this workflow in order. The pairing and server startup steps are stateful — running them out of order leaves the Docker container in a broken state that requires manual cleanup.

**Differentiators:**
- No USB required
- No Android SDK or Android Studio required on the host
- The adb server itself runs inside Docker — nothing Android-related is installed on the host
- The only host requirement is Docker

## Prerequisites

- Docker is installed and running
- Android device running Android 11 or later
- Device and host are on the same Wi-Fi network
- Wireless debugging is enabled on the device (Settings > Developer options > Wireless debugging)

## The two binaries

There are two distinct executables:

- **`android-installer-adb`** — a bash shim that routes adb commands into the persistent `adb-server` Docker container. It ships in the plugin's `bin/` (committed); no build is needed. It is used by `android-installer-connect.sh`, and is the command to run directly for any manual/diagnostic adb usage.
- **`adb-wireless`** — a native macOS binary compiled from source, written to `${CLAUDE_PLUGIN_DATA}/adb-wireless` (a persistent directory that survives plugin updates — not the plugin's own install tree, which gets wiped on every update). It is a build artifact and must be built once before the first pairing. It is used only by `android-installer-pair.sh` for QR-code pairing.

There's also an unprefixed `adb` file in `bin/` — a thin passthrough to `android-installer-adb`, kept only because `adb-wireless` internally shells out to bare `adb` during the pairing handshake and needs that exact name on `PATH` to find the shim rather than any system-installed `adb`. It's not meant to be invoked directly (a `PreToolUse` hook blocks bare `adb`); always use `android-installer-adb`.

## First-time setup: build adb-wireless binary

Before pairing for the first time, check whether the binary already exists and build it only if missing:

```bash
ls "${CLAUDE_PLUGIN_DATA}/adb-wireless" 2>/dev/null || android-installer-build-adb-wireless.sh --data-dir "${CLAUDE_PLUGIN_DATA}"
```

## Workflow A: First session (device not yet paired)

### Step 1 — Start the adb server

```bash
android-installer-start-adb-server.sh
```

### Step 2 — Pair via QR code

```bash
android-installer-pair.sh --data-dir "${CLAUDE_PLUGIN_DATA}"
```

A new Terminal window will open displaying the QR code. On the device: open **Settings > Developer options > Wireless debugging > Pair device with QR code**, then scan the QR code. Close the Terminal window when done.

**Note:** `android-installer-pair.sh` opens a separate window because Claude Code's TUI mangles the Unicode block characters used to render QR codes. The script returns immediately; pairing completes in the background window.

### Step 3 — Connect to the device

Ask the user: "What is the IP address and port shown under Settings > Developer options > Wireless debugging?" Then run:

```bash
android-installer-connect.sh <device-ip>:<port>
```

### Step 4 — Install the APK

Ask the user for the absolute path to their APK file if not already provided. Then run:

```bash
android-installer-install.sh /absolute/path/to/app.apk
```

### Step 5 — Clean up

When the session is done, stop the adb server:

```bash
docker stop adb-server
```

## Workflow B: Subsequent sessions (device already paired)

Skip the pairing steps. The device remembers the pairing.

First, ensure the `adb-wireless` binary exists (it lives in `${CLAUDE_PLUGIN_DATA}`, so a fresh plugin install won't have it yet):

```bash
ls "${CLAUDE_PLUGIN_DATA}/adb-wireless" 2>/dev/null || android-installer-build-adb-wireless.sh --data-dir "${CLAUDE_PLUGIN_DATA}"
```

Then connect and install. Ask the user for their device IP:port and APK path if not already provided:

```bash
android-installer-start-adb-server.sh
android-installer-connect.sh <device-ip>:<port>
android-installer-install.sh /absolute/path/to/app.apk
```

When done, stop the adb server:

```bash
docker stop adb-server
```

## Troubleshooting

If any step fails, read the file `references/troubleshooting.md` in the skill root directory for diagnosis steps and common fixes.

## Script reference

| Script | Purpose |
|--------|---------|
| `android-installer-build-adb-wireless.sh --data-dir <path>` | Builds the Docker-based adb-wireless binary into `<path>/adb-wireless`. Run once, passing `${CLAUDE_PLUGIN_DATA}`. |
| `android-installer-start-adb-server.sh` | Starts the adb server inside Docker. Run at the start of every session. |
| `android-installer-pair.sh --data-dir <path>` | Pairs the device via QR code (Android 11+). Run once per device, passing `${CLAUDE_PLUGIN_DATA}`. |
| `android-installer-connect.sh` | Connects to a paired device by IP:port. Run each session. |
| `android-installer-install.sh` | Installs an APK onto the connected device. |
| `android-installer-adb` | Runs an adb command directly against the persistent adb-server container. Use for manual/diagnostic checks. |
