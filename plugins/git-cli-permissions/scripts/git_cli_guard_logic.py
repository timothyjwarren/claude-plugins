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
