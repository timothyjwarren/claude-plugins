import shlex

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
