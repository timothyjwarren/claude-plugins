# adb-install Skill — Troubleshooting Guide

This file is loaded by Claude agents when something goes wrong during the
wireless ADB install workflow.

> **Note:** This skill has no host-resident `adb` binary. All adb commands use
> `android-installer-adb`, a shim bundled in the plugin's `bin/`, which routes
> through the `adb-server` Docker container. A `PreToolUse` hook blocks bare
> `adb` invocations — always use `android-installer-adb`.

---

## 1. Install fails or the device is not found

`android-installer-install.sh` copies the APK into the `adb-server` container
(`docker cp`) and runs `adb install` there through `android-installer-adb`, so
it uses the same connected devices and keys as `connect`/`pair`. No second
container or host networking is involved.

If the install reports `no devices/emulators found`, confirm the device is
connected:

```bash
android-installer-adb devices
```

If the device is missing, run `android-installer-connect.sh` again. If the
`adb-server` container is not running, start it with
`android-installer-start-adb-server.sh`.

---

## 2. Conflicting adb servers

All adb commands run against the single `adb-server` container.

**Symptom:** device is not listed, or you see `adb: failed to start daemon`.

**Cause:** a second adb server is competing on port 5037.

**Fix:**

```bash
# Kill any rogue servers:
android-installer-adb kill-server
android-installer-adb start-server   # restarts cleanly on port 5037

# Do NOT start adb inside the container manually.
```

Only one adb server should be running at a time — the one in the `adb-server`
container.

---

## 3. adb-wireless binary missing

`android-installer-pair.sh` requires a compiled `adb-wireless` binary at
`${CLAUDE_PLUGIN_DATA}/adb-wireless`. This binary is a build artifact and must
be built once before pairing.

**Error message:**

```
error: .../adb-wireless not found. Run android-installer-build-adb-wireless.sh first.
```

**Fix:**

```bash
android-installer-build-adb-wireless.sh --data-dir "${CLAUDE_PLUGIN_DATA}"
```

The script compiles the binary and places it at `${CLAUDE_PLUGIN_DATA}/adb-wireless`,
a directory that persists across plugin updates. After building, re-run
`android-installer-pair.sh --data-dir "${CLAUDE_PLUGIN_DATA}"`.

Note: `android-installer-pair.sh` prepends the plugin's `bin/` to `PATH` so
that `adb-wireless`'s internal shell-out to bare `adb` finds the bundled
passthrough automatically — no manual PATH change needed.

---

## 4. Pairing lost after reboot or settings change

ADB wireless pairing is persistent across device reboots **as long as** the
device's wireless debugging session remains active and trust is not revoked.

**Pairing is cleared when:**

- The user toggles Wireless debugging off and back on.
- The user revokes trust via:
  `Settings → Developer options → Wireless debugging → Paired devices → (revoke)`

**Symptom:** `android-installer-adb devices` shows the device as unauthorized or not listed at all
after a reboot or settings change.

**Fix:** re-run both scripts:

```bash
android-installer-pair.sh --data-dir "${CLAUDE_PLUGIN_DATA}"
android-installer-connect.sh
```

---

## 5. pair.sh hangs or shows no QR code

**Checklist:**

1. Confirm the `adb-wireless` binary exists and is executable:
   ```bash
   ls -l "${CLAUDE_PLUGIN_DATA}/adb-wireless"
   ```
   If missing, run `android-installer-build-adb-wireless.sh` (see section 3).

2. On the Android device, verify **Wireless debugging is enabled**:
   `Settings → Developer options → Wireless debugging` — the toggle must be on.

3. Ensure the host and device are on the **same Wi-Fi network** (or the same
   subnet). ADB wireless pairing uses mDNS/multicast which does not cross
   subnets.

4. If the terminal shows a blank screen with no QR code after several seconds,
   kill `android-installer-pair.sh` (Ctrl-C) and re-run it. Occasionally the
   pairing daemon on the device needs a moment to advertise.

5. `android-installer-pair.sh` adds the plugin's `bin/` to the front of `PATH`
   automatically, so `adb-wireless`'s internal shell-out to bare `adb` finds
   the bundled passthrough (which forwards to `android-installer-adb`)
   without any manual PATH configuration. If you see `adb: command not found`
   inside the script, the plugin install may be corrupted — reinstall the
   plugin. Do not run `android-installer-build-adb-wireless.sh` to fix this;
   that only creates `adb-wireless`.
