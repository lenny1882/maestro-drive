#!/usr/bin/env python3
"""Flag an SSH call inside a loop whose input arrives on stdin.

`_ssh` passes stdin to the remote command, so an ssh call inside a loop reading
from a pipe eats every line not yet read: the loop runs once and the rest of the
list disappears, silently, with a zero exit.

Three sightings on 17 Sep 2026 alone — `ports adopt` reported one driver of
four, `_rig_status` printed one device of seven, and `drivers.sh up` has carried
a prose comment about the trap for weeks. Prose did not stop it.

The fix is always the same: read the list before the loop
(`rows=(); mapfile -t rows < <(...)`), then iterate the array.
"""
import re
import sys

# Calls that consume stdin on their way to the Mac.
SSH = re.compile(r"(?<![\w-])(_ssh|scp|ssh)(?![\w-])")
# The dangerous shapes: a loop fed by a pipe, or one redirected from a process
# substitution. `for x in $(...)` is safe — the substitution is fully expanded
# before the loop starts — so it is not matched.
OPENS = re.compile(r"\|\s*while\s+(IFS=\S*\s+)?read\b"
                   r"|^\s*while\s+(IFS=\S*\s+)?read\b")
# `read -u <fd>` reads from an explicit descriptor, not stdin, so an ssh inside
# cannot touch it. That is the documented fix (item 36, `_journey`), and a lint
# that flagged it would train people to undo it.
EXPLICIT_FD = re.compile(r"\bread\b[^|;]*\s-\w*u\b|\bread\b[^|;]*\s-u\s")
CLOSES = re.compile(r"^\s*done\b")
NEWFUNC = re.compile(r"^\s*[\w:.-]+\s*\(\)\s*\{")

bad = []
for path in sys.argv[1:]:
    lines = open(path).read().splitlines()
    i = 0
    while i < len(lines):
        if (lines[i].lstrip().startswith("#")
                or not OPENS.search(lines[i])
                or EXPLICIT_FD.search(lines[i])):
            i += 1
            continue
        # Walk the body to its own `done`. Give up at a new function definition
        # or after 80 lines rather than swallowing the rest of the file — an
        # unbalanced scan is what made the first cut of this lint useless.
        # A loop written on one line (`while read ...; do ...; done < <(...)`)
        # is already closed, and the lines after it are the substitution that
        # FEEDS it — not its body. Scanning on from there is what made the first
        # two cuts of this lint report six false positives in build.sh.
        if re.search(r"\bdone\b", lines[i]):
            i += 1
            continue
        j, depth = i + 1, 1
        while j < len(lines) and j - i < 80:
            t = lines[j]
            if NEWFUNC.match(t):
                break
            if re.match(r"^\s*(while|for|until)\b", t) and t.rstrip().endswith(("do", "do;")):
                depth += 1
            if CLOSES.match(t):
                depth -= 1
                if depth == 0:
                    break
            if not t.lstrip().startswith("#"):
                m = SSH.search(t)
                # A call that closes its own stdin is safe, and that is the
                # documented workaround where the read cannot be hoisted.
                if m and "</dev/null" not in t and "< /dev/null" not in t:
                    bad.append((path, j + 1, m.group(1), t.strip()[:66]))
            j += 1
        i = j + 1

for path, n, fn, text in bad:
    print("%s:%d  `%s` inside a loop reading from stdin" % (path, n, fn))
    print("      %s" % text)
    print("      _ssh consumes the pipe — the loop will run once.")
    print("      Hoist the read:  rows=(); mapfile -t rows < <(...)")
    print("      or close its stdin:  _ssh ... </dev/null")
sys.exit(1 if bad else 0)
