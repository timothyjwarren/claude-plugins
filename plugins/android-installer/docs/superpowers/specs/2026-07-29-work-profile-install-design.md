# Install to work profile / non-default user

## Problem

`android-installer-install.sh` always calls `adb install /app.apk` with no user targeting, which
installs into the device's default (personal) profile. There's no way to target a work profile
or any other secondary Android user.

## Design

### 1. `android-installer-list-users.sh` (new script)

Runs inside the existing `android-installer-adb` shim (talks to the persistent `adb-server`
container over the already-connected device):

```bash
android-installer-adb shell pm list users
android-installer-adb shell getprop ro.serialno
```

`pm list users` output looks like:

```
Users:
	UserInfo{0:Owner:c13} running
	UserInfo{10:Work profile:1030} running
```

The script parses each `UserInfo{<id>:<name>:<flags>}` line into `<id>  <name>` and prints it,
followed by the device's hardware serial on its own labeled line, e.g.:

```
User ID  Name
0        Owner
10       Work profile

Device serial: R58N123ABCD
```

The serial is included specifically so the agent can key a cache entry off it (see below).

### 2. `android-installer-install.sh` (modified)

Add an optional `--user <id>` flag, parsed before the positional apk path:

```bash
android-installer-install.sh [--user <id>] <path-to-apk>
```

- Omitted: behavior is unchanged (installs to the default/personal profile).
- Present: the docker-run invocation passes `--user <id>` through to `adb install`, i.e.
  `adb install --user <id> /app.apk`.

No other behavior changes. Argument parsing stays simple (manual `while`/`case` loop consistent
with the other scripts in this plugin, no getopt dependency).

### 3. SKILL.md — new section: "Installing to a work profile / non-default user"

Documents, for the agent:

- Work profiles and other secondary users are separate Android "users" with numeric IDs; the
  default install target is the personal profile (usually user 0).
- To install elsewhere: run `android-installer-list-users.sh` to see available user IDs (and the
  device serial), ask the user which profile they want if it's not obvious (more than one
  non-primary user), then run `android-installer-install.sh --user <id> <apk>`.
- **Caching recommendation (not built into the plugin):** this workflow doesn't persist
  anything itself. *Only when a work-profile/non-default-user install is requested* — not as a
  standing habit — the agent should consider persisting the `<device serial> -> <user id>`
  mapping (e.g. via its memory system, if available) so it doesn't need to re-ask which profile
  to use for that same device next time. This is a suggestion for the agent to apply
  judgment on, not a requirement enforced by the plugin.

### 4. Script reference table

Add a row for `android-installer-list-users.sh`.

## Out of scope

- No built-in cache/state file in the plugin itself — caching is left entirely to the invoking
  agent, per explicit user direction.
- No changes to pairing, connect, or server lifecycle scripts.
- No validation that a given `--user <id>` actually exists before attempting install; `adb
  install` will surface its own error if the ID is invalid, which is sufficient.
