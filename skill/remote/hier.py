#!/usr/bin/env python3
"""Print the whole Maestro view hierarchy — every node, labelled or not.

The original session's dump skipped nodes with no text, which silently hid
every icon button and container. This one prints all of them.

Reads the JSON dump on stdin or from the path in argv[1].
"""
import json
import sys

TEXTISH = ("text", "accessibilityText", "value", "hintText", "title", "label")
FLAGS = ("selected", "checked", "focused")


def load(src):
    raw = src.read()
    # maestro prints banner lines before the JSON
    return json.loads(raw[raw.index("{"):])


def walk(node, depth=0):
    a = node.get("attributes", {}) or {}
    seen, labels = set(), []
    for k in TEXTISH:
        v = (a.get(k) or "").strip().replace("\n", " | ")
        if v and v not in seen:
            seen.add(v)
            labels.append(v)
    label = "  ".join(labels)[:70]

    rid = (a.get("resource-id") or "").strip()
    flags = "".join(k[0].upper() for k in FLAGS if str(a.get(k)) == "true")
    state = "" if str(a.get("enabled")) != "false" else " DISABLED"
    bounds = a.get("bounds", "-")
    ident = "#" + rid + " " if rid else ""
    # unlabelled nodes still get a line — they are often the tappable target
    body = ident + label if (ident or label) else "·"

    print(f"{'  ' * depth}{bounds:24} {flags:3}{state:9} {body}")
    for c in node.get("children", []) or []:
        walk(c, depth + 1)


if __name__ == "__main__":
    src = open(sys.argv[1]) if len(sys.argv) > 1 else sys.stdin
    walk(load(src))
