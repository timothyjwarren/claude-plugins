import json
import shlex
import sys

_OPERATOR_TOKENS = {"&&", "||", ";", "|"}


def split_segments(command):
    """Split a shell command string into segments at &&, ||, ;, |.

    Tokenizes with shlex.shlex(punctuation_chars=True) first so quoted
    text is respected (an operator inside quotes is kept as part of the
    token, not treated as a separator), then groups the resulting token
    stream into segments at the operator tokens.
    """
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return []

    segments = []
    current = []
    for tok in tokens:
        if tok in _OPERATOR_TOKENS:
            if current:
                segments.append(current)
                current = []
        else:
            current.append(tok)
    if current:
        segments.append(current)
    return segments


GIT_FLAT_SAFE_SUBCOMMANDS = {
    "add", "commit", "branch", "checkout", "fetch", "pull", "status",
    "diff", "log", "stash", "tag", "merge", "rebase", "reset", "show",
    "blame", "restore", "switch",
}


def classify_git(tokens):
    """Return True if a `git ...` token list is a recognized-safe invocation."""
    if len(tokens) < 2:
        return False
    subcommand = tokens[1]
    if subcommand == "remote":
        rest = tokens[2:]
        return not rest or rest == ["-v"] or rest == ["show"]
    return subcommand in GIT_FLAT_SAFE_SUBCOMMANDS


GH_SAFE_PAIRS = {
    ("pr", "view"), ("pr", "list"), ("pr", "diff"), ("pr", "checks"),
    ("pr", "status"),
    ("issue", "view"), ("issue", "list"), ("issue", "status"),
    ("repo", "view"), ("repo", "list"),
    ("run", "view"), ("run", "list"),
    ("workflow", "view"), ("workflow", "list"),
    ("release", "view"), ("release", "list"),
}


def classify_gh(tokens):
    """Return True if a `gh <noun> <verb>` token list's pair is safe-listed."""
    if len(tokens) < 3:
        return False
    noun, verb = tokens[1], tokens[2]
    return (noun, verb) in GH_SAFE_PAIRS


def is_safe_segment(tokens):
    if not tokens:
        return False
    if tokens[0] == "git":
        return classify_git(tokens)
    if tokens[0] == "gh":
        return classify_gh(tokens)
    return False


def decide(command):
    """Given a raw shell command string, return an allow decision dict,
    or None to defer to normal permission handling."""
    if not command or not command.strip():
        return None
    segments = split_segments(command)
    if not segments or not all(is_safe_segment(seg) for seg in segments):
        return None
    reason = "Recognized safe git/gh command(s): " + " | ".join(
        " ".join(seg) for seg in segments
    )
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": reason,
        }
    }


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
        command = data.get("command", "")
    except (json.JSONDecodeError, AttributeError):
        command = ""

    result = decide(command)
    if result is not None:
        print(json.dumps(result))
    sys.exit(0)


if __name__ == "__main__":
    main()
