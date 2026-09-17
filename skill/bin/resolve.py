#!/usr/bin/env python3
"""Resolve a label pattern in a Maestro iOS driver hierarchy to a tap point.

Reads a `/viewHierarchy` response on stdin and prints the absolute centre, in
device points, of every node whose text matches a pattern. This is the
arithmetic that reference/driving.md describes, done from the tree rather than by eye
off a screenshot.

The whole thing rests on one observation, captured from a live tree on
11 Aug 2026 (paths abbreviated):

    …1.1.1.0        0,0       134x291   <- marker, 402/3 x 874/3
    …1.1.1.1       15.9,39.7  102x18    "some label on the screen"
    …2.1.1.0      -47.6,-363  402x874   <- marker, screen-sized, negative origin
    …2.1.1.1.1.2    0,-56     306x48    "42 - Camden Road Store"

**A container's first child may be a marker that defines the coordinate space
for that container's children.** The marker is a *sibling* of the content, not
an ancestor of it — which is why walking the parent chain looking for a
transform finds nothing but full-screen containers, and why measuring a
screenshot felt like the only option.

A marker is any node whose frame is the screen divided by some factor k. It
sets the transform for its container's children to
`absolute = reported * k - markerOrigin * k`. Both of the misreported spaces
above are that one rule:

- `0,0 134x291` is the screen divided by 3, so its siblings are at 1/3 scale
  and get multiplied by 3. `15.9,39.7` becomes `47.7,119.1` — which is where
  that label actually sits.
- `-47.6,-363 402x874` is the screen at full scale shifted by its own origin,
  so its siblings are local offsets and get that origin subtracted. The item
  `0,-56` becomes `47.6,307`, centre `(200.9, 331)`.

Markers replace rather than compose: the overlay marker sits inside the 1/3
space but its own frame is full scale, so the outer factor is discarded. Most
containers begin with an ordinary `0,0 402x874` child, which makes k = 1 and
the offset zero — the identity — so the same rule runs everywhere and costs
nothing. A frame that is screen-width but not screen-height (the status bar at
402x54, the keyboard's 402x1245 scroll extent) is not a marker, which is what
keeps those subtrees from being shifted.

A resolved point is not automatically a reachable one. Two ways it is not,
both of which the driver reports as ordinary visible elements: the frame can be
off the bottom of the screen (a button below the fold reads y=1012 on an
874-point screen), and it can be underneath the keyboard. Both are refused
rather than tapped, because a tap on either fails silently — or worse, lands on
the typing-prediction bar and edits the field.

Two things this deliberately does not do. It does not guess: a pattern matching
more than one node is an error, not a coin toss. And it does not hide its
working — `--explain` prints the transform chain behind every answer, because
the rule above is drawn from a handful of observed screens and deserves to be
checked rather than trusted.
"""
import argparse
import json
import re
import sys
import textwrap

TEXT_KEYS = ("label", "title", "value", "placeholderValue", "identifier")
# Maestro replaces newlines with spaces before matching, and so do we. Labels
# wrapped mid-word by the app are otherwise unmatchable by anything you can
# read off the screen.
WS = re.compile(r"\s+")

# A node counts as screen-sized if its frame is within this many points of the
# screen divided by some factor. Frames come back with sub-pixel noise
# (402.0000001, 873.9999) and 874/3 is not an integer, so the slack is needed.
TOL = 2.0


def norm(s):
    return WS.sub(" ", s).strip() if s else ""


def texts(node):
    return [t for t in (norm(node.get(k)) for k in TEXT_KEYS) if t]


def frame(node):
    f = node.get("frame") or {}
    return (
        float(f.get("X", 0.0)),
        float(f.get("Y", 0.0)),
        float(f.get("Width", 0.0)),
        float(f.get("Height", 0.0)),
    )


def space_factor(w, h, screen_w, screen_h):
    """If this frame maps onto the whole screen, return the factor k, else None.

    k is what you multiply the node's own coordinates by to get device points,
    so a full-screen node gives 1 and a third-scale one gives 3.
    """
    if w <= 0 or h <= 0:
        return None
    k = screen_w / w
    if abs(w * k - screen_w) <= TOL and abs(h * k - screen_h) <= TOL:
        return k
    return None


def walk(node, screen_w, screen_h):
    """Yield (node, absolute_frame, transform_chain) for every node.

    The transform for a node's children is set by that node's *first* child, if
    that child is a marker (see the module docstring). Identity markers are not
    recorded in the chain — every container has one and they say nothing.
    """
    def rec(n, scale, off_x, off_y, chain):
        x, y, w, h = frame(n)
        yield n, (x * scale + off_x, y * scale + off_y, w * scale, h * scale), chain

        children = n.get("children") or []
        if not children:
            return

        c_scale, c_off_x, c_off_y, c_chain = scale, off_x, off_y, chain
        mx, my, mw, mh = frame(children[0])
        k = space_factor(mw, mh, screen_w, screen_h)
        if k is not None:
            c_scale, c_off_x, c_off_y = k, -mx * k, -my * k
            if (k, c_off_x, c_off_y) != (1.0, 0.0, 0.0):
                c_chain = chain + [
                    "marker %gx%g at %g,%g -> scale %.4g offset %+.5g,%+.5g"
                    % (mw, mh, mx, my, k, c_off_x, c_off_y)
                ]

        for c in children:
            yield from rec(c, c_scale, c_off_x, c_off_y, c_chain)

    yield from rec(node, 1.0, 0.0, 0.0, [])


STATUS_BAR, ALERT, KEYBOARD = 25, 7, 19
SYSTEM_TYPES = (STATUS_BAR, ALERT, KEYBOARD)


def system_subtrees(node):
    """Ids of every node drawn by iOS rather than by the app.

    The status bar, permission alerts and the keyboard belong to system
    processes. On a landscape-locked app they are reported in a different
    coordinate space to the app's own nodes (see system_transform), so they
    have to be found before anything measures them.
    """
    ids = set()

    def mark(n):
        ids.add(id(n))
        for c in n.get("children") or []:
            mark(c)

    def rec(n):
        lab = " ".join(str(n.get(k) or "") for k in ("identifier", "label"))
        if n.get("elementType") in SYSTEM_TYPES or any(m in lab for m in KEYBOARD_MARKS):
            mark(n)
            return
        for c in n.get("children") or []:
            rec(c)

    rec(node)
    return ids


def system_transform(node, screen_w, screen_h):
    """How to turn a system frame into an app frame, or None if they agree.

    A landscape-locked iPad app renders at 1194x834 while the device's native
    orientation stays portrait, 834x1194. The app's own nodes come back in the
    app's space; anything iOS draws comes back in the native one. Nothing in a
    node says which it is, so `tapon` on a permission alert resolved a point in
    the wrong space and missed silently (measured 12 Aug 2026).

    The status bar is the tell, because it is always present and always a thin
    strip along one edge. When it comes back 24x1194 against a 1194x834 screen —
    thin on the wrong axis, long side matching the screen's width — the two
    spaces are transposed, and which edge its x sits on says which way round.

    Verified on an iPad Pro 11-inch, iOS 16.4, status bar at x=810: the Allow
    button of the notification permission dialog reports 337.5,597.5 44x134.5,
    which this turns into centre 664.8,474.5 — the tap that works. The x=0 case
    is the same arithmetic mirrored and has NOT been confirmed against a tap.
    """
    bar = None

    def rec(n):
        nonlocal bar
        if bar is not None:
            return
        if n.get("elementType") == STATUS_BAR:
            bar = frame(n)
            return
        for c in n.get("children") or []:
            rec(c)

    rec(node)
    if bar is None:
        return None
    bx, by, bw, bh = bar
    if bw <= 0 or bh <= 0 or bw >= bh:
        return None                      # upright: the two spaces agree
    if abs(bh - screen_w) > TOL:
        return None                      # not the screen's long side; not this
    native_w, native_h = screen_h, screen_w
    if bx >= native_w - bw - TOL:        # bar down the right edge
        return ("landscapeLeft",
                lambda x, y, w, h: (y, native_w - (x + w), h, w))
    return ("landscapeRight-or-portrait",
            lambda x, y, w, h: (native_h - (y + h), x, h, w))


def image_rotation(node, screen_w, screen_h):
    """Degrees clockwise to turn a raw screenshot upright, 0 if it already is.

    `/screenshot` gives the device's native pixels, so a landscape-locked app
    on a natively-portrait iPad comes back on its side — 1668x2388 for a screen
    the app draws as 1194x834. Correcting it by hand is what session B spent
    eight `sips -r 270` calls on.

    The same status bar that tells system space from app space tells which way
    round, so this is that one detection reused rather than a second guess:

        bar down the right edge (x=810 on an 834-wide device)  landscapeLeft   270
        bar down the left edge  (x=0)                          landscapeRight   90

    Both measured on an iPad Pro 11-inch, iOS 16.4, 13 Aug 2026, by rotating the
    simulator and reading the picture back each way. 270 is also the value
    session B arrived at by hand for the first of them.
    """
    t = system_transform(node, screen_w, screen_h)
    if t is None:
        return 0
    return 270 if t[0] == "landscapeLeft" else 90


def keyboard_geometry(node, screen_w, screen_h):
    """Top edge, thickness and the containers behind them, in app space, of what the software keyboard covers.

    Use the keyboard's reported POSITION when it is in the screen's own
    coordinate space, and its SIZE only when it is not. The discriminator is in
    the same node: the keyboard always spans the app's full width, so when its
    reported width matches the screen width it is a single space and the reported
    top edge is trustworthy; when it does not (an iPad's native space, e.g.
    425 wide against a 1194-wide app), the position arrives in the wrong space and
    only the thickness can be believed. Thickness is the smaller of the stack's
    two extents — the keyboard is never taller than it is wide.

    This corrects item 30. Taking the size unconditionally (the 12 Aug fix) made
    the guard fire whenever a keyboard node existed at all: on the iPhone a
    keyboard parked DOWN reports 0,874 402x305 on an 874-point screen, and
    size-only gave a band at 874-305=569 and refused taps on a screen the keyboard
    was not covering. Reading the position gives a top of 874 — at the bottom edge
    — so the final clause returns None: a keyboard at or below screen_h covers
    nothing. The iPad native case (3,0 425x1194 on an 834-tall screen) still falls
    to the size path, 834-425=409, where it always worked.
    """
    xs, ys, xe, ye, parts = [], [], [], [], []
    assistant_ys, assistant_ye = [], []

    # Only the keyboard's own top-level containers. Its descendants carry
    # frames in their own local spaces — a key at x=-227, the prediction bar's
    # 402x1245 scroll extent — and unioning those gives a band wider than the
    # screen and a negative top edge.
    def rec(n):
        lab = " ".join(str(n.get(k) or "") for k in ("identifier", "label"))
        if n.get("elementType") == KEYBOARD or any(m in lab for m in KEYBOARD_MARKS):
            x, y, w, h = frame(n)
            if w > 0 and h > 0:
                xs.append(x); ys.append(y); xe.append(x + w); ye.append(y + h)
                ident = n.get("identifier") or n.get("label") or "keyboard"
                parts.append("%s %gx%g" % (ident, w, h))
                if "SystemInputAssistantView" in lab:
                    assistant_ys.append(y)
                    assistant_ye.append(y + h)
            return
        for c in n.get("children") or []:
            rec(c)

    rec(node)
    if not xs:
        return None
    kb_w = max(xe) - min(xs)
    thickness = min(kb_w, max(ye) - min(ys))
    if abs(kb_w - screen_w) <= TOL:
        top = min(ys)                    # single space — the reported top is real
        basis = ("the keyboard spans the full screen width (%g), so this is its "
                 "reported top edge in app space, from %s"
                 % (kb_w, " and ".join(parts)))
    else:
        top = screen_h - thickness       # native space — position is untrustworthy
        basis = ("%g is the %g-point screen less the keyboard's thickness of %g, "
                 "measured from %s — sizes, not positions, because the keyboard "
                 "reports its position in the device's own space (width %g) rather "
                 "than the app's" % (top, screen_h, thickness, " and ".join(parts), kb_w))
    if top >= screen_h - TOL:
        return None                      # parked at or below the bottom: covers nothing
    # The prediction bar (SystemInputAssistantView) sits above the keyboard
    # proper and can intercept taps aimed at elements beneath it. Record its
    # top edge separately so the refusal can name it.
    predict_band = (min(assistant_ys), max(assistant_ye)) if assistant_ys else None
    return top, thickness, parts, basis, predict_band


def keyboard_band(node, screen_w, screen_h):
    """Just the top edge. The whole shape is in keyboard_geometry."""
    g = keyboard_geometry(node, screen_w, screen_h)
    return None if g is None else g[0]


KEYBOARD_MARKS = ("SystemInputAssistantView", "UIKeyboardLayoutStar")


def keyboard_subtree(node):
    """Return the set of node ids belonging to the on-screen keyboard.

    The driver reports an element the keyboard covers exactly as it reports any
    other: right frame, enabled, visible, no hint that a tap there will never
    reach it. On 11 Aug 2026 that cost several minutes — taps aimed at a list
    row under the keyboard landed on the typing-prediction bar and typed "The "
    into the field instead of choosing anything.
    """
    ids = set()

    def mark(n):
        ids.add(id(n))
        for c in n.get("children") or []:
            mark(c)

    def rec(n):
        lab = " ".join(str(n.get(k) or "") for k in ("identifier", "label"))
        if n.get("elementType") == 19 or any(m in lab for m in KEYBOARD_MARKS):
            mark(n)
            return
        for c in n.get("children") or []:
            rec(c)

    rec(node)
    return ids


def _outside(cx, cy, screen_w, screen_h):
    """Which way, and by how far, a centre falls outside the screen."""
    out = []
    if cx < 0:
        out.append("%.1f points left of it" % -cx)
    elif cx > screen_w:
        out.append("%.1f points right of it" % (cx - screen_w))
    if cy < 0:
        out.append("%.1f points above it" % -cy)
    elif cy > screen_h:
        out.append("%.1f points below it" % (cy - screen_h))
    return " and ".join(out) if out else "on it"


# --- somewhere it is safe to tap ---------------------------------------------
# XCUIElementType numbers for the things a tap does something to. The three
# already named above (STATUS_BAR 25, ALERT 7, KEYBOARD 19) come from the same
# enum, which is how these were checked.
#
# Containers are deliberately absent. A scroll view, a table, a collection view
# and a plain `other` are all things a tap passes through, and treating them as
# obstacles would rule out most of the screen — the sign-in screen measured on
# 13 Aug has a scroll view covering 402x810 of its 402x874.
TAPPABLE_TYPES = frozenset((
    9, 10, 11, 12, 13, 14, 15, 16, 17,   # button and its relatives
    20,                                  # a keyboard key
    27, 75, 80,                          # table row, cell, tab
    33, 34, 37, 38, 39, 40, 41,          # slider, page control, segmented, pickers, switch
    42, 45, 49, 50, 51, 52,              # link, search field, text fields, date picker, text view
    54, 56, 59, 60, 79,                  # menu items, stepper arrows, stepper
))


def _rect_gap(px, py, r):
    """Distance from a point to a rectangle, 0 if the point is inside it."""
    x, y, w, h = r
    dx = max(x - px, 0.0, px - (x + w))
    dy = max(y - py, 0.0, py - (y + h))
    return (dx * dx + dy * dy) ** 0.5


def obstacles(hierarchy, screen_w, screen_h):
    """Every rectangle a tap must miss, in app-space points.

    Three kinds: anything carrying text, anything whose element type reacts to
    a tap, and anything iOS drew rather than the app (the status bar, an
    alert). Full-screen nodes are left out — every app has a stack of them and
    they are the background this is looking for, not an obstacle.
    """
    root = hierarchy["axElement"] if "axElement" in hierarchy else hierarchy
    kb_ids = keyboard_subtree(root)
    sys_ids = system_subtrees(root)
    xform = system_transform(root, screen_w, screen_h)
    out = []
    for n, f, _chain in walk(root, screen_w, screen_h):
        if id(n) in kb_ids:
            continue                      # the band covers the keyboard whole
        if id(n) in sys_ids and xform is not None:
            f = xform[1](*frame(n))       # markers are an app-space construct
        x, y, w, h = f
        if w <= 0 or h <= 0:
            continue
        if w >= screen_w - TOL and h >= screen_h - TOL:
            continue
        why = None
        if texts(n):
            why = texts(n)[0][:40]
        elif n.get("elementType") in TAPPABLE_TYPES:
            why = "a control (type %s)" % n.get("elementType")
        elif id(n) in sys_ids:
            why = "drawn by iOS"
        if why:
            out.append(((x, y, w, h), why))
    return out


def blank_point(hierarchy, screen_w, screen_h, margin=16.0, clearance=20.0):
    """The emptiest point on the screen, for a tap meant to have no effect.

    iOS has no API for putting the keyboard away. Maestro's own `hideKeyboard`
    swipes from the middle of the screen and hopes, which upstream documents as
    flaky, and the workaround upstream recommends is a tap on a non-interactive
    area — so that is what this finds, from the tree rather than by eye.

    The keyboard's own band is one of the obstacles, so the point is always
    above it. What comes back is the candidate furthest from anything, with the
    distance, so a caller can see how much room it had; ties go to the highest
    point, since the top of a screen is usually the title bar.

    It cannot see what the accessibility tree does not report. A Flutter
    gesture detector with no semantics node, or an invisible full-screen scrim,
    is a tap target this has no way to know about — which is why `dismiss`
    checks the keyboard afterwards rather than assuming.
    """
    root = hierarchy["axElement"] if "axElement" in hierarchy else hierarchy
    obs = obstacles(hierarchy, screen_w, screen_h)
    kb = keyboard_geometry(root, screen_w, screen_h)
    bottom = screen_h if kb is None else kb[0]
    if kb is not None:
        obs = obs + [((0.0, kb[0], screen_w, screen_h - kb[0]), "the keyboard")]

    x0, x1 = margin, screen_w - margin
    y0, y1 = margin, bottom - margin
    if x1 <= x0 or y1 <= y0:
        return {"error": "the keyboard leaves no room above it: it starts at "
                         "y=%g on a %g-point screen" % (bottom, screen_h)}

    # The screen's own edges count towards the clearance, or every answer comes
    # back in a corner: the emptiest place on a screen full of centred content
    # is the outside of it, and a tap 2 points from the edge is where iOS puts
    # its own gestures.
    step = max(4.0, min(x1 - x0, y1 - y0) / 60.0)
    best = None
    py = y0
    while py <= y1 + 1e-9:
        px = x0
        while px <= x1 + 1e-9:
            gap, near = min(
                (px, "the left edge"), (screen_w - px, "the right edge"),
                (py, "the top edge"), (bottom - py, "the keyboard"
                                       if kb is not None else "the bottom edge"),
            )
            for r, why in obs:
                d = _rect_gap(px, py, r)
                if d < gap:
                    gap, near = d, why
                    if gap == 0.0:
                        break
            if gap > 0.0 and (best is None or gap > best[0] + 1e-9):
                best = (gap, px, py, near)
            px += step
        py += step

    if best is None or best[0] < clearance:
        got = "nothing" if best is None else "%.1f points" % best[0]
        return {"error": "no point on this screen is %g points clear of "
                         "everything — the best is %s" % (clearance, got),
                "obstacles": len(obs)}
    gap, px, py, near = best
    return {"point": (round(px, 1), round(py, 1)), "clearance": round(gap, 1),
            "nearest": near, "obstacles": len(obs),
            "region": (x0, y0, x1, y1), "step": round(step, 1)}


def matches(hierarchy, pattern, screen_w, screen_h, visible_only=True):
    rx = re.compile(pattern)
    root = hierarchy["axElement"]
    kb_ids = keyboard_subtree(root)
    sys_ids = system_subtrees(root)
    xform = system_transform(root, screen_w, screen_h)
    nodes = list(walk(root, screen_w, screen_h))
    kb = keyboard_geometry(root, screen_w, screen_h)
    kb_top = None if kb is None else kb[0]
    predict_band = None if kb is None else kb[4]

    # Markers are an app-space construct, so a system node's marker-adjusted
    # frame is meaningless. Take its raw frame and put it in app space instead.
    if xform is not None:
        name, fn = xform
        nodes = [
            (n, fn(*frame(n)), c + ["system space (%s) -> app space" % name])
            if id(n) in sys_ids else (n, f, c)
            for n, f, c in nodes
        ]

    found = []
    for n, (x, y, w, h), chain in nodes:
        if visible_only and (w <= 0 or h <= 0):
            continue
        hits = [t for t in texts(n) if rx.search(t)]
        if not hits:
            continue
        cx, cy = x + w / 2, y + h / 2
        warn = why = None
        if not (0 <= cx <= screen_w and 0 <= cy <= screen_h):
            warn = "OFF SCREEN — scroll it into view first"
            why = ["the screen is %gx%g and the centre is %s"
                   % (screen_w, screen_h, _outside(cx, cy, screen_w, screen_h))]
        elif kb_top is not None and id(n) not in kb_ids and cy >= kb_top:
            if predict_band is not None and cy < predict_band[1] + TOL:
                warn = ("UNDER THE PREDICTION BAR — the tap will land on the "
                        "QuickType suggestion strip, not the element")
            else:
                warn = "UNDER THE KEYBOARD — the tap will hit the keyboard instead"
            why = [
                "the keyboard's top edge is y=%g and this centre is %.1f points "
                "below it" % (kb_top, cy - kb_top),
                kb[3],
            ]
            if y < kb_top:
                why.append(
                    "the element's top edge (y=%.1f) is above the keyboard — it "
                    "is partially covered, not fully hidden" % y)
        found.append(
            {
                "text": hits[0],
                "all_text": texts(n),
                "type": n.get("elementType"),
                "enabled": n.get("enabled", True),
                "frame": [round(v, 1) for v in (x, y, w, h)],
                "centre": [round(cx, 1), round(cy, 1)],
                "chain": chain,
                "warn": warn,
                "why": why or [],
            }
        )
    return found


# What to do about a refusal, printed under it. This is deliberately not "type
# to filter the list, then press return": that was recorded as the working
# method for a covered dropdown and measured wrong on 13 Aug 2026 — the list
# does not always filter, and return can commit the first row rather than the
# one that was typed (BACKLOG.md item 14). Sending someone who has just been
# refused a tap towards a method that silently picks the wrong row would be
# worse than saying nothing.
ADVICE = {
    "UNDER THE PREDICTION BAR": [
        "the QuickType suggestion strip sits above the keyboard and intercepts "
        "taps aimed at elements beneath it — a tap there types the predicted "
        "word into the focused field instead of reaching the element",
        "`driver.sh dismiss` puts the keyboard (and with it the prediction bar) "
        "away, or scroll the element clear",
        "--anyway taps regardless, but the tap will land on a suggestion, not "
        "the element",
    ],
    "UNDER THE KEYBOARD": [
        "`driver.sh dismiss` puts the keyboard away — it taps the emptiest "
        "point on the screen, which is the only method iOS offers, and checks "
        "afterwards that the keyboard actually went",
        "or scroll the element clear. Either way, tap it and then assert what "
        "happened with `expect` rather than assuming the tap took",
        "--anyway taps regardless. On 12 Aug that was done on the belief that "
        "the refusal was a false positive, and it typed a stray character into "
        "the field underneath",
    ],
    "NOWHERE BLANK": [
        "every part of this screen above the keyboard has something on it. "
        "Scroll, or close whatever is covering it, and try again",
        "a screen the app fills edge to edge with tappable rows has no safe "
        "point by definition — there is nothing to dismiss the keyboard with "
        "that does not also do something",
    ],
    "OFF SCREEN": [
        "swipe it into view and resolve again — the point moves",
        "a node reported 0,0 0x0 is off a scrolling container's viewport, and "
        "dismissing the keyboard does not bring it back (measured 13 Aug)",
    ],
}


# A screen is a list far more often than it is one element, and until 17 Sep
# 2026 nothing here could say so: --point picks one and refuses when several
# match, the default listing is walk order with the resolver's diagnostics
# interleaved, and neither is something a second reading can be diffed against.
# So every session that needed "what is on the list now" wrote its own recursive
# walk of axElement inside a heredoc — 118 of them over 15-16 Sep 2026, no two
# the same, so two sessions' logs of one screen were not comparable
# (BACKLOG item 72).
#
# Three rules make the output diffable, which is the whole point:
#   * draw order, top to bottom then left to right, never walk order
#   * one line per row, fixed columns, no diagnostics mixed in
#   * an empty list exits 0 with n=0 — a list that has emptied IS the finding,
#     and making it an error is how a watcher records "no change" for it
VIS = {
    None: "vis",
    "OFF SCREEN": "off",
    "UNDER THE KEYBOARD": "kbd",
    "UNDER THE PREDICTION BAR": "kbd",
}


def _vis(m):
    if m["frame"][2] <= 0 or m["frame"][3] <= 0:
        return "zero"
    if not m["warn"]:
        return "vis"
    return VIS.get(m["warn"].split(" —")[0], "??")


def _rows(found, args):
    found = sorted(found, key=lambda m: (m["frame"][1], m["frame"][0]))
    if args.json:
        print(json.dumps([
            {
                "i": i,
                "text": m["text"],
                "vis": _vis(m),
                "frame": m["frame"],
                "centre": m["centre"],
                "enabled": m["enabled"],
            }
            for i, m in enumerate(found)
        ]))
        return 0
    print("n=%d" % len(found))
    for i, m in enumerate(found):
        x, y, w, h = m["frame"]
        print("%3d  %-4s %8.1f,%-8.1f %7.1fx%-7.1f centre %6.1f,%-6.1f%s %s"
              % (i, _vis(m), x, y, w, h, m["centre"][0], m["centre"][1],
                 "" if m["enabled"] else " DISABLED",
                 m["text"][:60] + "\u2026" if len(m["text"]) > 60 else m["text"]))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("pattern", nargs="?",
                    help="regular expression, searched (not anchored); omit with --space")
    ap.add_argument("--width", type=float, required=True, help="screen width in points")
    ap.add_argument("--height", type=float, required=True, help="screen height in points")
    ap.add_argument("--index", type=int, help="pick the Nth match (0-based) instead of failing")
    ap.add_argument("--point", action="store_true", help="print just 'x y' for the single match")
    ap.add_argument("--rect", action="store_true",
                    help="print just 'x y w h' for the single match, in app-space points")
    ap.add_argument("--blank", action="store_true",
                    help="print 'x y' for the emptiest point above the keyboard: somewhere\na tap is meant to do nothing, which is the only way iOS has of putting\nthe keyboard away")
    ap.add_argument("--space", action="store_true",
                    help="print '<space-name> <degrees>' and exit: how the device's native\npixels are turned into app space, and the clockwise rotation that puts a\nraw screenshot upright")
    ap.add_argument("--rows", action="store_true",
                    help="print EVERY match in draw order, one line each, with its\nvisibility — for reading a list off the screen rather than picking one\nelement out of it. Empty is a result, not an error: it exits 0 with n=0.")
    ap.add_argument("--json", action="store_true",
                    help="with --rows, emit a JSON array instead of the text table")
    ap.add_argument("--explain", action="store_true", help="show the transform chain")
    ap.add_argument("--include-hidden", action="store_true", help="include zero-sized nodes")
    ap.add_argument("--anyway", action="store_true",
                    help="give the point even if it is off screen or under the keyboard")
    ap.add_argument("--enabled", action="store_true",
                    help="match only enabled nodes")
    ap.add_argument("--disabled", action="store_true",
                    help="match only disabled nodes")
    args = ap.parse_args()
    if args.pattern is None and not (args.space or args.blank):
        ap.error("a pattern is required unless --space or --blank is given")

    try:
        hierarchy = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print("resolve: hierarchy is not valid JSON (%s)" % e, file=sys.stderr)
        return 2

    if args.blank:
        b = blank_point(hierarchy, args.width, args.height)
        if "error" in b:
            print("resolve: %s" % b["error"], file=sys.stderr)
            for line in ADVICE["NOWHERE BLANK"]:
                print(textwrap.fill(line, 78, initial_indent="  ",
                                    subsequent_indent="  "), file=sys.stderr)
            return 5
        print("%g %g" % b["point"])
        if args.explain:
            print("  %.1f points clear of everything; the nearest thing is %s"
                  % (b["clearance"], b["nearest"]))
            print("  %d obstacles, searched %g,%g..%g,%g every %g points"
                  % ((b["obstacles"],) + b["region"] + (b["step"],)))
        return 0

    if args.space:
        root = hierarchy.get("axElement", hierarchy)
        t = system_transform(root, args.width, args.height)
        print("%s %d" % (t[0] if t else "upright",
                         image_rotation(root, args.width, args.height)))
        return 0

    found = matches(
        hierarchy, args.pattern, args.width, args.height,
        visible_only=not args.include_hidden,
    )

    if args.enabled:
        found = [m for m in found if m["enabled"]]
    elif args.disabled:
        found = [m for m in found if not m["enabled"]]

    if args.rows:
        return _rows(found, args)

    if not found:
        extra = ""
        if args.enabled:
            extra = " (with --enabled filter)"
        elif args.disabled:
            extra = " (with --disabled filter)"
        print("resolve: no visible node matches /%s/%s" % (args.pattern, extra), file=sys.stderr)
        return 3

    if args.index is not None:
        if args.index >= len(found):
            print("resolve: only %d matches for /%s/, wanted index %d"
                  % (len(found), args.pattern, args.index), file=sys.stderr)
            return 3
        found = [found[args.index]]

    if args.rect:
        if len(found) > 1:
            print("resolve: /%s/ matches %d nodes; narrow the pattern or pass --index:"
                  % (args.pattern, len(found)), file=sys.stderr)
            for i, m in enumerate(found):
                print("  [%d] %-40s at %s" % (i, m["text"][:40], m["centre"]), file=sys.stderr)
            return 4
        # No reachability gate here. --point refuses a node under the keyboard
        # because tapping it does the wrong thing silently; cropping a picture
        # to it does not, and a covered element is often exactly what the
        # picture is meant to show.
        print("%g %g %g %g" % tuple(found[0]["frame"]))
        return 0

    if args.point:
        if len(found) > 1:
            print("resolve: /%s/ matches %d nodes; narrow the pattern or pass --index:"
                  % (args.pattern, len(found)), file=sys.stderr)
            for i, m in enumerate(found):
                print("  [%d] %-40s at %s" % (i, m["text"][:40], m["centre"]), file=sys.stderr)
            return 4
        if found[0]["warn"] and not args.anyway:
            print("resolve: /%s/ is at %s, which is %s"
                  % (args.pattern, found[0]["centre"], found[0]["warn"]), file=sys.stderr)
            for line in found[0]["why"] + ADVICE.get(found[0]["warn"].split(" —")[0], []):
                print(textwrap.fill(line, 78, initial_indent="  ",
                                    subsequent_indent="  "), file=sys.stderr)
            return 5
        print("%g %g" % tuple(found[0]["centre"]))
        return 0

    for i, m in enumerate(found):
        x, y, w, h = m["frame"]
        print("[%d] %8.1f,%-8.1f %7.1fx%-7.1f centre %6.1f,%-6.1f t%-3s%s %s"
              % (i, x, y, w, h, m["centre"][0], m["centre"][1], m["type"],
                 "" if m["enabled"] else " DISABLED",
                 m["text"][:50] + "…" if len(m["text"]) > 50 else m["text"]))
        if m["warn"]:
            print("       !! %s" % m["warn"])
            for line in m["why"]:
                print(textwrap.fill(line, 78, initial_indent="          ",
                                    subsequent_indent="          "))
        if args.explain:
            chain = m["chain"] or ["(no coordinate space applied — frame is absolute)"]
            prev, count = None, 0
            for step in chain:
                if step == prev:
                    count += 1
                    continue
                if prev is not None:
                    suffix = " (replaces, not compounds)" if count > 0 else ""
                    print("       %s%s" % (prev, suffix))
                prev, count = step, 0
            if prev is not None:
                suffix = " (replaces, not compounds)" if count > 0 else ""
                print("       %s%s" % (prev, suffix))
    return 0


if __name__ == "__main__":
    sys.exit(main())
