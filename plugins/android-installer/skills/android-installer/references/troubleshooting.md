# adb-install Skill — Troubleshooting Guide

This file is loaded by Claude agents when something goes wrong during the
wireless ADB install workflow.

> **Note:** This skill has no host-resident `adb` binary. All adb commands use
> `android-installer-adb`, a shim bundled in the plugin's `bin/`, which routes
> through the `adb-server` Docker container. A `PreToolUse` hook blocks bare
> `adb` invocations — always use `android-installer-adb`.

---

## 1. Install container cannot reach the adb server (host-gateway issues)

The install container must reach the adb server running on the host. `android-installer-install.sh`
resolves the host address automatically:

- **Docker Desktop (Mac / Windows):** uses `host.docker.internal`, which Docker
  Desktop provides out of the box.
- **Linux:** queries the bridge gateway with `docker network inspect`, then falls
  back to `172.17.0.1` if inspection fails.

If the container starts but then hangs or reports a connection refused error,
the wrong gateway address was resolved. Debug steps:

```bash
# From the host, confirm which address the container should use:
docker network inspect bridge --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}'

# Verify adb is listening on the host:
android-installer-adb devices   # starts the server if not running

# Temporarily override inside a test container:
docker run --rm -e ANDROID_ADB_SERVER_ADDRESS=<gateway-ip> \
  --add-host host.docker.internal:<gateway-ip> \
  <image> adb devices
```

On Linux, if `host.docker.internal` does not resolve, pass
`--add-host host.docker.internal:$(ip route | awk '/default/{print $3}')`
to your `docker run` invocation.

---

## 2. Conflicting adb servers

The install container deliberately does **not** start its own adb server. It
proxies to the host server via the `ANDROID_ADB_SERVER_ADDRESS` environment
variable.

**Symptom:** device is not listed, or you see `adb: failed to start daemon`.

**Cause:** a second adb server is competing on port 5037.

**Fix:**

```bash
# Kill any rogue servers on the host:
android-installer-adb kill-server
android-installer-adb start-server   # restarts cleanly on port 5037

# Do NOT start adb inside the container manually.
```

Only one adb server should be running at a time — the one on the host that
`android-installer-install.sh` connects to.

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
android-installer-build-adb-wireless.sh
```

The script compiles the binary and places it at `${CLAUDE_PLUGIN_DATA}/adb-wireless`,
a directory that persists across plugin updates. After building, re-run
`android-installer-pair.sh`.

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
android-installer-pair.sh
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
