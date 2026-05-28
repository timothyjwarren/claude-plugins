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

## Skill root

The skill system prints a line like `Base directory for this skill: /path/to/skill` before this document is shown. Capture that path as `SKILL_ROOT` and use it to construct all script paths. Example: if that line reads `Base directory for this skill: /path/to/.claude/plugins/my-plugin/1.0.0/skills/android-installer`, then set `SKILL_ROOT=/path/to/.claude/plugins/my-plugin/1.0.0/skills/android-installer`.

## Prerequisites

- Docker is installed and running
- Android device running Android 11 or later
- Device and host are on the same Wi-Fi network
- Wireless debugging is enabled on the device (Settings > Developer options > Wireless debugging)

## The two binaries

There are two distinct executables in `scripts/`:

- **`scripts/adb`** — a bash shim that routes adb commands into the persistent `adb-server` Docker container. It is already present in the skill directory (committed); no build is needed. It is used by `connect.sh`.
- **`scripts/adb-wireless`** — a native macOS binary compiled from source. It is a build artifact (not tracked by git) and must be built once before the first pairing. It is used only by `pair.sh` for QR-code pairing.

`pair.sh` prepends `scripts/` to `PATH` before running `adb-wireless`. This is intentional: `adb-wireless` internally shells out to `adb` during the pairing handshake, and the shim at `scripts/adb` is what should answer — not any system-installed `adb` (which may not exist or may point to a different server).

## First-time setup: build adb-wireless binary

Before pairing for the first time, check whether the binary already exists and build it only if missing:

```bash
ls "$SKILL_ROOT/scripts/adb-wireless" 2>/dev/null || "$SKILL_ROOT/scripts/build-adb-wireless.sh"
```

Output binary is written to `scripts/adb-wireless` inside the skill root directory.

## Workflow A: First session (device not yet paired)

### Step 1 — Start the adb server

```bash
"$SKILL_ROOT/scripts/start-adb-server.sh"
```

### Step 2 — Pair via QR code

```bash
"$SKILL_ROOT/scripts/pair.sh"
```

A QR code will appear in the terminal. On the device: open **Settings > Developer options > Wireless debugging > Pair device with QR code**, then scan the QR code.

**Note:** `pair.sh` is interactive — it displays a QR code and blocks until the device scans it. Do not expect it to return immediately.

### Step 3 — Connect to the device

Ask the user: "What is the IP address and port shown under Settings > Developer options > Wireless debugging?" Then run:

```bash
"$SKILL_ROOT/scripts/connect.sh" <device-ip>:<port>
```

### Step 4 — Install the APK

Ask the user for the absolute path to their APK file if not already provided. Then run:

```bash
"$SKILL_ROOT/scripts/install.sh" /absolute/path/to/app.apk
```

### Step 5 — Clean up

When the session is done, stop the adb server:

```bash
docker stop adb-server
```

## Workflow B: Subsequent sessions (device already paired)

Skip the pairing steps. The device remembers the pairing.

First, ensure `scripts/adb-wireless` exists (it is not tracked by git, so a fresh clone won't have it):

```bash
ls "$SKILL_ROOT/scripts/adb-wireless" 2>/dev/null || "$SKILL_ROOT/scripts/build-adb-wireless.sh"
```

Then connect and install. Ask the user for their device IP:port and APK path if not already provided:

```bash
"$SKILL_ROOT/scripts/start-adb-server.sh"
"$SKILL_ROOT/scripts/connect.sh" <device-ip>:<port>
"$SKILL_ROOT/scripts/install.sh" /absolute/path/to/app.apk
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
| `scripts/build-adb-wireless.sh` | Builds the Docker-based adb-wireless binary into `scripts/adb-wireless`. Run once. |
| `scripts/start-adb-server.sh` | Starts the adb server inside Docker. Run at the start of every session. |
| `scripts/pair.sh` | Pairs the device via QR code (Android 11+). Run once per device. |
| `scripts/connect.sh` | Connects to a paired device by IP:port. Run each session. |
| `scripts/install.sh` | Installs an APK onto the connected device. |
