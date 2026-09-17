"""Print a view hierarchy as an indented tree. Reads /viewHierarchy JSON on
stdin; `nodes` as the argument prints every node, `tree` only the ones carrying
a label or an identifier.

The unlabelled containers `tree` hides carry the frames that explain an overlay
reported in a parent's local space, so read `nodes` rather than measuring a
screenshot when a frame looks wrong.

Split out of driver.sh on 13 Aug 2026 so that `tapon --tree` could reuse it and
so that the renderer itself could be tested (BACKLOG.md item 7).
"""
import json
import sys

# XCUIElement.ElementType raw values. Maestro treats 12/40/41 as checkable
# (IOSDriver.CHECKABLE_ELEMENTS), which is why `checked:` matches nothing else.
TYPES = {1: "other", 2: "app", 3: "group", 4: "window", 7: "alert", 9: "button",
         12: "checkbox", 14: "popupbtn", 15: "combobox", 18: "popover",
         19: "keyboard", 20: "key", 21: "navbar", 22: "tabbar", 24: "toolbar",
         25: "statusbar", 26: "table", 27: "row", 32: "collection", 33: "slider",
         37: "segmented", 38: "picker", 39: "pickerwheel", 40: "switch",
         41: "toggle", 42: "link", 43: "image", 44: "icon", 45: "searchfld",
         46: "scrollview", 48: "text", 49: "textfield", 50: "securefld",
         52: "textview", 53: "menu", 54: "menuitem", 58: "webview", 75: "cell",
         79: "stepper", 80: "tab"}

MODE = sys.argv[1] if len(sys.argv) > 1 else "tree"
ALL = MODE == "nodes"
COMPACT = MODE == "text"

SKIP_TYPES = {19, 20, 25}  # keyboard, key, statusbar


def walk(n, depth=0):
    f = n.get("frame") or {}
    box = "%4d,%-4d %4dx%-4d" % (f.get("X", 0), f.get("Y", 0),
                                 f.get("Width", 0), f.get("Height", 0))
    _raw = " ".join(dict.fromkeys(
        x for x in (n.get("label"), n.get("title"), n.get("value"),
                    n.get("placeholderValue")) if x
    )).strip()
    label = _raw[:60] + "…" if len(_raw) > 60 else _raw
    ident = n.get("identifier") or ""
    _fg = "".join(k[0].upper() for k in ("selected", "hasFocus") if n.get(k))
    flags = "[%-2s]" % _fg if _fg else "    "
    dis = " DISABLED" if not n.get("enabled", True) else ""
    if label or ident or ALL:
        print("%s%s %-9s %s%s %s%s" % (
            "  " * depth, box,
            TYPES.get(n.get("elementType"), "t%s" % n.get("elementType")),
            flags, dis, ("#" + ident + " ") if ident else "", label))
    for c in n.get("children") or []:
        walk(c, depth + 1)


def walk_compact(n, seen):
    et = n.get("elementType")
    if et in SKIP_TYPES:
        return
    _raw = " ".join(dict.fromkeys(
        x for x in (n.get("label"), n.get("title"), n.get("value"),
                    n.get("placeholderValue")) if x
    )).strip()
    if _raw and _raw not in seen:
        seen.add(_raw)
        label = _raw[:80] + "…" if len(_raw) > 80 else _raw
        dis = "" if n.get("enabled", True) else "  DISABLED"
        tname = TYPES.get(et, "t%s" % et)
        print("%-9s %s%s" % (tname, label, dis))
    for c in n.get("children") or []:
        walk_compact(c, seen)


d = json.load(sys.stdin)
if COMPACT:
    seen = set()
    walk_compact(d["axElement"], seen)
    if not seen:
        print("(no text nodes — a modal, camera, or loading screen?)")
else:
    walk(d["axElement"])
