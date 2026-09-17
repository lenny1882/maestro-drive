#!/usr/bin/env python3
"""Split one journey line into arguments, then expand ${VAR} inside each.

Reads a line on stdin, writes its arguments NUL-separated on stdout.

The order is the whole point. Expanding the file first and splitting it
afterwards is how `text ${USER}` with `USER="Test User"` came to type only
"Test": the value's space became a token boundary and everything after it was
dropped in silence. The shorter string still filtered the list and still
matched something, so a session set a device to the wrong user and the wrong
location and reported success (BACKLOG.md item 14).

Splitting first gives a variable the behaviour anyone would assume:

    text ${USER}                one argument, however many spaces it holds
    tapon "^${PREFIX} Store$"   expands inside the pattern without breaking it
    log ${NOTE}                 a # in the value is not a comment

An unset name is left as written rather than becoming an empty string, so a
missing variable fails loudly on the verb that used it instead of quietly
typing nothing.
"""
import os
import re
import shlex
import sys

VAR = re.compile(r"\$\{(\w+)\}")


def expand(token):
    return VAR.sub(lambda m: os.environ.get(m.group(1), m.group(0)), token)


def main():
    try:
        args = shlex.split(sys.stdin.read())
    except ValueError as e:
        print("journey: cannot parse the line (%s)" % e, file=sys.stderr)
        return 2
    sys.stdout.write("\0".join(expand(a) for a in args))
    return 0


if __name__ == "__main__":
    sys.exit(main())
