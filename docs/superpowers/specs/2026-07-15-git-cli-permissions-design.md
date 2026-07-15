# git-cli-permissions plugin design

## Problem

`git` and `gh` CLI invocations currently go through Claude Code's normal permission
system undifferentiated. Purely local, reversible operations (`git status`, `git add`,
`gh pr view`) get the same treatment as operations with off-machine effects visible to
others (`git push`, `gh pr create`, `gh pr comment`). This either means over-prompting
for safe local operations, or a blanket allow rule that also covers risky remote
operations.

## Goal

A `PreToolUse` hook that recognizes a specific set of confirmed-safe, local-only
`git`/`gh` invocations and auto-approves them, while staying silent on everything else
so the user's existing permission configuration (prompts, always-allow rules, etc.)
continues to apply unmodified.

## Non-goals

- The hook never blocks (no exit 2 / deny).
- The hook never forces an approval prompt (no `ask`) — it must not override a user's
  own always-allow configuration for something like `git push`.
- No coverage of git/gh commands beyond the classification tables below in this first
  version — anything not explicitly listed defers.

## Architecture

Single `PreToolUse` hook, matcher `Bash`, following the existing `*-guard.sh` pattern
used by `android-builder`, `npm-builder`, `golang-builder`, and `android-installer`
(bash entrypoint, embedded Python for JSON/command parsing).

```
plugins/git-cli-permissions/
  .claude-plugin/plugin.json
  hooks/hooks.json
  scripts/git-cli-guard.sh
```

No `bin/`, `skills/`, or `dockerfiles/` — this plugin has no agent-invoked scripts and
no user-facing skill, it's purely a hook.

## Hook contract

Confirmed via Claude Code docs (`code.claude.com/docs/en/hooks.md`):

- Exit 0 + no stdout JSON → defer to normal permission handling.
- Exit 0 + stdout JSON `{"hookSpecificOutput": {"hookEventName": "PreToolUse",
  "permissionDecision": "allow", "permissionDecisionReason": "..."}}` → explicit
  allow, skips the permission check.

This plugin only ever uses these two outcomes.

## Command parsing

The hook receives the full `command` string. Because bash allows chaining
(`git add . && git push`, `git commit -m x; gh pr create`), the string must be split
into individual command segments before classification:

1. Tokenize with Python's `shlex`, using `punctuation_chars` enabled so `&&`, `||`,
   `;`, `|` become distinct tokens.
2. Split the token stream into segments at those operator tokens.
3. Re-`shlex.split()` each segment's raw text into argv-style tokens for
   classification.

## Classification

### git

Token[1] (the subcommand) is checked:

- Flat-safe subcommands: `add, commit, branch, checkout, fetch, pull, status, diff,
  log, stash, tag, merge, rebase, reset, show, blame, restore, switch`.
  - `pull` is only flat-safe because the user sets `git config --global pull.ff only`
    outside this plugin, making every `git pull` invocation fast-forward-only at the
    config level. The hook does not itself inspect `pull` flags.
- `remote` — safe only when read-only: bare `git remote`, `git remote -v`, or
  `git remote show`. Any other subcommand (`add`, `set-url`, `remove`, `rm`, `rename`,
  `set-head`, `set-branches`, `prune`) is not safe (defers) because it mutates remote
  configuration.
- `clone`, `push`, and any unrecognized subcommand are not safe (defer).

### gh

Requires the shape `gh <noun> <verb> ...` (token[0]=`gh`, token[1]=noun,
token[2]=verb). The `(noun, verb)` pair must be in this explicit table to be safe:

```
(pr, view)  (pr, list)  (pr, diff)  (pr, checks)  (pr, status)
(issue, view)  (issue, list)  (issue, status)
(repo, view)  (repo, list)
(run, view)  (run, list)
(workflow, view)  (workflow, list)
(release, view)  (release, list)
```

Pairs are enumerated individually and deliberately not generalized (e.g. "any noun +
view is safe") — each pair should be reasoned about on its own before being added.
Anything not in the table — unlisted pairs, missing verb (bare `gh pr`), commands with
no noun/verb shape (`gh api`, `gh auth`, `gh browse`, `gh config`) — defers.

## Overall decision

Per Bash tool call (which may contain multiple chained segments):

- If every segment is a recognized-safe git/gh invocation → emit `permissionDecision:
  "allow"` with a reason summarizing which command(s) were recognized.
- Otherwise (any segment is non-git/gh, an unrecognized git/gh subcommand, or an
  explicitly unsafe one like `push`) → exit 0 with no JSON output (defer for the whole
  call — the hook cannot partially approve a compound command).

## plugin.json

```json
{
  "name": "git-cli-permissions",
  "description": "Auto-approve safe, local-only git/gh commands (status, diff, add, commit, fetch, pull, gh pr view, etc.); defer everything else to normal permission settings",
  "category": "development"
}
```

## Future extraction

Classification tables start as inline Python data structures in
`scripts/git-cli-guard.sh` (matching this repo's existing guard-script convention).
Extracting them into a separate config file is a plausible future step once the tables
grow, but is explicitly out of scope for the first version.

## Testing

Two layers, both repeatable and checked into the repo:

1. **Unit tests** for the parsing/classification logic (segment splitting, git
   subcommand table, `remote` sub-dispatch, gh `(noun, verb)` table, overall
   allow/defer combination) as a standalone Python test module, run directly with
   `python3` (no external test framework dependency, matching this repo's
   no-build-step script style).
2. **Script-level test harness**: a script (e.g. `scripts/test-git-cli-guard.sh`) that
   feeds a table of sample JSON stdin payloads to `scripts/git-cli-guard.sh` itself and
   asserts the actual exit code/stdout against the expected decision, so the real
   entrypoint (not just the inner logic) is covered end to end. Cases to include: each
   flat-safe git subcommand, `git remote -v` vs `git remote add`, `git pull`, `git
   clone`, `git push`, each whitelisted gh pair, an unlisted gh pair, `gh api`/`gh
   auth`, a chained command mixing safe and unsafe segments, and a chained command
   where all segments are safe.

Both are run manually: `python3 scripts/test_git_cli_guard_logic.py` and
`scripts/test-git-cli-guard.sh`.
