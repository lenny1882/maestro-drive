#!/usr/bin/env python3
"""What does the text field at a point hold?

Reads a `/viewHierarchy` response on stdin and prints the value of the text field
containing the point, or nothing when that field is empty or there is none. `clear`
uses it to tell a field it emptied from one it left alone (item 145).

It reads `value`, never `label`, because a native field keeps its label when empty,
and a value equal to the placeholder counts as empty. The frame is what picks the
node rather than `hasFocus`, which neither a Flutter field nor a native search field
set when measured on 5 Nov 2026.
"""
import json
import sys

# searchField, textField, secureTextField, textView, as measured or from XCUIElementType.
FIELD_TYPES = {45, 49, 50, 52}


def fields(node):
    if node.get("elementType") in FIELD_TYPES:
        yield node
    for c in node.get("children") or []:
        yield from fields(c)


def holds(frame, x, y):
    fx, fy = frame.get("X", 0), frame.get("Y", 0)
    return fx <= x <= fx + frame.get("Width", 0) and fy <= y <= fy + frame.get("Height", 0)


def main():
    if len(sys.argv) != 3:
        print("usage: fieldvalue.py <x> <y>   (hierarchy on stdin)", file=sys.stderr)
        return 2
    x, y = float(sys.argv[1]), float(sys.argv[2])
    doc = json.load(sys.stdin)
    for node in fields(doc.get("axElement", doc)):
        if holds(node.get("frame") or {}, x, y):
            value = node.get("value") or ""
            if value != (node.get("placeholderValue") or ""):
                print(value)
            return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
