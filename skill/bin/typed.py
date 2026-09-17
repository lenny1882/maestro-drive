#!/usr/bin/env python3
"""Did the text that was just typed actually land in the field?

Reads a `/viewHierarchy` response on stdin. The check is scoped to the node that
has focus — the field the keystrokes went to — and compares what that field now
holds against what was typed. Exit 0 means it matches, 1 means it does not.

`type` is a tap followed by keystrokes, and both halves fail quietly. A tap that
misses the field types into whatever had focus — on 12 Aug 2026 that put a stray
character into a store field and the run carried on. A value that arrives
shortened looks like the app truncating it: `text ${USER}` with
`USER="Test User"` typed `Test`, which still filtered a list and still matched
something, so the journey reported success and set the wrong user (item 14).

Two earlier holes, both from checking the whole tree for a substring (item 31):
a field already holding `4001` that a non-searchable dropdown appended `LOC1` to
reads as `4001LOC1`, which *contains* `LOC1`; and a dropdown row whose own label is
`LOC1` puts the string on screen whether or not the field received it. Scoping to
the focused node and comparing its value for equality closes both — `4001LOC1` is
not `LOC1`, and a menu row is not the focused field.

Two things this deliberately does NOT do:

- **A secure field is exempt.** It never shows what it holds, so a PIN that
  arrived perfectly is invisible here; when the focused field is secure this says
  nothing rather than failing a login journey on its own PIN step.
- **Nothing focused means no check.** If no node has focus there is no field to
  read the value from, so this says so and passes rather than falling back to a
  tree-wide search that reads as a check and is not one. A tap that missed onto
  another field is still caught, because that field then has focus and holds the
  wrong value; only a tap onto empty space goes unjudged.

What this still does NOT check is what the app then DID with the text. The
dropdown failure behind item 14 puts `LOC1` in the field correctly and commits
`4001` anyway; only an `expect` on the committed value catches that.
"""
import json
import sys

SECURE_FIELD = 50
# The field's own content, not the placeholder (which is the hint, not what was
# typed) — matching placeholderValue would pass on an empty field.
CONTENT_KEYS = ("value", "label", "title")


def norm(v):
    return " ".join(str(v).split())


def field_texts(node):
    for k in CONTENT_KEYS:
        v = node.get(k)
        if v:
            yield norm(v)


def focused(node):
    if node.get("hasFocus"):
        return node
    for c in node.get("children") or []:
        f = focused(c)
        if f is not None:
            return f
    return None


def main():
    if len(sys.argv) != 2:
        print("usage: typed.py <text>   (hierarchy on stdin)", file=sys.stderr)
        return 2
    wanted = norm(sys.argv[1])
    if not wanted:
        return 0
    try:
        root = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print("typed: hierarchy is not valid JSON (%s)" % e, file=sys.stderr)
        return 2
    root = root.get("axElement", root)

    node = focused(root)
    if node is None:
        print("typed: nothing has focus, so there is no field to read the typed "
              "value from — passing without checking (item 31)", file=sys.stderr)
        return 0
    if node.get("elementType") == SECURE_FIELD:
        return 0

    have = list(field_texts(node))
    if wanted in have:
        return 0
    shown = have[0] if have else "(empty)"
    print('typed: the focused field holds "%s", not "%s" — the text did not land '
          "as typed. A missed tap types into whatever had focus, and typing into "
          "a field that already held a value appends to it." % (shown, sys.argv[1]),
          file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
