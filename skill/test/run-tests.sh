#!/usr/bin/env bash
# Tests for maestro-remote-mac.
#
# These are the skill's behaviour tests, and they are the ones that matter. They
# run against real hierarchies captured off real devices in test/fixtures/, not
# hand-written JSON, and nothing here touches a device, a network or the real
# config — so they run just as well from ~/.claude/skills/maestro-remote-mac as
# from a checkout, which is what ../test/run-tests.sh uses them for: it installs
# the skill into a throwaway CLAUDE_DIR and runs this file out of the installed
# copy. The packaging tests live in ../test/run-tests.sh; run that one to get
# both.
#
# Fixtures, all captured 12 Aug 2026:
#   ipad-landscape-keyboard-up   iPad Pro 11-inch, iOS 16.4, landscape-locked
#                                app on a natively-portrait device, keyboard up
#   ipad-landscape-system-alert  the same, showing the notification permission
#                                dialog on first launch after a clean install
#   iphone-portrait-keyboard-up  iPhone 16 Pro, iOS 18.6, keyboard up — the
#                                case where app and device space already agree
#   quadrants-200x100.png        not a device capture: four flat quadrants,
#                                written by hand so a rotation's direction and a
#                                crop's rectangle can both be read back exactly
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="$REPO/test/fixtures"

# Scratch, and HOME redirected with it: nothing here may touch the real config
# or the real ~/.ssh.
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
# $TMPDIR with it: config.sh remembers the conf it found under $LDIR, which
# defaults to $TMPDIR (item 71), and a case that sources config.sh without
# setting LDIR would otherwise write that into the real session scratch.
export TMPDIR="$TMP/scratch"; mkdir -p "$TMPDIR"
R="python3 $REPO/bin/resolve.py"

IPAD="--width 1194 --height 834"
IPHONE="--width 402 --height 874"

pass=0; fail=0
ok(){ printf '  ok    %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL  %s\n    %s\n' "$1" "$2"; fail=$((fail+1)); }

echo "sanity"
for f in "$REPO"/bin/*.sh "$REPO"/hooks/*.sh; do
  bash -n "$f" && ok "$(basename "$f") parses" || no "$(basename "$f") parses" "syntax error"
done
python3 -c "import py_compile,sys; py_compile.compile('$REPO/bin/resolve.py', doraise=True)" \
  && ok "resolve.py compiles" || no "resolve.py compiles" "syntax error"
for f in ipad-landscape-keyboard-up ipad-landscape-system-alert iphone-portrait-keyboard-up; do
  python3 -c "import json,sys; json.load(open('$FIX/$f.json'))" >/dev/null 2>&1 \
    && ok "fixture $f is valid JSON" || no "fixture $f is valid JSON" "will not parse"
done

echo
echo "system coordinate space (landscape-locked app on a portrait device)"
# iOS draws the status bar, alerts and the keyboard in the device's native
# portrait space while the app draws in its own landscape one. Before this was
# handled, tapon on a permission dialog resolved a point in the wrong space and
# missed in silence. 664.8,474.5 is not arithmetic — it is the tap that was
# confirmed to dismiss the dialog, twice, on 12 Aug 2026.
got=$($R "^Allow$" $IPAD --point < "$FIX/ipad-landscape-system-alert.json" 2>&1)
[ "$got" = "664.8 474.5" ] \
  && ok "alert Allow resolves to the tap that works" \
  || no "alert Allow resolves to the tap that works" "got '$got', want '664.8 474.5'"

$R "^Allow$" $IPAD --explain < "$FIX/ipad-landscape-system-alert.json" 2>&1 | grep -q "system space" \
  && ok "--explain shows the system-space step" || no "--explain shows the system-space step" "no mention of it"

# The status bar is the tell, and the clock inside it is the checkable part:
# reported at 815,16 in native space, it has to land in the 24-point strip
# across the top of the app's UI once transformed.
clock=$($R "^[0-9]{1,2}:[0-9]{2} (AM|PM)$" $IPAD --point < "$FIX/ipad-landscape-system-alert.json" 2>&1)
awk -v c="$clock" 'BEGIN{split(c,p," "); exit !(p[2] > 0 && p[2] < 24)}' \
  && ok "the status bar clock lands in the app's top strip" \
  || no "the status bar clock lands in the app's top strip" "got '$clock', want y under 24"

# An upright app must be left completely alone.
got=$($R "^SCAN$" $IPHONE --point < "$FIX/iphone-portrait-keyboard-up.json" 2>&1)
[ "$got" = "201 262.6" ] \
  && ok "iPhone frames are untouched" || no "iPhone frames are untouched" "got '$got', want '201 262.6'"
$R "^SCAN$" $IPHONE --explain < "$FIX/iphone-portrait-keyboard-up.json" 2>&1 | grep -q "system space" \
  && no "iPhone gets no system transform" "one was applied" || ok "iPhone gets no system transform"

echo
echo "keyboard guard"
# Item 30: use the keyboard's POSITION when it is in the screen's space (its
# width matches the screen width) and its SIZE only when it is not (an iPad's
# native space). A keyboard parked at or below the bottom edge covers nothing
# and produces no band. band() takes the fixture, screen_w and screen_h.
band(){ python3 - "$1" "$2" "$3" <<PY
import json,sys,importlib.util
s=importlib.util.spec_from_file_location("r","$REPO/bin/resolve.py")
r=importlib.util.module_from_spec(s); s.loader.exec_module(r)
b=r.keyboard_band(json.load(open(sys.argv[1]))["axElement"], float(sys.argv[2]), float(sys.argv[3]))
print("None" if b is None else int(b))
PY
}
b=$(band "$FIX/ipad-landscape-keyboard-up.json" 1194 834)
[ "$b" = "409" ] && ok "iPad keyboard band top is 409 (native space, size path)" || no "iPad keyboard band top is 409 (native space, size path)" "got $b"
# The iPhone fixture is item 30's own case: the menu is open and the keyboard is
# parked off-screen at y=874/946 on an 874-point screen, covering nothing. The
# old size-only code produced a phantom band at 569 and refused taps on a screen
# the keyboard was not covering; the fix reads the position and produces no band.
b=$(band "$FIX/iphone-portrait-keyboard-up.json" 402 874)
[ "$b" = "None" ] && ok "iPhone: a keyboard parked off-screen produces no band (item 30)" || no "iPhone: a keyboard parked off-screen produces no band (item 30)" "got $b"
# The other direction must still hold: a keyboard genuinely up still produces a
# band and still refuses a covered element. Two synthetic fixtures, one per code
# path, each with a keyboard up and a target beneath it — the real fixtures no
# longer carry an up keyboard (the iPhone one is parked off-screen, the iPad one
# is all keys below the band). kb-pos: full-width keyboard, position path, top
# 569. kb-size: iPad native-space keyboard (width 425 ≠ screen 1194), size path,
# top 409.
printf '%s' '{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":19,"label":"SystemInputAssistantView","frame":{"X":0,"Y":569,"Width":402,"Height":48}},
 {"elementType":19,"label":"UIKeyboardLayoutStar","frame":{"X":0,"Y":617,"Width":402,"Height":257}},
 {"elementType":9,"label":"SETTINGS","frame":{"X":0,"Y":700,"Width":200,"Height":44}},
 {"elementType":9,"label":"SEARCH","frame":{"X":0,"Y":100,"Width":200,"Height":44}}]}}' > "$TMP/kb-pos.json"
printf '%s' '{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":1194,"Height":834},"children":[
 {"elementType":19,"label":"SystemInputAssistantView","frame":{"X":373,"Y":0,"Width":55,"Height":1194}},
 {"elementType":19,"label":"UIKeyboardLayoutStar","frame":{"X":3,"Y":0,"Width":370,"Height":1194}},
 {"elementType":9,"label":"SUBMIT","frame":{"X":100,"Y":500,"Width":200,"Height":44}}]}}' > "$TMP/kb-size.json"
b=$(band "$TMP/kb-pos.json" 402 874)
[ "$b" = "569" ] && ok "a keyboard genuinely up (full-width, top 569) still produces a band" || no "a keyboard genuinely up (full-width, top 569) still produces a band" "got $b"
b=$(band "$TMP/kb-size.json" 1194 834)
[ "$b" = "409" ] && ok "a keyboard in native space (size path, top 409) still produces a band" || no "a keyboard in native space (size path, top 409) still produces a band" "got $b"

# The regression: SCAN sits at the very top of the iPad screen and was being
# refused as covered, which made every keyboard screen on iPad undriveable.
$R "^SCAN$" $IPAD < "$FIX/ipad-landscape-keyboard-up.json" 2>&1 | grep -q "UNDER THE KEYBOARD" \
  && no "iPad: SCAN at the top is tappable" "still refused" || ok "iPad: SCAN at the top is tappable"
$R "^SEARCH$" $IPAD --point < "$FIX/ipad-landscape-keyboard-up.json" >/dev/null 2>&1 \
  && ok "iPad: SEARCH above the keyboard is tappable" || no "iPad: SEARCH above the keyboard is tappable" "refused"

# The other direction: the guard must still fire on something genuinely covered.
$R "^SETTINGS" $IPHONE < "$FIX/iphone-portrait-keyboard-up.json" 2>&1 | grep -q "UNDER THE KEYBOARD" \
  && no "iPhone: with the keyboard parked off-screen, the tab bar is not refused as covered (item 30)" "still refused" \
  || ok "iPhone: with the keyboard parked off-screen, the tab bar is not refused as covered (item 30)"
$R "^SEARCH$" $IPHONE < "$FIX/iphone-portrait-keyboard-up.json" 2>&1 | grep -q "UNDER THE KEYBOARD" \
  && no "iPhone: SEARCH above the keyboard is tappable" "wrongly refused" || ok "iPhone: SEARCH above the keyboard is tappable"

# A refusal nobody believes is a refusal nobody obeys. On 12 Aug one was
# overridden as a false positive and a stray character went into the field
# underneath, so the message now carries the arithmetic behind it.
# Collapsed to one line first: the message is wrapped for reading, so a phrase
# can fall across two lines and a literal match would miss it.
msg=$($R "^SETTINGS" --width 402 --height 874 --point < "$TMP/kb-pos.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$msg" in
  *"top edge is y=569"*) ok "the refusal gives the edge it measured against" ;;
  *) no "the refusal gives the edge it measured against" "said: $msg" ;;
esac
case "$msg" in
  *"UIKeyboardLayoutStar"*|*"SystemInputAssistantView"*)
    ok "the refusal names the containers the band came from" ;;
  *) no "the refusal names the containers the band came from" "no container named" ;;
esac
# On the position path the message says the top edge is the reported one because
# the keyboard spans the full screen width — so no phantom-position mistake.
case "$msg" in
  *"full screen width"*) ok "the position-path refusal says why the reported edge is trusted" ;;
  *) no "the position-path refusal says why the reported edge is trusted" "not explained" ;;
esac
# The size path still explains itself: the keyboard reports its position in the
# device's own space, so only the size was used. Measured on the native-space
# (iPad) fixture, where that path is taken.
msg_sz=$($R "^SUBMIT" --width 1194 --height 834 --point < "$TMP/kb-size.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$msg_sz" in
  *"sizes, not positions"*) ok "the size-path refusal says why only the size was used" ;;
  *) no "the size-path refusal says why only the size was used" "not explained: $msg_sz" ;;
esac
# The method this used to point at commits the wrong row — item 14 measured it.
case "$msg" in
  *"filter"*|*"press return"*|*"key return"*)
    no "the refusal does not send anyone to filter-then-return" "it still does" ;;
  *) ok "the refusal does not send anyone to filter-then-return" ;;
esac
case "$msg" in
  *"expect"*) ok "the refusal says to assert what the tap did" ;;
  *) no "the refusal says to assert what the tap did" "no assert advice" ;;
esac

# Item 53: a target in the prediction bar band is named as UNDER THE PREDICTION
# BAR, not just "the keyboard". The prediction bar sits between y=569 and y=617
# in kb-pos.json; an element at y=580 falls in that band.
printf '%s' '{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":19,"label":"SystemInputAssistantView","frame":{"X":0,"Y":569,"Width":402,"Height":48}},
 {"elementType":19,"label":"UIKeyboardLayoutStar","frame":{"X":0,"Y":617,"Width":402,"Height":257}},
 {"elementType":9,"label":"LOC1","frame":{"X":50,"Y":580,"Width":200,"Height":30}},
 {"elementType":9,"label":"SETTINGS","frame":{"X":0,"Y":700,"Width":200,"Height":44}},
 {"elementType":9,"label":"SEARCH","frame":{"X":0,"Y":100,"Width":200,"Height":44}}]}}' > "$TMP/kb-predict.json"
msg=$($R "^LOC1$" --width 402 --height 874 --point < "$TMP/kb-predict.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$msg" in
  *"PREDICTION BAR"*) ok "a target in the prediction bar band is named as such (item 53)" ;;
  *"UNDER THE KEYBOARD"*) no "a target in the prediction bar band is named as such (item 53)" "got: UNDER THE KEYBOARD" ;;
  *) no "a target in the prediction bar band is named as such (item 53)" "got: $msg" ;;
esac
# A target further down is still "UNDER THE KEYBOARD"
msg=$($R "^SETTINGS" --width 402 --height 874 --point < "$TMP/kb-predict.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$msg" in
  *"UNDER THE KEYBOARD"*) ok "a target under the keyboard proper is still named as such" ;;
  *"PREDICTION BAR"*) no "a target under the keyboard proper is still named as such" "wrongly said prediction bar" ;;
  *) no "a target under the keyboard proper is still named as such" "got: $msg" ;;
esac

# Off screen is the other refusal, and it has the same problem: "scroll it into
# view" does not say which way or how far.
msg=$($R "Typing Predictions" $IPHONE --point < "$FIX/iphone-portrait-keyboard-up.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$msg" in
  *"402x874"*"19.0 points below"*) ok "off screen says by how much, and which way" ;;
  *) no "off screen says by how much, and which way" "said: $msg" ;;
esac
case "$msg" in
  *"0,0 0x0"*) ok "off screen warns about a node off a scrolling viewport" ;;
  *) no "off screen warns about a node off a scrolling viewport" "not mentioned" ;;
esac

# find --explain is the read that precedes the tap, so it carries the same
# reasoning rather than only the one-line warning.
out=$($R "^SETTINGS" $IPHONE --explain < "$TMP/kb-pos.json" 2>&1)
case "$out" in
  *"top edge is y=569"*) ok "the listing explains the warning too, not just the refusal" ;;
  *) no "the listing explains the warning too, not just the refusal" "only the headline" ;;
esac

# --anyway is still the way past it, and must not have become harder to find.
$R "^SETTINGS" $IPHONE --point --anyway < "$TMP/kb-pos.json" >/dev/null 2>&1 \
  && ok "--anyway still overrides the refusal" || no "--anyway still overrides the refusal" "refused anyway"

echo
echo "screenshot orientation and cropping"
# A landscape-locked app on a natively-portrait iPad gets its picture back on
# its side. Which way to turn it is the same status-bar reading that separates
# system space from app space, so there is one detection, not two — and these
# are the degrees that were confirmed by rotating the simulator both ways and
# looking at the result (13 Aug 2026).
got=$($R --width 1194 --height 834 --space < "$FIX/ipad-landscape-system-alert.json" 2>&1)
[ "$got" = "landscapeLeft 270" ] \
  && ok "iPad landscapeLeft asks for 270 degrees" \
  || no "iPad landscapeLeft asks for 270 degrees" "got '$got'"

got=$($R $IPHONE --space < "$FIX/iphone-portrait-keyboard-up.json" 2>&1)
[ "$got" = "upright 0" ] \
  && ok "an upright screen asks for no rotation" || no "an upright screen asks for no rotation" "got '$got'"

# --rect is what a crop is aimed with, so it gives the frame rather than the
# centre, and unlike --point it does not refuse a node the keyboard covers:
# cropping a picture to a covered element is fine, tapping it is not.
got=$($R "^SCAN$" $IPHONE --rect < "$FIX/iphone-portrait-keyboard-up.json" 2>&1)
[ "$got" = "15 131.5 372 262.2" ] \
  && ok "--rect gives the frame, not the centre" || no "--rect gives the frame, not the centre" "got '$got'"

$R "SEARCH" $IPHONE --rect < "$FIX/iphone-portrait-keyboard-up.json" >/dev/null 2>&1
[ $? = 4 ] && ok "--rect refuses an ambiguous pattern" || no "--rect refuses an ambiguous pattern" "did not exit 4"

# bin/img.sh, offline. It picks a backend at run time and the only one that is
# guaranteed lives on the Mac, so the cases below are skipped rather than failed
# on a machine with no local image tool — a test that needs the network would be
# no test at all.
IMG="$REPO/bin/img.sh"
PNG="$FIX/quadrants-200x100.png"
got=$("$IMG" --size "$PNG" 2>&1)
[ "$got" = "200 100" ] && ok "--size reads a PNG header without decoding it" \
  || no "--size reads a PNG header without decoding it" "got '$got'"

if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || command -v sips >/dev/null 2>&1; then
  # One pixel, decoded here rather than with another tool: for a 1x1 image every
  # PNG filter reduces to the sample itself, so this is exact whatever the
  # backend chose to write.
  topleft() {
    python3 -c '
import struct, sys, zlib
d = open(sys.argv[1], "rb").read()
i, idat, plte, ct = 8, b"", b"", 0
while i < len(d):
    n = struct.unpack(">I", d[i:i+4])[0]; t = d[i+4:i+8]; b = d[i+8:i+8+n]; i += 12 + n
    if t == b"IHDR": ct = b[9]
    elif t == b"PLTE": plte = b
    elif t == b"IDAT": idat += b
s = zlib.decompress(idat)[1:]
if ct == 3: print(*plte[s[0]*3:s[0]*3+3])
elif ct in (0, 4): print(s[0], s[0], s[0])
else: print(s[0], s[1], s[2])' "$1"
  }
  # Quadrants: top-left black, top-right red, bottom-left green.
  for spec in "270 255 0 128 the right edge comes up to the top" \
              "90 0 255 128 the left edge comes up to the top"; do
    set -- $spec; deg=$1; want="$2 $3 $4"; shift 4; what="$*"
    cp "$PNG" "$TMP/r.png"
    "$IMG" "$TMP/r.png" --rotate "$deg" >/dev/null 2>&1
    dims=$("$IMG" --size "$TMP/r.png")
    "$IMG" "$TMP/r.png" --out "$TMP/px.png" --crop 0,0,1,1 >/dev/null 2>&1
    got="$(topleft "$TMP/px.png" 2>&1)"
    { [ "$dims" = "100 200" ] && [ "$got" = "$want" ]; } \
      && ok "rotate $deg: $what" \
      || no "rotate $deg: $what" "got ${dims} and pixel '$got', want '100 200' and '$want'"
  done

  cp "$PNG" "$TMP/c.png"
  "$IMG" "$TMP/c.png" --crop 10,20,50,30 >/dev/null 2>&1
  got=$("$IMG" --size "$TMP/c.png")
  [ "$got" = "50 30" ] && ok "crop cuts exactly the rectangle asked for" \
    || no "crop cuts exactly the rectangle asked for" "got '$got', want '50 30'"

  # Rotate first, then crop: the rectangle is read against the upright picture,
  # which is the only order that lets app-space points be used unchanged.
  cp "$PNG" "$TMP/rc.png"
  "$IMG" "$TMP/rc.png" --rotate 90 --crop 0,0,80,150 >/dev/null 2>&1
  got=$("$IMG" --size "$TMP/rc.png")
  [ "$got" = "80 150" ] && ok "a crop is measured against the rotated picture" \
    || no "a crop is measured against the rotated picture" "got '$got', want '80 150'"

  # ImageMagick narrows an over-wide rectangle and sips slides it — 1748x180
  # against 1750x180 when it was measured. Clamped here so the two agree.
  cp "$PNG" "$TMP/ov.png"
  "$IMG" "$TMP/ov.png" --crop 150,80,100,100 >/dev/null 2>&1
  got=$("$IMG" --size "$TMP/ov.png")
  [ "$got" = "50 20" ] && ok "a rectangle past the edge is trimmed, not slid" \
    || no "a rectangle past the edge is trimmed, not slid" "got '$got', want '50 20'"

  cp "$PNG" "$TMP/s.png"
  "$IMG" "$TMP/s.png" --scale 25 >/dev/null 2>&1
  got=$("$IMG" --size "$TMP/s.png")
  [ "$got" = "50 25" ] && ok "scale shrinks by percentage" \
    || no "scale shrinks by percentage" "got '$got', want '50 25'"

  cp "$PNG" "$TMP/n.png"
  "$IMG" "$TMP/n.png" --out "$TMP/n2.png" >/dev/null 2>&1
  cmp -s "$PNG" "$TMP/n2.png" && ok "no operations copies the file untouched" \
    || no "no operations copies the file untouched" "the bytes changed"
else
  echo "  skip  bin/img.sh pixel tests — no local image tool (the Mac backend is not used here)"
fi

"$IMG" "$PNG" --out "$TMP/z.png" --rotate 45 >/dev/null 2>&1
[ $? = 2 ] && ok "img.sh refuses a rotation that is not a quarter turn" \
  || no "img.sh refuses a rotation that is not a quarter turn" "did not exit 2"
"$IMG" "$PNG" --out "$TMP/z.png" --crop 300,0,10,10 >/dev/null 2>&1
[ $? = 2 ] && ok "img.sh refuses an origin outside the picture" \
  || no "img.sh refuses an origin outside the picture" "did not exit 2"

echo
echo "cli contract"
$R "^definitely not on this screen$" $IPAD < "$FIX/ipad-landscape-keyboard-up.json" >/dev/null 2>&1
rc=$?; [ "$rc" = 3 ] && ok "no match exits 3" || no "no match exits 3" "exit was $rc"
# SEARCH is both a button and a tab on the iPhone search screen.
$R "SEARCH" $IPHONE --point < "$FIX/iphone-portrait-keyboard-up.json" >/dev/null 2>&1
rc=$?; [ "$rc" = 4 ] && ok "an ambiguous pattern exits 4 rather than guessing" || no "an ambiguous pattern exits 4 rather than guessing" "exit was $rc"
$R "^SETTINGS" $IPHONE --point < "$TMP/kb-pos.json" >/dev/null 2>&1
rc=$?; [ "$rc" = 5 ] && ok "an untappable match exits 5" || no "an untappable match exits 5" "exit was $rc"
$R "^SETTINGS" $IPHONE --point --anyway < "$TMP/kb-pos.json" >/dev/null 2>&1 \
  && ok "--anyway overrides it" || no "--anyway overrides it" "still refused"

echo
echo "truncated labels are marked (item 33)"
# tree.py truncates at 60 chars, resolve.py at 50. Both must show … when cut.
long='{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":9,"label":"ABCDEFGHIJ ABCDEFGHIJ ABCDEFGHIJ ABCDEFGHIJ ABCDEFGHIJ ABCDEFGHIJ EXTRA","frame":{"X":10,"Y":10,"Width":100,"Height":44}}]}}'
treeout=$(printf '%s' "$long" | python3 "$REPO/bin/tree.py" 2>&1)
case "$treeout" in
  *"…"*) ok "tree.py appends … when a label is cut" ;;
  *) no "tree.py appends … when a label is cut" "no ellipsis in: $treeout" ;;
esac
resolveout=$(printf '%s' "$long" | $R "ABCDEFGHIJ" --width 402 --height 874 2>&1)
case "$resolveout" in
  *"…"*) ok "resolve.py appends … when a label is cut" ;;
  *) no "resolve.py appends … when a label is cut" "no ellipsis in: $resolveout" ;;
esac

echo
echo "journey lines: split first, then expand"
# The order is the defect from BACKLOG.md item 14. Expanding the file and then
# splitting it turned USER="Test User" into two arguments and dropped the
# second, so `text ${USER}` typed "Test" — which still filtered the list and
# still matched something, and set a device to the wrong user for a session.
J="python3 $REPO/bin/jtok.py"
toks() { printf '%s' "$1" | $J | tr '\0' '|'; }   # NULs are hard to eyeball

got=$(U="Test User" toks 'text ${U}')
[ "$got" = "text|Test User" ] \
  && ok "a value with a space stays one argument" \
  || no "a value with a space stays one argument" "got '$got', want 'text|Test User'"

got=$(P="Camden Road" toks 'tapon "^${P} Store$"')
[ "$got" = "tapon|^Camden Road Store$" ] \
  && ok "a variable inside a quoted pattern does not break it" \
  || no "a variable inside a quoted pattern does not break it" "got '$got'"

# Unset stays as written. Becoming an empty string would type nothing and carry
# on, which is the same silent-success failure in a different disguise.
got=$(toks 'text ${NOT_SET_ANYWHERE}')
[ "$got" = 'text|${NOT_SET_ANYWHERE}' ] \
  && ok "an unset variable is left alone rather than emptied" \
  || no "an unset variable is left alone rather than emptied" "got '$got'"

got=$(N="two # three" toks 'log ${N}')
[ "$got" = "log|two # three" ] \
  && ok "a # inside a value is not treated as a comment" \
  || no "a # inside a value is not treated as a comment" "got '$got'"

got=$(toks 'type "^Field$" "a b c"')
[ "$got" = 'type|^Field$|a b c' ] \
  && ok "quoting still works as it always did" || no "quoting still works as it always did" "got '$got'"

printf '%s' 'text "unbalanced' | $J >/dev/null 2>&1
[ $? = 2 ] && ok "an unparseable line fails rather than guessing" \
  || no "an unparseable line fails rather than guessing" "did not exit 2"

# The PIN is the reason this matters beyond argument counts: the journey runner
# echoes each line as written, and it used to echo the expanded one.
got=$(APP_PIN=9999 toks 'type "^Passcode$" ${APP_PIN}')
case "$got" in *9999*) ok "the value still reaches the verb" ;;
  *) no "the value still reaches the verb" "got '$got'" ;; esac

echo
echo "app notes carry how well they are known"
# Five notes have turned out to be wrong and every one was written from a single
# sighting stated as fact, two of them inside this skill's own example notes.
# The marker is required so that nobody can decline to answer the question.
NOTES="$TMP/proj/maestro/app-notes.md"
mkdir -p "$TMP/proj"
cat > "$TMP/proj/.maestro-mac.conf" <<'CONF'
: "${MAC_HOST:=nowhere}"
: "${MAC_FQDN:=nowhere.invalid}"
: "${APP_ID:=com.example.notes}"
: "${APP_SECRET:=hunter2}"
CONF
N() { (cd "$TMP/proj" && MAESTRO_MAC_CONF="$TMP/proj/.maestro-mac.conf" "$REPO/bin/notes.sh" "$@"); }

N init >/dev/null 2>&1
[ -s "$NOTES" ] && ok "notes.sh init writes the file from the template" \
  || no "notes.sh init writes the file from the template" "nothing was created"

N add "screen quirks" "the tab bar is 80 points tall" --measured >/dev/null 2>&1
grep -q ", measured) the tab bar is 80 points tall" "$NOTES" \
  && ok "a measured note is stamped measured" \
  || no "a measured note is stamped measured" "$(grep -n 'tab bar' "$NOTES" 2>&1 | head -1)"

N add "screen quirks" "the dropdown seems not to raise the keyboard" --once >/dev/null 2>&1
grep -q ", seen once) the dropdown seems not to raise" "$NOTES" \
  && ok "--once is recorded as seen once" || no "--once is recorded as seen once" "not stamped"

N add "screen quirks" "filtering is on, from the widget source" --inferred >/dev/null 2>&1
grep -q ", inferred) filtering is on" "$NOTES" \
  && ok "--inferred is recorded" || no "--inferred is recorded" "not stamped"

# The whole mechanism rests on this: a default would make every note claim the
# same confidence, which is the state being fixed.
out=$(N add "screen quirks" "no marker given" 2>&1); rc=$?
[ "$rc" = 2 ] && ok "a note with no confidence is refused" \
  || no "a note with no confidence is refused" "exited $rc"
case "$out" in *--measured*--once*) ok "the refusal names the choices" ;;
  *) no "the refusal names the choices" "got '$out'" ;; esac
grep -q "no marker given" "$NOTES" \
  && no "nothing is written when it is refused" "the text was appended anyway" \
  || ok "nothing is written when it is refused"

out=$(N add "screen quirks" "made up" --probably 2>&1); rc=$?
[ "$rc" = 2 ] && ok "an unknown confidence is refused" || no "an unknown confidence is refused" "exited $rc"

# The credential guard predates this and must still hold with the new argument
# in place — a marker is no reason to start writing secrets into a committed file.
out=$(N add "known test data" "the PIN is hunter2" --measured 2>&1); rc=$?
[ "$rc" = 3 ] && ok "a note quoting a conf value is still refused" \
  || no "a note quoting a conf value is still refused" "exited $rc"
grep -q "hunter2" "$NOTES" \
  && no "the credential never reaches the file" "it was written" \
  || ok "the credential never reaches the file"

# A new section that nearly duplicates an existing heading warns and names the
# closest one, at the moment of writing (item 52). "screen qwirks" does not
# substring-match "Screen quirks", so it would silently start a rival section.
out=$(N add "screen qwirks" "a typo'd heading" --measured 2>&1)
case "$out" in
  *"NEW section 'screen qwirks'"*"Screen quirks"*) ok "a near-miss new section warns and names the closest heading (item 52)" ;;
  *) no "a near-miss new section warns and names the closest heading (item 52)" "got: $out" ;;
esac
# A genuinely new, unrelated section is not warned about, or the warning is noise.
out=$(N add "teleporter latency" "warp factor 9" --measured 2>&1)
case "$out" in
  *"closest existing"*) no "a genuinely new section is not warned about" "cried wolf: $out" ;;
  *) ok "a genuinely new section is not warned about" ;;
esac

echo
echo "contradiction checker (item 19)"
# A synthetic notes file with a known contradiction: two notes under the same
# heading, about the same named control, one affirming and one negating.
cat > "$TMP/contra-notes.md" <<'NOTES'
## Screen quirks

- (2026-08-12, measured) Select Store filters the list when you type.
- (2026-08-12, measured) Select Store does not filter — typing leaves the list unchanged.
NOTES
out=$(python3 "$REPO/bin/notes_check.py" < "$TMP/contra-notes.md" 2>&1); rc=$?
[ "$rc" = 1 ] && case "$out" in *CONTRADICTION*"Select Store"*"filter"*) true ;; *) false ;; esac \
  && ok "two notes about the same control with opposite verbs are caught" \
  || no "two notes about the same control with opposite verbs are caught" "rc=$rc: $out"

# A superseded note (strikethrough) is skipped — no false positive.
cat > "$TMP/contra-super.md" <<'NOTES'
## Screen quirks

- (2026-08-12, measured) ~~Select Store filters the list.~~ **WRONG — see below.**
- (2026-08-12, measured) Select Store does not filter.
NOTES
out=$(python3 "$REPO/bin/notes_check.py" < "$TMP/contra-super.md" 2>&1); rc=$?
[ "$rc" = 0 ] && ok "a superseded (strikethrough/wrong) note is skipped" \
  || no "a superseded (strikethrough/wrong) note is skipped" "rc=$rc: $out"

# Notes about different controls are not compared even if verbs clash.
cat > "$TMP/contra-diff.md" <<'NOTES'
## Screen quirks

- (2026-08-12, measured) The keyboard works fine here.
- (2026-08-12, measured) The tab bar does not work on iPad.
NOTES
out=$(python3 "$REPO/bin/notes_check.py" < "$TMP/contra-diff.md" 2>&1); rc=$?
[ "$rc" = 0 ] && ok "notes about different subjects are not flagged" \
  || no "notes about different subjects are not flagged" "rc=$rc: $out"

# CONTESTED notes are reported as contested, not as contradictions.
cat > "$TMP/contra-contested.md" <<'NOTES'
## Does this app report bounds correctly?

- (2026-08-12) **CONTESTED** iPad Pro controls need the transform — worked on 12 Aug.
- (2026-08-21) **CONTESTED** iPad Pro controls did nothing with the transform.
NOTES
out=$(python3 "$REPO/bin/notes_check.py" < "$TMP/contra-contested.md" 2>&1); rc=$?
case "$out" in
  *"0 contradiction"*"1 contested"*) ok "CONTESTED notes are reported as contested, not contradictions" ;;
  *) no "CONTESTED notes are reported as contested, not contradictions" "got: $out" ;;
esac

echo
echo "docs mirror: surfaces its known-wrong claims (item 55)"
# The mirror flatly denies physical-iOS support the skill has; a claim believed
# twice. docs-check.sh carries a maintained known-wrong list, gated on the pinned
# version so a refresh to a new mirror drops corrections that may not apply.
mkdir -p "$TMP/dckit/bin" "$TMP/dckit/docs"
cp "$REPO/bin/docs-check.sh" "$TMP/dckit/bin/"
printf '_ssh(){ echo 2.8.0; }\nMAC_HOST=x; MAC_FQDN=x; APP_ID=x; SSH_OPTS=(-o X=y)\n' > "$TMP/dckit/bin/lib.sh"

printf 'MAESTRO_VERSION=2.8.0\nMIRRORED=2026-08-11\nPAGES=154\n' > "$TMP/dckit/docs/VERSION"
out=$(bash "$TMP/dckit/bin/docs-check.sh" --quiet 2>&1)
case "$out" in
  *"KNOWN-WRONG"*"physical iOS"*"device.sh"*) ok "the pinned mirror's physical-iOS denial is surfaced as known-wrong" ;;
  *) no "the pinned mirror's physical-iOS denial is surfaced as known-wrong" "got: $out" ;;
esac

printf 'MAESTRO_VERSION=9.9.9\nMIRRORED=2027-01-01\nPAGES=154\n' > "$TMP/dckit/docs/VERSION"
out=$(bash "$TMP/dckit/bin/docs-check.sh" --quiet 2>&1)
case "$out" in
  *"KNOWN-WRONG"*) no "the known-wrong list is gated on the pinned version" "printed for the wrong version" ;;
  *) ok "the known-wrong list is gated on the pinned version" ;;
esac

echo
echo "reading typed text back"
# `type` is a tap plus keystrokes and both halves fail quietly. The check is
# scoped to the FOCUSED field (item 31): the whole-tree substring search it
# replaced passed on an appended value and on a menu row carrying the same text.
T="python3 $REPO/bin/typed.py"

cat > "$TMP/typed-ok.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":49,"hasFocus":true,"value":"LOC1"}]}}
JSON
$T "LOC1" < "$TMP/typed-ok.json" >/dev/null 2>&1
[ $? = 0 ] && ok "text that landed in the focused field passes" || no "text that landed in the focused field passes" "did not exit 0"

# A missed tap types into whatever had focus, so the focused field holds the
# wrong thing — which is exactly what this now catches.
cat > "$TMP/typed-missed.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":49,"hasFocus":true,"value":"Store name"}]}}
JSON
$T "LOC1" < "$TMP/typed-missed.json" >/dev/null 2>&1
[ $? = 1 ] && ok "text that did not land in the focused field fails" || no "text that did not land in the focused field fails" "did not exit 1"

# Truncation (item 14): "Test" arrived, "Test User" was asked for.
cat > "$TMP/typed-short.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":49,"hasFocus":true,"value":"Test"}]}}
JSON
$T "Test User" < "$TMP/typed-short.json" >/dev/null 2>&1
[ $? = 1 ] && ok "a value that arrived shortened is caught" || no "a value that arrived shortened is caught" "did not exit 1"

# Item 31, hole 1: typing into a field that already held a value appends to it.
# The old substring check passed on this because "4001LOC1" contains "LOC1".
cat > "$TMP/typed-append.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":49,"hasFocus":true,"value":"4001LOC1"}]}}
JSON
$T "LOC1" < "$TMP/typed-append.json" >/dev/null 2>&1
[ $? = 1 ] && ok "an appended value is caught, not passed on the substring (item 31)" || no "an appended value is caught, not passed on the substring (item 31)" "did not exit 1"

# Item 31, hole 2: a menu row carries the same text as the value but the focused
# field did not receive it. The row must not make the check pass.
cat > "$TMP/typed-row.json" <<'JSON'
{"axElement":{"elementType":2,"children":[
  {"elementType":49,"hasFocus":true,"value":""},
  {"elementType":48,"label":"LOC1"}]}}
JSON
$T "LOC1" < "$TMP/typed-row.json" >/dev/null 2>&1
[ $? = 1 ] && ok "a menu row with the same text does not pass the check (item 31)" || no "a menu row with the same text does not pass the check (item 31)" "did not exit 1"

# A secure field never shows what it holds; passing beats failing a PIN step.
cat > "$TMP/typed-secure.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":50,"hasFocus":true,"placeholderValue":"Enter The PIN","value":"••••"}]}}
JSON
$T "1234" < "$TMP/typed-secure.json" >/dev/null 2>&1
[ $? = 0 ] && ok "a focused secure field suspends the check" || no "a focused secure field suspends the check" "it cried wolf"

# Nothing focused: no field to read, so it says so and passes rather than a
# tree-wide search that is not really a check.
cat > "$TMP/typed-nofocus.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":48,"label":"anything"}]}}
JSON
$T "LOC1" < "$TMP/typed-nofocus.json" >/dev/null 2>&1
[ $? = 0 ] && ok "no focused field means no check, and it passes" || no "no focused field means no check, and it passes" "did not exit 0"

# Values wrap mid-string, which is why whitespace is collapsed; this has to agree
# with the resolver about the same screen.
cat > "$TMP/typed-wrapped.json" <<'JSON'
{"axElement":{"elementType":2,"children":[{"elementType":49,"hasFocus":true,"value":"Test\n  User"}]}}
JSON
$T "Test User" < "$TMP/typed-wrapped.json" >/dev/null 2>&1
[ $? = 0 ] && ok "a value wrapped mid-string still matches" || no "a value wrapped mid-string still matches" "whitespace was not collapsed"

echo "not json" | $T "anything" >/dev/null 2>&1
[ $? = 2 ] && ok "bad input exits 2, not 1" || no "bad input exits 2, not 1" "wrong exit"

echo
echo "is the installed app the code under test"
# remote/appcheck.sh runs on the Mac but is a file so that it can be run here.
# The fixtures are a fake .app with an XML Info.plist and a throwaway git repo,
# with both timestamps set by hand — the whole point of the check is the
# comparison between them, so it has to be tested at both signs.
. "$REPO/remote/appcheck.sh"

APP="$TMP/Fake.app"; mkdir -p "$APP"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Fake</string>
<key>CFBundleShortVersionString</key><string>1.0.0-dev</string>
<key>CFBundleVersion</key><string>26</string>
</dict></plist>
PLIST
echo 'a binary, with a marker: PROJ-1783-widget-key' > "$APP/Fake"

GIT="$TMP/checkout"; mkdir -p "$GIT"
(cd "$GIT" && git init -q . \
  && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m first \
     --date="2026-08-10T14:21:00" 2>/dev/null) >/dev/null 2>&1
git -C "$GIT" log -1 --format=%ct >/dev/null 2>&1 || echo "  note: no usable git, the two comparison cases will be skipped"
HEAD_AT=$(git -C "$GIT" log -1 --format=%ct 2>/dev/null)

got=$(appcheck "" "$GIT" 2>&1)
case "$got" in *"not installed"*) ok "an app that is not installed says so" ;;
  *) no "an app that is not installed says so" "got '$got'" ;; esac

got=$(appcheck "$APP" "" 2>&1)
case "$got" in *"no checkout on the Mac"*) ok "no REPO says what is missing, not nothing" ;;
  *) no "no REPO says what is missing, not nothing" "got '$got'" ;; esac

case "$(appcheck "$APP" "" 2>&1)" in
  *"1.0.0-dev build 26"*) ok "the installed version and build number are read from the bundle" ;;
  *) no "the installed version and build number are read from the bundle" "not in the output" ;;
esac

if [ -n "$HEAD_AT" ]; then
  # A build from before the newest commit cannot contain it. This is the case
  # that bit sessions A and B, both of which found the simulator running a
  # build from another branch.
  touch -d "@$((HEAD_AT - 172800))" "$APP/Fake" 2>/dev/null
  got=$(appcheck "$APP" "$GIT" 2>&1)
  case "$got" in *STALE*"2 days"*) ok "a build older than HEAD is called stale, with the gap" ;;
    *) no "a build older than HEAD is called stale, with the gap" "got '$got'" ;; esac

  # And the reverse must not overclaim: newer than HEAD is not proof of which
  # branch it came from, because a checkout can move after a build.
  touch -d "@$((HEAD_AT + 3600))" "$APP/Fake" 2>/dev/null
  got=$(appcheck "$APP" "$GIT" 2>&1)
  case "$got" in
    *STALE*) no "a build newer than HEAD is not called stale" "it was" ;;
    *"does not prove"*) ok "a newer build is reported without claiming the branch" ;;
    *) no "a newer build is reported without claiming the branch" "got '$got'" ;;
  esac
fi

got=$(appcheck "$APP" "" "PROJ-1783-widget-key" 2>&1)
case "$got" in *"marker: found"*) ok "a marker that is in the bundle is found" ;;
  *) no "a marker that is in the bundle is found" "got '$got'" ;; esac

got=$(appcheck "$APP" "" "not-in-this-build" 2>&1)
case "$got" in *"MARKER MISSING"*) ok "a marker that is absent is called out" ;;
  *) no "a marker that is absent is called out" "got '$got'" ;; esac

echo
echo "wall.sh label refuses a flag rather than wearing it (item 89)"
# Every one of these must exit before anything reaches a device: with no udid a
# label goes to whatever _dev resolves to, which on a shared Mac is a peer's
# simulator. That is how `label --help` overwrote one.
LW() { MAC_HOST=x MAC_FQDN=x APP_ID=x MAESTRO_MAC_CONF=/dev/null "$REPO/bin/wall.sh" "$@" 2>&1; }

lw_out=$(LW label --help); lw_rc=$?
[ "$lw_rc" = 0 ] && printf '%s' "$lw_out" | grep -q "^usage: " \
  && ok "label --help prints the usage and exits 0" \
  || no "label --help prints the usage and exits 0" "rc=$lw_rc: $lw_out"

printf '%s' "$lw_out" | grep -qi "ssh\|Host key\|Connection" \
  && no "label --help never reaches a device" "it tried to connect" \
  || ok "label --help never reaches a device"

lw_out=$(LW label -h); lw_rc=$?
[ "$lw_rc" = 0 ] \
  && ok "label -h is the same as --help" \
  || no "label -h is the same as --help" "rc=$lw_rc"

lw_out=$(LW label --groupp brandco); lw_rc=$?
[ "$lw_rc" = 2 ] && printf '%s' "$lw_out" | grep -q "unknown option --groupp" \
  && ok "label refuses an unknown flag instead of labelling with it" \
  || no "label refuses an unknown flag instead of labelling with it" "rc=$lw_rc: $lw_out"

lw_out=$(LW label somename --group); lw_rc=$?
[ "$lw_rc" = 2 ] && printf '%s' "$lw_out" | grep -q -- "--group needs a value" \
  && ok "label refuses --group with nothing after it" \
  || no "label refuses --group with nothing after it" "rc=$lw_rc: $lw_out"

# A label that really does start with a dash is still writable, after --.
lw_out=$(LW label -- --odd-name); lw_rc=$?
printf '%s' "$lw_out" | grep -q "unknown option" \
  && no "label takes a dashed name after --" "it still refused it" \
  || ok "label takes a dashed name after --"

lw_out=$(LW label); lw_rc=$?
[ "$lw_rc" = 2 ] && printf '%s' "$lw_out" | grep -q "^usage: " \
  && ok "label with no name prints the usage" \
  || no "label with no name prints the usage" "rc=$lw_rc: $lw_out"

echo "ssh host fallback"
# No Mac needed: a stub ssh on PATH answers for one alias and hangs up on the
# rest, which is exactly what a Mac on the other network looks like.
STUB="$TMP/stub"; mkdir -p "$STUB"
cat > "$STUB/ssh" <<'STUBSH'
#!/usr/bin/env bash
# The host is the first bare word that is not an option or an option's value.
skip=0
for a in "$@"; do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  case "$a" in
    -o|-i|-p|-F|-l) skip=1 ;;
    -*) ;;
    *) host=$a; break ;;
  esac
done
[ "$host" = "$WORKS" ] && exit 0
exit 255                       # ssh's own "could not connect"
STUBSH
chmod +x "$STUB/ssh"

# Each call gets its own cache dir unless one is named, so ordering between
# cases cannot leak a previous answer — which it did the first time round.
pick(){ # pick <MAC_HOST value> <alias that works> [cache dir]
  PATH="$STUB:$PATH" WORKS="$2" MAC_HOST="$1" LDIR="${3:-$(mktemp -d)}" bash -c '
    mkdir -p "$LDIR"
    MAC_FQDN=x APP_ID=x MAESTRO_MAC_CONF=/dev/null
    . '"$REPO"'/bin/lib.sh 2>/dev/null
    _pick_host >/dev/null 2>&1
    printf "%s" "$MAC_HOST"'
}

got=$(pick "mac-a mac-b" mac-b)
[ "$got" = "mac-b" ] && ok "falls through to the alias that answers" \
  || no "falls through to the alias that answers" "chose '$got'"

got=$(pick "mac-a mac-b" mac-a)
[ "$got" = "mac-a" ] && ok "takes the first alias when it answers" \
  || no "takes the first alias when it answers" "chose '$got'"

# A single alias must not be probed at all — that is the existing behaviour and
# the cost of the whole feature has to stay zero for anyone not using it.
got=$(PATH="$STUB:$PATH" WORKS=nothing MAC_HOST="mac-b" LDIR="$TMP/hc2" bash -c '
  mkdir -p "$LDIR"; MAC_FQDN=x APP_ID=x MAESTRO_MAC_CONF=/dev/null
  . '"$REPO"'/bin/lib.sh 2>/dev/null; _pick_host >/dev/null 2>&1; printf "%s" "$MAC_HOST"')
[ "$got" = "mac-b" ] && ok "a single alias is used without probing" \
  || no "a single alias is used without probing" "got '$got'"

mkdir -p "$TMP/hostcache"
pick "mac-a mac-b" mac-b "$TMP/hostcache" >/dev/null
[ "$(cat "$TMP/hostcache/mac-host" 2>/dev/null)" = "mac-b" ] \
  && ok "the choice is cached" || no "the choice is cached" "cache holds '$(cat "$TMP/hostcache/mac-host" 2>/dev/null)'"

# A cache naming an alias that is no longer configured must be ignored, not used.
printf 'mac-somewhere-else' > "$TMP/hostcache/mac-host"
got=$(pick "mac-a mac-b" mac-a "$TMP/hostcache")
[ "$got" = "mac-a" ] && ok "a cache outside the list is ignored" \
  || no "a cache outside the list is ignored" "chose '$got'"

mkdir -p "$TMP/hc4"; printf 'mac-b' > "$TMP/hc4/mac-host"
got=$(pick "mac-a mac-b" mac-a "$TMP/hc4")
[ "$got" = "mac-b" ] && ok "a cached choice is used ahead of the list order" \
  || no "a cached choice is used ahead of the list order" "chose '$got'"

# A host that is up but slow must be found by the second, longer pass rather
# than reported as unreachable — the same class of wrong answer as the bug this
# fixes. The stub sleeps past the fast probe and answers inside the slow one.
cat > "$STUB/ssh-slow" <<'STUBSH'
#!/usr/bin/env bash
skip=0
for a in "$@"; do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  case "$a" in -o|-i|-p|-F|-l) skip=1 ;; -*) ;; *) host=$a; break ;; esac
done
[ "$host" = "$WORKS" ] || exit 255
sleep "${SLOW_BY:-3}"; exit 0
STUBSH
chmod +x "$STUB/ssh-slow"
mkdir -p "$TMP/slow"; cp "$STUB/ssh-slow" "$TMP/slow/ssh"
got=$(PATH="$TMP/slow:$PATH" WORKS=mac-b SLOW_BY=3 PROBE_FAST=1 PROBE_SLOW=6 \
  MAC_HOST="mac-a mac-b" LDIR="$TMP/hc5" bash -c '
  mkdir -p "$LDIR"; MAC_FQDN=x APP_ID=x MAESTRO_MAC_CONF=/dev/null
  . '"$REPO"'/bin/lib.sh 2>/dev/null; _pick_host 2>/dev/null >/dev/null; printf "%s" "$MAC_HOST"')
[ "$got" = "mac-b" ] && ok "a slow but working alias is found on the second pass" \
  || no "a slow but working alias is found on the second pass" "chose '$got'"

# The Mac moving mid-session: the cached alias stops answering, ssh returns its
# own 255, and _ssh must re-pick rather than report an absence.
mkdir -p "$TMP/hc6"; printf 'mac-b' > "$TMP/hc6/mac-host"
out=$(PATH="$STUB:$PATH" WORKS=mac-a MAC_HOST="mac-a mac-b" LDIR="$TMP/hc6" bash -c '
  MAC_FQDN=x APP_ID=x MAESTRO_MAC_CONF=/dev/null
  . '"$REPO"'/bin/lib.sh 2>/dev/null
  _ssh "true" >/dev/null 2>&1 && printf "rc0 %s" "$MAC_HOST" || printf "rc%s %s" "$?" "$MAC_HOST"' 2>/dev/null)
case "$out" in
  "rc0 mac-a") ok "a cached alias that stops answering is re-picked mid-session" ;;
  *) no "a cached alias that stops answering is re-picked mid-session" "got '$out'" ;;
esac

out=$(PATH="$STUB:$PATH" WORKS=nothing MAC_HOST="mac-a mac-b" LDIR="$TMP/hc3" bash -c '
  mkdir -p "$LDIR"; MAC_FQDN=x APP_ID=x MAESTRO_MAC_CONF=/dev/null
  . '"$REPO"'/bin/lib.sh 2>/dev/null; _pick_host 2>&1 >/dev/null')
case "$out" in
  *"mac-a"*"mac-b"*) ok "when none answer, the error names what was tried" ;;
  *) no "when none answer, the error names what was tried" "said: $out" ;;
esac


echo
echo "an action and the read after it are one round trip"
# driver.sh has never been testable offline: it binds to a driver on the Mac at
# load. A stub curl and a stub lib.sh give it a whole fake device, which is what
# lets the --tree flag and the settle-after-acting rule be checked at all.
DBIN="$TMP/dbin"; mkdir -p "$DBIN"
cp "$REPO/bin/driver.sh" "$REPO/bin/tree.py" "$REPO/bin/resolve.py" "$REPO/bin/typed.py" \
   "$REPO/bin/jtok.py" "$DBIN/"
cat > "$DBIN/lib.sh" <<'LIBSH'
MAC_FQDN=stub.invalid; APP_ID=test.app; DEV=stub; DPORT=1; DRIVER_PORT=1
DRIVER_PORT_BASE=1; RDIR=/tmp/none; JOURNEY_DIR=/tmp/none; SSH_OPTS=(-o X=y)
_driver_bind(){ return 0; }
_ssh(){ return 0; }
LIBSH
cat > "$TMP/stub/curl" <<'CURLSH'
#!/usr/bin/env bash
# A device that is always up, always still, and always shows one fixture.
prev=; for a in "$@"; do
  case "$a" in http*) url=$a ;; esac
  [ "$prev" = -d ] && body=$a; prev=$a
done
echo "$url ${body:-}" >> "$CURL_LOG"
case "$url" in
  */status)          printf '200' ;;
  */isScreenStatic)  printf '{"isScreenStatic":true}' ;;
  */deviceInfo)      printf '{"widthPoints":402,"heightPoints":874}' ;;
  */viewHierarchy)   cat "$FIXTURE" ;;
  */keyboard)
    # The keyboard is up until the route named in KB_UNTIL has been called, so
    # a test can say "this is the thing that puts it away" rather than counting
    # polls. KB_UNTIL=never keeps it up whatever happens; unset means down.
    v=false
    if [ -n "${KB_UNTIL:-}" ]; then
      v=true
      [ "$KB_UNTIL" != never ] && [ -n "$CURL_LOG" ] &&
        grep -q "/$KB_UNTIL" "$CURL_LOG" && v=false
    fi
    printf '{"isKeyboardVisible":%s}' "$v" ;;
  *)                 printf '{}' ;;
esac
CURLSH
chmod +x "$TMP/stub/curl"
drv(){ PATH="$TMP/stub:$PATH" CURL_LOG="$TMP/curl.log" \
       FIXTURE="$FIX/iphone-portrait-keyboard-up.json" bash "$DBIN/driver.sh" "$@" 2>&1; }

: > "$TMP/curl.log"
out=$(drv tap 10 20)
grep -q '/isScreenStatic' "$TMP/curl.log" \
  && ok "the CLI tap waits for the screen, as the journey verb always has" \
  || no "the CLI tap waits for the screen, as the journey verb always has" "never called isScreenStatic"

: > "$TMP/curl.log"
out=$(SETTLE=0 drv tap 10 20)
grep -q '/isScreenStatic' "$TMP/curl.log" \
  && no "SETTLE=0 turns the wait off rather than failing" "still polled" \
  || ok "SETTLE=0 turns the wait off rather than failing"

: > "$TMP/curl.log"
out=$(drv tapon --tree '^SCAN$')
case "$out" in
  *textfield*|*searchfld*) ok "--tree prints the screen in the same call as the action" ;;
  *) no "--tree prints the screen in the same call as the action" "got: $(printf '%s' "$out" | head -2)" ;;
esac

# tree hides the unlabelled containers, nodes keeps them, and that is the whole
# difference between the two flags.
a=$(drv tap --tree 1 2 | wc -l); b=$(drv tap --nodes 1 2 | wc -l)
[ "$b" -gt "$a" ] && ok "--nodes shows more than --tree, as the commands do" \
  || no "--nodes shows more than --tree, as the commands do" "tree $a lines, nodes $b"

# `type` takes the rest of the line, so a flag on the end would be typed. It is
# only ever read directly after the verb.
: > "$TMP/curl.log"
out=$(drv type '^SCAN$' hello --tree)
if grep -q 'inputText.*hello --tree' "$TMP/curl.log"; then
  ok "a --tree after the text is typed, not obeyed"
else
  no "a --tree after the text is typed, not obeyed" "sent: $(grep inputText "$TMP/curl.log")"
fi
: > "$TMP/curl.log"
out=$(drv type --tree '^SCAN$' hello)
if grep -q 'inputText.*"hello"' "$TMP/curl.log"; then
  ok "a --tree before the pattern is obeyed, not typed"
else
  no "a --tree before the pattern is obeyed, not typed" "sent: $(grep inputText "$TMP/curl.log")"
fi

out=$(drv tree extra 2>&1); rc=$?
[ "$rc" = 0 ] && ok "the tree command itself still works after the split into tree.py" \
  || no "the tree command itself still works after the split into tree.py" "rc=$rc: $out"

# The read is worth most when the action failed — that is when you go and look.
: > "$TMP/curl.log"
out=$(drv tapon --tree '^NoSuchElement$'); rc=$?
[ "$rc" != 0 ] && case "$out" in
  *textfield*|*searchfld*) ok "a failed action still prints the screen, and still fails" ;;
  *) no "a failed action still prints the screen, and still fails" "no tree in the output" ;;
esac || no "a failed action still prints the screen, and still fails" "rc=$rc"

echo
echo "erase --all and clear (item 60)"
# erase --all sends eraseText with 9999 instead of the default 50
: > "$TMP/curl.log"
out=$(drv erase --all 2>&1)
if grep -q 'eraseText.*9999' "$TMP/curl.log"; then
  ok "erase --all sends 9999 characters, not the default 50"
else
  no "erase --all sends 9999 characters, not the default 50" "sent: $(grep eraseText "$TMP/curl.log")"
fi

# plain erase still sends the default 50
: > "$TMP/curl.log"
out=$(drv erase 2>&1)
if grep -q 'eraseText.*50' "$TMP/curl.log"; then
  ok "plain erase still sends 50"
else
  no "plain erase still sends 50" "sent: $(grep eraseText "$TMP/curl.log")"
fi

# erase with a count still sends that count
: > "$TMP/curl.log"
out=$(drv erase 12 2>&1)
if grep -q 'eraseText.*12' "$TMP/curl.log"; then
  ok "erase <n> still sends the specified count"
else
  no "erase <n> still sends the specified count" "sent: $(grep eraseText "$TMP/curl.log")"
fi

# clear resolves the pattern, long-presses it, then looks for "Select All"
: > "$TMP/curl.log"
out=$(drv clear '^SCAN$' 2>&1)
if grep -q 'touch.*duration.*1' "$TMP/curl.log"; then
  ok "clear long-presses the resolved element"
else
  no "clear long-presses the resolved element" "sent: $(cat "$TMP/curl.log")"
fi

# clear on a pattern that does not resolve fails cleanly
: > "$TMP/curl.log"
out=$(drv clear '^NoSuchElement$' 2>&1); rc=$?
[ "$rc" != 0 ] && ok "clear on a non-existent element exits non-zero" \
  || no "clear on a non-existent element exits non-zero" "rc=$rc"

# journey: erase --all in a journey sends 9999
jf="$TMP/erase-all.journey"
printf 'erase --all\n' > "$jf"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1)
if grep -q 'eraseText.*9999' "$TMP/curl.log"; then
  ok "journey: erase --all sends 9999"
else
  no "journey: erase --all sends 9999" "sent: $(grep eraseText "$TMP/curl.log")"
fi

# journey: clear verb resolves, long-presses
jf="$TMP/clear.journey"
printf 'clear "^SCAN$"\n' > "$jf"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1)
if grep -q 'touch.*duration.*1' "$TMP/curl.log"; then
  ok "journey: clear long-presses the resolved element"
else
  no "journey: clear long-presses the resolved element" "sent: $(cat "$TMP/curl.log")"
fi

echo
echo "journey features from Maestro flows (item 44)"
# tapon? skips silently when the pattern is not on screen
jf="$TMP/tapon-opt.journey"
printf 'tapon? "^NoSuchElement$"\ntapon "^SCAN$"\n' > "$jf"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1); rc=$?
if [ "$rc" = 0 ] && grep -q '/touch' "$TMP/curl.log"; then
  ok "tapon? skips a missing element and the journey continues"
else
  no "tapon? skips a missing element and the journey continues" "rc=$rc"
fi

# tapon? taps when the pattern IS on screen
jf="$TMP/tapon-opt-hit.journey"
printf 'tapon? "^SCAN$"\n' > "$jf"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1); rc=$?
if [ "$rc" = 0 ] && grep -q '/touch' "$TMP/curl.log"; then
  ok "tapon? taps when the pattern is present"
else
  no "tapon? taps when the pattern is present" "rc=$rc"
fi

# include-if runs the included file when the pattern matches
jf="$TMP/incif-main.journey"
printf 'include-if "^SCAN$" incif-sub.journey\n' > "$jf"
printf 'log included\n' > "$TMP/incif-sub.journey"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1); rc=$?
if [ "$rc" = 0 ] && echo "$out" | grep -q 'included'; then
  ok "include-if runs the sub-journey when the pattern is visible"
else
  no "include-if runs the sub-journey when the pattern is visible" "rc=$rc out=$out"
fi

# include-if skips when the pattern does not match
jf="$TMP/incif-skip.journey"
printf 'include-if "^NoSuchElement$" incif-sub.journey\nlog continued\n' > "$jf"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1); rc=$?
if [ "$rc" = 0 ] && echo "$out" | grep -q 'continued' && ! echo "$out" | grep -q 'included'; then
  ok "include-if skips when the pattern is not visible"
else
  no "include-if skips when the pattern is not visible" "rc=$rc out=$out"
fi

# include-if-not is the inverse
jf="$TMP/incifnot.journey"
printf 'include-if-not "^NoSuchElement$" incif-sub.journey\n' > "$jf"
: > "$TMP/curl.log"
out=$(drv script "$jf" 2>&1); rc=$?
if [ "$rc" = 0 ] && echo "$out" | grep -q 'included'; then
  ok "include-if-not runs the sub-journey when the pattern is absent"
else
  no "include-if-not runs the sub-journey when the pattern is absent" "rc=$rc out=$out"
fi

echo
echo "putting the keyboard away"
# iOS has no API for it, so there is no driver route either — see the block in
# driver.sh. What is testable here is that both measured methods are tried, in
# the order that puts the harmless one first, and that the answer is read back
# rather than assumed.

: > "$TMP/curl.log"
out=$(drv dismiss); rc=$?
if [ "$rc" = 0 ] && case "$out" in *"already down"*) true ;; *) false ;; esac &&
   ! grep -q '/touch' "$TMP/curl.log"; then
  ok "dismiss on a keyboard that is already down taps nothing"
else
  no "dismiss on a keyboard that is already down taps nothing" "rc=$rc: $out"
fi

: > "$TMP/curl.log"
pt=$(drv blank | tr ' ' ',')
out=$(KB_UNTIL=touch drv dismiss); rc=$?
if [ "$rc" = 0 ] && case "$out" in *"with a tap at $pt"*) true ;; *) false ;; esac; then
  ok "dismiss tries the blank tap first, and says where it tapped"
else
  no "dismiss tries the blank tap first, and says where it tapped" "blank=$pt rc=$rc: $out"
fi

# The point has to be somewhere a tap does nothing, which is the whole claim.
chk=$(REPO="$REPO" python3 - "$FIX/iphone-portrait-keyboard-up.json" 402 874 \
        "$FIX/ipad-landscape-keyboard-up.json" 1194 834 <<'PYCHK'
import json, os, sys
sys.path.insert(0, os.environ["REPO"] + "/bin")
import resolve
bad = []
for i in (0, 3):
    path, w, h = sys.argv[1 + i], float(sys.argv[2 + i]), float(sys.argv[3 + i])
    hier = json.load(open(path))
    b = resolve.blank_point(hier, w, h)
    if "point" not in b:
        bad.append("%s: %s" % (path, b["error"]))
        continue
    px, py = b["point"]
    g = resolve.keyboard_geometry(hier["axElement"], w, h)
    top = h if g is None else g[0]
    if py >= top:
        bad.append("%s: %g is not above the keyboard at %g" % (path, py, top))
    for (rx, ry, rw, rh), why in resolve.obstacles(hier, w, h):
        if rx <= px <= rx + rw and ry <= py <= ry + rh:
            bad.append("%s: %s,%s is inside %r" % (path, px, py, why))
print("|".join(bad))
PYCHK
)
[ -z "$chk" ] && ok "the blank point is above the keyboard and on top of nothing" \
  || no "the blank point is above the keyboard and on top of nothing" "$chk"

out=$(python3 "$REPO/bin/resolve.py" --blank --width 60 --height 60 \
        < "$FIX/iphone-portrait-keyboard-up.json" 2>&1); rc=$?
[ "$rc" = 5 ] && ok "a screen with no room above the keyboard is refused, not guessed at" \
  || no "a screen with no room above the keyboard is refused, not guessed at" "rc=$rc: $out"

: > "$TMP/curl.log"
out=$(KB_UNTIL=pressKey drv dismiss); rc=$?
if [ "$rc" = 0 ] && case "$out" in *'`key return`'*commit*) true ;; *) false ;; esac; then
  ok "when only key return works, dismiss says so and what it may have committed"
else
  no "when only key return works, dismiss says so and what it may have committed" "rc=$rc: $out"
fi

: > "$TMP/curl.log"
out=$(KB_UNTIL=pressKey drv dismiss --no-key); rc=$?
if [ "$rc" = 1 ] && ! grep -q '/pressKey' "$TMP/curl.log"; then
  ok "--no-key stops before the method that can submit the field"
else
  no "--no-key stops before the method that can submit the field" "rc=$rc: $out"
fi

: > "$TMP/curl.log"
out=$(KB_UNTIL=never drv dismiss); rc=$?
if [ "$rc" = 1 ] && case "$out" in *"still up after a tap"*) true ;; *) false ;; esac; then
  ok "a keyboard that will not go is reported as still up, not as dismissed"
else
  no "a keyboard that will not go is reported as still up, not as dismissed" "rc=$rc: $out"
fi

# The refusal is the place a caller meets this problem, so that is where the
# verb has to be named.
out=$(python3 "$REPO/bin/resolve.py" '^SETTINGS' --width 402 --height 874 --point \
        < "$TMP/kb-pos.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$out" in
  *"driver.sh dismiss"*) ok "the under-the-keyboard refusal names the verb that fixes it" ;;
  *) no "the under-the-keyboard refusal names the verb that fixes it" "$out" ;;
esac

echo
echo "expect / expect-not wait for a condition (item 41)"
# Default timeout 0: one check, answered at once, no heartbeat and no sleep — so
# existing journeys do not silently start waiting.
out=$(drv expect '^SCAN$' 2>&1); rc=$?
[ "$rc" = 0 ] && ok "expect passes at once when the element is present" \
  || no "expect passes at once when the element is present" "rc=$rc: $out"

out=$(drv expect '^ZZNOPE$' 2>&1); rc=$?
{ [ "$rc" = 1 ] && ! printf '%s' "$out" | grep -q 'waiting for'; } \
  && ok "expect with no timeout fails immediately, with no heartbeat" \
  || no "expect with no timeout fails immediately, with no heartbeat" "rc=$rc: $out"

out=$(drv expect-not '^ZZNOPE$' 2>&1); rc=$?
[ "$rc" = 0 ] && ok "expect-not passes at once when the element is absent" \
  || no "expect-not passes at once when the element is absent" "rc=$rc: $out"

# A timeout>0 on a condition that never comes: poll to the deadline, one
# heartbeat a second, then fail naming the limit. The stub never changes, so this
# exercises the give-up path; returning the moment it is met is the loop checking
# before it sleeps.
start=$(date +%s); out=$(drv expect '^ZZNOPE$' 2 2>&1); rc=$?
elapsed=$(( $(date +%s) - start ))
{ [ "$rc" = 1 ] && printf '%s' "$out" | grep -q '1/2s' \
    && printf '%s' "$out" | grep -q 'not found after 2s' && [ "$elapsed" -ge 2 ]; } \
  && ok "expect <timeout> polls with a per-second heartbeat, then fails naming the limit" \
  || no "expect <timeout> polls with a per-second heartbeat, then fails naming the limit" \
       "rc=$rc t=${elapsed}s: $(printf '%s' "$out" | tr '\n' '|')"

out=$(drv expect-not '^SCAN$' 1 2>&1); rc=$?
{ [ "$rc" = 1 ] && printf '%s' "$out" | grep -q 'to clear (1/1s)' \
    && printf '%s' "$out" | grep -q 'is present after 1s'; } \
  && ok "expect-not <timeout> waits for it to clear, then fails naming the limit" \
  || no "expect-not <timeout> waits for it to clear, then fails naming the limit" \
       "rc=$rc: $(printf '%s' "$out" | tr '\n' '|')"

# A non-numeric timeout must not crash the step — treat it as no timeout.
out=$(drv expect '^ZZNOPE$' notanumber 2>&1); rc=$?
{ [ "$rc" = 1 ] && ! printf '%s' "$out" | grep -q 'waiting for'; } \
  && ok "a non-numeric timeout is treated as zero, not a crash" \
  || no "a non-numeric timeout is treated as zero, not a crash" "rc=$rc: $out"

echo
echo "flag column is bracketed and fixed-width (item 32)"
# A selected element must show [S ] not bare S before the label
sel_fix='{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":9,"label":"SETTINGS","selected":true,"frame":{"X":0,"Y":770,"Width":80,"Height":70}},
 {"elementType":9,"label":"CHAT","frame":{"X":80,"Y":770,"Width":80,"Height":70}}]}}'
treeout=$(printf '%s' "$sel_fix" | python3 "$REPO/bin/tree.py" tree 2>&1)
case "$treeout" in
  *"[S ]"*SETTINGS*) ok "a selected element shows [S ] before the label" ;;
  *) no "a selected element shows [S ] before the label" "got: $treeout" ;;
esac
case "$treeout" in
  *"    "*CHAT*) ok "an unflagged element has a blank field keeping columns aligned" ;;
  *) no "an unflagged element has a blank field keeping columns aligned" "got: $treeout" ;;
esac

echo
echo "explain: consecutive identical markers collapse (item 34)"
# resolve.py explain should show one marker with "(replaces, not compounds)"
exp_fix='{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":1,"frame":{"X":0,"Y":0,"Width":134,"Height":291.333},"children":[
  {"elementType":1,"frame":{"X":0,"Y":0,"Width":134,"Height":291.333},"children":[
   {"elementType":9,"label":"LOC1","frame":{"X":12.5,"Y":182.5,"Width":91.7,"Height":16}}]}]}]}}'
expout=$(printf '%s' "$exp_fix" | $R "^LOC1$" --width 402 --height 874 --explain 2>&1)
case "$expout" in
  *"replaces, not compounds"*) ok "consecutive identical markers collapse with a note" ;;
  *) no "consecutive identical markers collapse with a note" "got: $expout" ;;
esac

echo
echo "partial keyboard coverage noted (item 35)"
# An element whose top (y=540) is above the keyboard (top=569) but centre
# (y=580) is below it should note the partial coverage.
printf '%s' '{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":19,"label":"SystemInputAssistantView","frame":{"X":0,"Y":569,"Width":402,"Height":48}},
 {"elementType":19,"label":"UIKeyboardLayoutStar","frame":{"X":0,"Y":617,"Width":402,"Height":257}},
 {"elementType":9,"label":"PARTIAL","frame":{"X":50,"Y":540,"Width":200,"Height":80}},
 {"elementType":9,"label":"ABOVE","frame":{"X":50,"Y":100,"Width":200,"Height":44}}]}}' > "$TMP/kb-partial.json"
msg=$($R "^PARTIAL$" --width 402 --height 874 --point < "$TMP/kb-partial.json" 2>&1 | tr '\n' ' ' | tr -s ' ')
case "$msg" in
  *"partially covered"*) ok "an element with its top above the keyboard is noted as partially covered" ;;
  *) no "an element with its top above the keyboard is noted as partially covered" "got: $msg" ;;
esac

echo
echo "expect-cmd polls a command (item 41 remainder)"
# expect-cmd with a passing command succeeds
out=$(drv expect-cmd "true" 2 2>&1); rc=$?
[ "$rc" = 0 ] && ok "expect-cmd passes when the command succeeds" \
  || no "expect-cmd passes when the command succeeds" "rc=$rc: $out"
# expect-cmd with a failing command fails
start=$(date +%s); out=$(drv expect-cmd "false" 1 2>&1); rc=$?
elapsed=$(( $(date +%s) - start ))
{ [ "$rc" = 1 ] && [ "$elapsed" -ge 1 ]; } \
  && ok "expect-cmd fails after the timeout when the command never succeeds" \
  || no "expect-cmd fails after the timeout when the command never succeeds" "rc=$rc t=${elapsed}s"

echo
echo "named value profiles (item 37)"
# PROFILE=<name> loads .maestro-mac.conf.<name> on top of the base
mkdir -p "$TMP/prof"
printf ': "${APP_ID:=base.app}"\n: "${APP_USER:=baseuser}"\n: "${MAC_HOST:=stub}"\n: "${MAC_FQDN:=s}"\n' > "$TMP/prof/.maestro-mac.conf"
printf 'APP_USER=altuser\n' > "$TMP/prof/.maestro-mac.conf.alt"
base_user=$(cd "$TMP/prof" && bash -c '. "'"$REPO"'/bin/config.sh" && echo "$APP_USER"' 2>/dev/null)
alt_user=$(cd "$TMP/prof" && PROFILE=alt bash -c '. "'"$REPO"'/bin/config.sh" && echo "$APP_USER"' 2>/dev/null)
[ "$base_user" = "baseuser" ] && ok "base conf loads its own APP_USER" \
  || no "base conf loads its own APP_USER" "got: $base_user"
[ "$alt_user" = "altuser" ] && ok "PROFILE=alt overrides APP_USER from the profile" \
  || no "PROFILE=alt overrides APP_USER from the profile" "got: $alt_user"

echo
echo "compact tree mode (item 43)"
# text mode filters keyboard/status-bar, dedupes, omits frames
treeout=$(python3 "$REPO/bin/tree.py" text < "$FIX/iphone-portrait-keyboard-up.json" 2>&1)
echo "$treeout" | grep -q "key " \
  && no "text mode filters keyboard keys" "key still present" \
  || ok "text mode filters keyboard keys"
echo "$treeout" | grep -q "statusbar" \
  && no "text mode filters the status bar" "statusbar still present" \
  || ok "text mode filters the status bar"
# frames (the "1234,567 " column) should be absent
echo "$treeout" | grep -qE '^ *[0-9]+,[0-9]' \
  && no "text mode omits frames" "frames present" \
  || ok "text mode omits frames"
# an empty screen prints the hint
emptyfix='{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[]}}'
hintout=$(printf '%s' "$emptyfix" | python3 "$REPO/bin/tree.py" text 2>&1)
case "$hintout" in
  *"no text nodes"*) ok "text mode prints a hint on an empty screen" ;;
  *) no "text mode prints a hint on an empty screen" "got: $hintout" ;;
esac

echo
echo "assert enabled/disabled state (item 38)"
# resolve.py --enabled/--disabled filter, tested directly against a synthetic fixture
dis_fix='{"axElement":{"elementType":0,"frame":{"X":0,"Y":0,"Width":402,"Height":874},"children":[
 {"elementType":9,"label":"SUBMIT","enabled":false,"frame":{"X":50,"Y":100,"Width":200,"Height":44}},
 {"elementType":9,"label":"CANCEL","enabled":true,"frame":{"X":50,"Y":200,"Width":200,"Height":44}}]}}'
# --enabled on a disabled element fails
printf '%s' "$dis_fix" | $R "^SUBMIT$" --width 402 --height 874 --point --enabled >/dev/null 2>&1
rc=$?; [ "$rc" = 3 ] && ok "resolve --enabled rejects a disabled match" \
  || no "resolve --enabled rejects a disabled match" "rc=$rc"

# --enabled on an enabled element passes
printf '%s' "$dis_fix" | $R "^CANCEL$" --width 402 --height 874 --point --enabled >/dev/null 2>&1
rc=$?; [ "$rc" = 0 ] && ok "resolve --enabled passes an enabled match" \
  || no "resolve --enabled passes an enabled match" "rc=$rc"

# --disabled on a disabled element passes
printf '%s' "$dis_fix" | $R "^SUBMIT$" --width 402 --height 874 --point --disabled >/dev/null 2>&1
rc=$?; [ "$rc" = 0 ] && ok "resolve --disabled passes a disabled match" \
  || no "resolve --disabled passes a disabled match" "rc=$rc"

# --disabled on an enabled element fails
printf '%s' "$dis_fix" | $R "^CANCEL$" --width 402 --height 874 --point --disabled >/dev/null 2>&1
rc=$?; [ "$rc" = 3 ] && ok "resolve --disabled rejects an enabled match" \
  || no "resolve --disabled rejects an enabled match" "rc=$rc"

# journey: expect "^SUBMIT$" disabled passes on a disabled element
printf '%s' "$dis_fix" > "$TMP/dis-fix.json"
jf="$TMP/expect-dis.journey"
printf 'expect "^SUBMIT$" disabled\n' > "$jf"
out=$(PATH="$TMP/stub:$PATH" CURL_LOG="$TMP/curl.log" \
      FIXTURE="$TMP/dis-fix.json" bash "$DBIN/driver.sh" script "$jf" 2>&1); rc=$?
[ "$rc" = 0 ] && ok "journey: expect <pat> disabled passes on a disabled element" \
  || no "journey: expect <pat> disabled passes on a disabled element" "rc=$rc: $out"

echo
echo "a journey runs to the end even when a verb drains stdin (item 36)"
# The read must own its own fd: a verb that shells out to something reading stdin
# (ssh, historically) would otherwise swallow the rest of the file and end the run
# at line 1 with status 0. Reproduce the eater with a curl stub that drains stdin,
# and assert every line still runs. With the read on fd 0 (the old bug) the drain
# eats the journey; on its own fd it cannot.
mkdir -p "$TMP/stub-eat"
cat > "$TMP/stub-eat/curl" <<'CURLSH'
#!/usr/bin/env bash
cat >/dev/null 2>&1 || true       # the stdin eater, like ssh reading fd 0
prev=; for a in "$@"; do case "$a" in http*) url=$a ;; esac
  [ "$prev" = -d ] && body=$a; prev=$a; done
case "$url" in
  */status)         printf '200' ;;
  */isScreenStatic) printf '{"isScreenStatic":true}' ;;
  */deviceInfo)     printf '{"widthPoints":402,"heightPoints":874}' ;;
  *)                printf '{}' ;;
esac
CURLSH
chmod +x "$TMP/stub-eat/curl"
printf 'tap 1 1\ntap 2 2\ntap 3 3\nlog done\n' > "$TMP/eat.journey"
out=$(PATH="$TMP/stub-eat:$PATH" FIXTURE="$FIX/iphone-portrait-keyboard-up.json" \
      bash "$DBIN/driver.sh" script "$TMP/eat.journey" </dev/null 2>&1); rc=$?
oks=$(printf '%s\n' "$out" | grep -c '  ok   ')
{ [ "$rc" = 0 ] && [ "$oks" = 4 ]; } \
  && ok "all 4 lines run despite a stdin-draining verb, exit 0" \
  || no "all 4 lines run despite a stdin-draining verb, exit 0" "rc=$rc oks=$oks: $(printf '%s' "$out" | tr '\n' '|')"

# The failure path still stops the run and returns non-zero (the fd is closed on
# it too), and the line after the failure does not run.
printf 'expect ^ZZNOPE$\nlog unreached\n' > "$TMP/fail.journey"
out=$(drv script "$TMP/fail.journey" 2>&1); rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'FAILED at' \
    && ! printf '%s' "$out" | grep -q 'unreached'; } \
  && ok "a failing step stops the journey, returns non-zero, and runs no further" \
  || no "a failing step stops the journey, returns non-zero, and runs no further" "rc=$rc: $(printf '%s' "$out" | tr '\n' '|')"

echo
echo "a dead device driver names the real cause, not the relay (item 46)"
# _devdrv_hint probes lockState and the Mac's device driver log on a status
# failure. Extract just that function and drive it with a fake _ssh that answers
# both probes, so no Mac is needed. DEV is set because the function names it.
DRVLOG='Testing started\nThe connection was invalidated\n** TEST EXECUTE FAILED **\n'
if ( DEV=devudid
     _ssh(){ case "$*" in *lockState*) echo "  passcodeRequired: false" ;; *devdrv.log*) printf "$DRVLOG" ;; esac; }
     source <(sed -n '/^_devdrv_hint()/,/^}/p' "$REPO/bin/driver.sh")
     out=$(_devdrv_hint 2>&1)
     printf '%s' "$out" | grep -q 'devdrv.log' &&
     printf '%s' "$out" | grep -q 'connection was invalidated' &&
     printf '%s' "$out" | grep -q 'item 46' &&
     ! printf '%s' "$out" | grep -q 'LOCKED' ); then
  ok "an unlocked device with a dead driver surfaces ~/devdrv.log and item 46"
else
  no "an unlocked device with a dead driver surfaces ~/devdrv.log and item 46" "hint missing or wrong"
fi
if ( DEV=devudid
     _ssh(){ case "$*" in *lockState*) echo "  passcodeRequired: true" ;; *devdrv.log*) printf "$DRVLOG" ;; esac; }
     source <(sed -n '/^_devdrv_hint()/,/^}/p' "$REPO/bin/driver.sh")
     out=$(_devdrv_hint 2>&1)
     printf '%s' "$out" | grep -q 'LOCKED' &&
     printf '%s' "$out" | grep -qi 'unlock' ); then
  ok "a locked phone is named first — unlock it — ahead of the relay/log noise"
else
  no "a locked phone is named first — unlock it — ahead of the relay/log noise" "lock hint missing"
fi
if ( DEV=simudid; _ssh(){ return 0; }
     source <(sed -n '/^_devdrv_hint()/,/^}/p' "$REPO/bin/driver.sh")
     out=$(_devdrv_hint 2>&1); [ -z "$out" ] ); then
  ok "no lock and no device log means no extra output (a simulator run is unaffected)"
else
  no "no lock and no device log means no extra output (a simulator run is unaffected)" "printed something"
fi

echo
echo "a registered physical device resolves like a simulator (item 45)"
# bin/device.sh registers a phone in DEVICE_MAP; _driver_map must merge it so
# _driver_bind finds it. Test the seam by extracting the two functions.
if ( LDIR="$TMP/devseam"; mkdir -p "$LDIR"
     DRIVER_MAP="$LDIR/drivers.map"; DEVICE_MAP="$LDIR/devices.map"
     DPORT_BASE=9101; DRIVER_PORT_BASE=22087
     : > "$DRIVER_MAP"                                   # no simulators
     echo "DEVUDID 22187 device" > "$DEVICE_MAP"         # one phone
     _driver_scan(){ cat "$DRIVER_MAP"; }               # no Mac
     source <(sed -n '/^_driver_map()/,/^}/p' "$REPO/bin/lib.sh")
     source <(sed -n '/^_dport_for()/,/^}/p' "$REPO/bin/lib.sh")
     _driver_map | grep -q "DEVUDID 22187 device" &&
     [ "$(_dport_for 22187)" = 9201 ] ); then
  ok "a device in DEVICE_MAP shows up in the driver map, with the right relay port"
else
  no "a device in DEVICE_MAP shows up in the driver map, with the right relay port" "seam broken"
fi
# The ensure-driver recovery (item 46) must fire only for a registered phone, and
# never reach bin/device.sh for a simulator.
if ( LDIR="$TMP/ensure1"; mkdir -p "$LDIR"; DEVICE_MAP="$LDIR/devices.map"
     echo "PHONEUDID 22187 device" > "$DEVICE_MAP"
     source <(sed -n '/^_is_device()/,/^}/p' "$REPO/bin/driver.sh")
     DEV=PHONEUDID; _is_device &&
     { DEV=SIMUDID; _is_device && exit 1; true; } ); then
  ok "_is_device tells a registered phone from a simulator"
else
  no "_is_device tells a registered phone from a simulator" "gate wrong"
fi
if ( LDIR="$TMP/ensure2"; mkdir -p "$LDIR"; DEVICE_MAP="$LDIR/devices.map"; : > "$DEVICE_MAP"
     _ensure_dev_retry=0; HERE=/nonexistent-would-fail-if-reached; DEV=SIMUDID
     source <(sed -n '/^_is_device()/,/^}/p' "$REPO/bin/driver.sh")
     source <(sed -n '/^_ensure_device()/,/^}/p' "$REPO/bin/driver.sh")
     _ensure_device; [ $? = 1 ] ); then
  ok "ensure-driver no-ops for a simulator, never reaching device.sh"
else
  no "ensure-driver no-ops for a simulator, never reaching device.sh" "did not self-gate"
fi

echo
echo "the tree renderer"
for f in ipad-landscape-keyboard-up iphone-portrait-keyboard-up; do
  t=$(python3 "$REPO/bin/tree.py" tree < "$FIX/$f.json" | wc -l)
  n=$(python3 "$REPO/bin/tree.py" nodes < "$FIX/$f.json" | wc -l)
  [ "$t" -gt 0 ] && [ "$n" -gt "$t" ] \
    && ok "$f renders, and nodes is the longer of the two ($t/$n)" \
    || no "$f renders, and nodes is the longer of the two" "tree $t, nodes $n"
done
# An unlabelled container has a frame and nothing else, so it is exactly what
# `tree` drops and `nodes` keeps.
python3 "$REPO/bin/tree.py" tree < "$FIX/ipad-landscape-system-alert.json" | grep -q 'Allow' \
  && ok "a labelled node survives the tree filter" \
  || no "a labelled node survives the tree filter" "Allow is missing"
python3 "$REPO/bin/tree.py" nodes < "$FIX/ipad-landscape-system-alert.json" | grep -qE '^ *[0-9]+,[0-9-]+ +[0-9]+x[0-9]+ +[a-z]' \
  && ok "every line carries a frame and a type" \
  || no "every line carries a frame and a type" "no line matched the shape"



echo
echo "a driver that was taken, not one that was never there"
# Measured 13 Aug on three simulators: running Maestro against a device
# destroys THAT device's driver when the command finishes, and leaves every
# other one alone. The failure lands one call later, on whatever tries to use
# that device next, where "no driver" reads as if there had never been one.
lib(){ # lib <LDIR> <script...>
  local d=$1; shift
  LDIR="$d" MAC_HOST=x MAC_FQDN=x APP_ID=x DEV= MAESTRO_MAC_CONF=/dev/null bash -c '
    . '"$REPO"'/bin/lib.sh 2>/dev/null
    '"$*" 2>&1
}
OWN="$TMP/own"; mkdir -p "$OWN"

got=$(lib "$OWN" '_driver_own AAA 22087; _driver_own BBB 22088; _driver_owned BBB')
case "$got" in
  "22088 "*) ok "a started driver is recorded against its device" ;;
  *) no "a started driver is recorded against its device" "got '$got'" ;;
esac

# Starting the same device again must replace its line, not add a second one —
# `up` records on the already-up path as well as the fresh one.
got=$(lib "$OWN" '_driver_own AAA 22090; grep -c "^AAA " "$DRIVER_OWNED"')
[ "$got" = 1 ] && ok "re-recording a device replaces its line" \
  || no "re-recording a device replaces its line" "got $got lines"
got=$(lib "$OWN" '_driver_owned AAA')
case "$got" in 22090*) ok "and keeps the newer port" ;; *) no "and keeps the newer port" "got '$got'" ;; esac

got=$(lib "$OWN" '_driver_disown AAA; _driver_owned AAA; _driver_owned BBB')
case "$got" in
  22088*) ok "disowning one device leaves the others" ;;
  *) no "disowning one device leaves the others" "got '$got'" ;;
esac
got=$(lib "$OWN" '_driver_disown; _driver_owned BBB')
[ -z "$got" ] && ok "down-all clears the lot" || no "down-all clears the lot" "got '$got'"

# The note itself. Two other drivers still running, so it must say the loss was
# confined to this device — that is the fact that stops the next ten minutes
# being spent suspecting the app or the relay.
note=$(lib "$OWN" '_driver_own CCC 22088
  _driver_gone_note CCC "AAA 22087 1
BBB 22089 2"' | tr '\n' ' ' | tr -s ' ')
case "$note" in
  *"port 22088"*) ok "the note names the port the driver had" ;;
  *) no "the note names the port the driver had" "said: $note" ;;
esac
case "$note" in
  *"destroys that device's driver"*) ok "the note says what takes a driver away" ;;
  *) no "the note says what takes a driver away" "said: $note" ;;
esac
case "$note" in
  *"bin/hier.sh"*"bin/flow.sh"*"bin/shot.sh"*) ok "the note names the scripts that do it" ;;
  *) no "the note names the scripts that do it" "said: $note" ;;
esac
case "$note" in
  *"the other 2 still have theirs"*) ok "the note says the other devices are fine" ;;
  *) no "the note says the other devices are fine" "said: $note" ;;
esac

# A device nobody started must not get the explanation — there is nothing to
# explain, and inventing a cause is worse than the plain message.
note=$(lib "$OWN" '_driver_gone_note NEVERSTARTED "AAA 22087 1"')
[ -z "$note" ] && ok "a device that was never started gets no explanation" \
  || no "a device that was never started gets no explanation" "said: $note"

# The count wording has to survive both edges.
note=$(lib "$OWN" '_driver_own DDD 22087; _driver_gone_note DDD ""' | tr '\n' ' ')
case "$note" in
  *"none has a driver either"*) ok "with nothing else running it says so" ;;
  *) no "with nothing else running it says so" "said: $note" ;;
esac
note=$(lib "$OWN" '_driver_own EEE 22087; _driver_gone_note EEE "AAA 22088 1"' | tr '\n' ' ')
case "$note" in
  *"the remaining one still has its driver"*) ok "one survivor is not called 'the other 1'" ;;
  *) no "one survivor is not called 'the other 1'" "said: $note" ;;
esac



echo
echo "working out how a project is built"
# remote/build.sh runs on the Mac but touches nothing but the filesystem when
# detecting, so the whole of its discovery is testable here against a repo
# built to the same shape as the real one: a pinned SDK, seven entrypoints of
# which one is a template, and schemes that do not all have an entrypoint.
mkrepo(){ # mkrepo <dir> <flavour>...
  local d=$1; shift
  mkdir -p "$d/lib" "$d/.fvm/flutter/bin" "$d/ios/Runner.xcodeproj/xcshareddata/xcschemes"
  printf '#!/bin/sh\necho "Flutter 3.41.9 - test stub"\n' > "$d/.fvm/flutter/bin/flutter"
  chmod +x "$d/.fvm/flutter/bin/flutter"
  echo 3.41.9 > "$d/.fvm/flutter.version"
  : > "$d/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
  : > "$d/ios/Runner.xcodeproj/xcshareddata/xcschemes/Demo AnalyticsExtension.xcscheme"
  : > "$d/lib/main_env.tpl.dart"          # a template, not an entrypoint
  : > "$d/lib/main_orphan.dart"           # an entrypoint with no scheme
  : > "$d/ios/Runner.xcodeproj/xcshareddata/xcschemes/noentry.xcscheme"
  : > "$d/ios/Runner.xcodeproj/project.pbxproj"
  for f in "$@"; do
    : > "$d/lib/main_$f.dart"
    : > "$d/ios/Runner.xcodeproj/xcshareddata/xcschemes/$f.xcscheme"
  done
}
pbx(){ # pbx <dir> <config> <bundle id>
  printf '\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = %s;\n\t\t\tname = "%s";\n' \
    "$3" "$2" >> "$1/ios/Runner.xcodeproj/project.pbxproj"
}
B="sh $REPO/remote/build.sh"
RP="$TMP/repo"; mkrepo "$RP" dev uat prod
pbx "$RP" Debug           com.example.app.dev      # the unflavoured default
pbx "$RP" Debug-dev       com.example.app.dev
pbx "$RP" Release-dev     com.example.app.dev
pbx "$RP" Debug-uat       com.example.app.uat
pbx "$RP" Debug-prod      com.example.app.prod

out=$($B --repo "$RP" --detect --app-id com.example.app.dev 2>&1)
case "$out" in
  *".fvm/flutter/bin/flutter"*) ok "the SDK the repo pins is the one it uses" ;;
  *) no "the SDK the repo pins is the one it uses" "got: $out" ;;
esac
case "$out" in
  *"flavour    dev — the only one whose bundle id is"*)
    ok "the flavour comes from which configuration builds that bundle id" ;;
  *) no "the flavour comes from which configuration builds that bundle id" "got: $out" ;;
esac
case "$out" in
  *"target     lib/main_dev.dart"*) ok "the entrypoint follows from the flavour" ;;
  *) no "the entrypoint follows from the flavour" "got: $out" ;;
esac

# A flavour needs BOTH halves. This is what discards a template entrypoint, an
# extension's scheme, and either half on its own — without knowing about any of
# them by name.
out=$($B --repo "$RP" --detect 2>&1)
for absent in main_env.tpl Runner "Demo Analytics" noentry orphan; do
  case "$out" in
    *"$absent"*) no "'$absent' is not offered as a flavour" "it was listed" ;;
    *) ok "'$absent' is not offered as a flavour" ;;
  esac
done
n=$(printf '%s\n' "$out" | grep -cE '^ +(dev|uat|prod)  \(-t ')
[ "$n" = 3 ] && ok "the three real flavours are all offered" \
  || no "the three real flavours are all offered" "listed $n"

# Refusing is the point. Building the wrong flavour installs a different bundle
# id and leaves the app under test exactly as it was, which nothing reports.
$B --repo "$RP" --app-id com.example.app.dev --flavor "" >/dev/null 2>&1
out=$($B --repo "$RP" 2>&1); rc=$?
[ "$rc" != 0 ] && case "$out" in
  *"NOT DECIDED"*) ok "with no bundle id to go on it refuses rather than picking" ;;
  *) no "with no bundle id to go on it refuses rather than picking" "got: $out" ;;
esac || no "with no bundle id to go on it refuses rather than picking" "rc=$rc"

# Two flavours can legitimately build the same id; then there is no evidence.
RP2="$TMP/repo2"; mkrepo "$RP2" dev alt
pbx "$RP2" Debug-dev com.example.app.dev
pbx "$RP2" Debug-alt com.example.app.dev
out=$($B --repo "$RP2" --app-id com.example.app.dev 2>&1); rc=$?
[ "$rc" != 0 ] && case "$out" in
  *"2 of them build com.example.app.dev"*) ok "two flavours building one id is reported, not resolved" ;;
  *) no "two flavours building one id is reported, not resolved" "got: $out" ;;
esac || no "two flavours building one id is reported, not resolved" "rc=$rc"

# --detect must never stop at the refusal: reporting is the whole job.
$B --repo "$RP2" --detect --app-id com.example.app.dev >/dev/null 2>&1 \
  && ok "--detect reports and exits 0 even when the flavour is undecided" \
  || no "--detect reports and exits 0 even when the flavour is undecided" "it exited non-zero"

out=$($B --repo "$RP" --detect --flavor nosuch 2>&1)
case "$out" in
  *"no scheme and entrypoint pair of that name"*) ok "a flavour that does not exist is called out, not obeyed silently" ;;
  *) no "a flavour that does not exist is called out, not obeyed silently" "got: $out" ;;
esac

# An unflavoured project must not be told to choose a flavour it has not got.
RP3="$TMP/repo3"; mkdir -p "$RP3/lib" "$RP3/.fvm/flutter/bin"
printf '#!/bin/sh\necho stub\n' > "$RP3/.fvm/flutter/bin/flutter"; chmod +x "$RP3/.fvm/flutter/bin/flutter"
: > "$RP3/lib/main.dart"
out=$($B --repo "$RP3" --detect 2>&1)
case "$out" in
  *"flavour    none"*) ok "a project with lib/main.dart and no schemes needs no flavour" ;;
  *) no "a project with lib/main.dart and no schemes needs no flavour" "got: $out" ;;
esac

# No SDK at all is the one failure that has to name the fix, because a repo
# that pins with fvm needs `fvm install` before anything here can work.
RP4="$TMP/repo4"; mkdir -p "$RP4/lib" "$TMP/minbin"
# A PATH with a shell on it and nothing else: this machine has a flutter on its
# own PATH, and the point is a Mac that has none.
ln -sf "$(command -v sh)" "$TMP/minbin/sh"
out=$(PATH="$TMP/minbin" HOME="$TMP/nohome" "$TMP/minbin/sh" "$REPO/remote/build.sh" \
        --repo "$RP4" --detect 2>&1); rc=$?
[ "$rc" != 0 ] && case "$out" in
  *"fvm install"*) ok "no SDK anywhere says what to do about it" ;;
  *) no "no SDK anywhere says what to do about it" "got: $out" ;;
esac || no "no SDK anywhere says what to do about it" "rc=$rc"

# GEM_HOME is only right when `pod` is genuinely missing — setting it when it
# is not needed breaks a working CocoaPods just as effectively.
mkdir -p "$TMP/gemhome/.gem/bin"
printf '#!/bin/sh\n' > "$TMP/gemhome/.gem/bin/pod"; chmod +x "$TMP/gemhome/.gem/bin/pod"
out=$(HOME="$TMP/gemhome" $B --repo "$RP" --detect --app-id com.example.app.dev 2>&1)
case "$out" in
  *"using GEM_HOME=$TMP/gemhome/.gem"*) ok "a pod outside PATH is found and GEM_HOME reported" ;;
  *) no "a pod outside PATH is found and GEM_HOME reported" "got: $(printf '%s' "$out" | grep cocoapods)" ;;
esac
out=$(PATH="$TMP/gemhome/.gem/bin:$PATH" $B --repo "$RP" --detect --app-id com.example.app.dev 2>&1)
case "$out" in
  *"GEM_HOME"*) no "a pod already on PATH is left alone" "GEM_HOME set anyway" ;;
  *) ok "a pod already on PATH is left alone" ;;
esac

# A build that installs nothing must not exit 0 (item 40). Stub xcrun so the
# install and the residency check can each be made to fail, and drop a fake built
# .app in place so the build step reaches the install loop.
mkdir -p "$RP/build/ios/iphonesimulator/Runner.app" "$TMP/xcstub"
cat > "$TMP/xcstub/xcrun" <<'XC'
#!/bin/sh
case "$2" in
  install)           exit "${XC_INSTALL_RC:-0}" ;;
  get_app_container) [ "${XC_CONTAINER_RC:-0}" = 0 ] && echo /fake/container
                     exit "${XC_CONTAINER_RC:-0}" ;;
  *) exit 0 ;;
esac
XC
chmod +x "$TMP/xcstub/xcrun"
bld(){ PATH="$TMP/xcstub:$PATH" $B --repo "$RP" --app-id com.example.app.dev \
         --flavor dev --install SIMUDID 2>&1; }

out=$(XC_INSTALL_RC=1 bld); rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'install failed: SIMUDID'; } \
  && ok "a failed install makes the build exit non-zero" \
  || no "a failed install makes the build exit non-zero" "rc=$rc: $(printf '%s' "$out" | tr '\n' '|')"

out=$(XC_INSTALL_RC=0 XC_CONTAINER_RC=1 bld); rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'not on SIMUDID afterwards'; } \
  && ok "install returning 0 but the app not resident is caught, not passed" \
  || no "install returning 0 but the app not resident is caught, not passed" "rc=$rc: $(printf '%s' "$out" | tr '\n' '|')"

out=$(XC_INSTALL_RC=0 XC_CONTAINER_RC=0 bld); rc=$?
{ [ "$rc" = 0 ] && printf '%s' "$out" | grep -q 'installed  SIMUDID'; } \
  && ok "a real install reports installed and exits 0" \
  || no "a real install reports installed and exits 0" "rc=$rc: $(printf '%s' "$out" | tr '\n' '|')"


echo
echo "vmservice: the flutter run log fallback, and the two failures kept apart (item 39)"
mkdir -p "$TMP/vmstub"
# xcrun stub: the simulator system log yields no URI — the app scrolled out of
# the 5-minute window — which is exactly what forces the flutter-run-log fallback.
printf '#!/bin/sh\nexit 0\n' > "$TMP/vmstub/xcrun"; chmod +x "$TMP/vmstub/xcrun"
# curl stub: /getVM answers with one live isolate. No cache file, so the
# getVersion/getIsolate validation path is not reached.
cat > "$TMP/vmstub/curl" <<'CURLV'
#!/bin/sh
for a in "$@"; do case "$a" in http*) u=$a;; esac; done
case "$u" in
  *getVM*) echo '{"result":{"isolates":[{"id":"isolates/123"}]}}' ;;
  *)       echo '{}' ;;
esac
CURLV
chmod +x "$TMP/vmstub/curl"
VMS="bash $REPO/remote/vmservice.sh"

printf 'A Dart VM Service on iPhone 16 Pro is available at: http://127.0.0.1:55407/R-KhdenhVwM=/\n' > "$TMP/frun-test.log"
out=$(PATH="$TMP/vmstub:$PATH" FLUTTER_RUN_LOG="$TMP/frun-test.log" FRUN_LOG="$TMP/none.log" \
      $VMS SIMUDID "$TMP/vmcache" 2>&1)
case "$out" in
  *"55407/R-KhdenhVwM= isolates/123"*) ok "vmservice reads the URI from the flutter run log after the system log has scrolled past it" ;;
  *) no "vmservice reads the URI from the flutter run log after the system log has scrolled past it" "got: $out" ;;
esac

# No log anywhere: the failure must not claim the app is not in debug, which is a
# different thing from no service being found at all.
out=$(PATH="$TMP/vmstub:$PATH" FLUTTER_RUN_LOG="$TMP/none.log" FRUN_LOG="$TMP/none2.log" \
      $VMS SIMUDID "$TMP/vmcache2" 2>&1); rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$out" | grep -q "NOT the same as 'the app is not in debug'"; } \
  && ok "vmservice tells 'no service found' apart from 'not in debug'" \
  || no "vmservice tells 'no service found' apart from 'not in debug'" "rc=$rc: $out"


echo
echo "device build: exact app path, installed-bundle check, and the profile gate (item 45)"
# The device path (profile build via the Aqua session + devicectl install) is
# Mac-only, but stubbing osascript to run its payload directly exercises the
# branch offline. Reuses the mkrepo/pbx harness. A stale wrong-flavour build dir
# is present precisely because the first live run's glob picked one over the
# fresh output.
DVREPO="$TMP/devrepo"; mkrepo "$DVREPO" uat
pbx "$DVREPO" Debug-uat com.example.app.uat
mkdir -p "$DVREPO/build/ios/iphoneos/Runner.app"          # the fresh, correct output
mkdir -p "$DVREPO/build/ios/Debug-dev-iphoneos/Runner.app" # a stale wrong-flavour build
DVSTUB="$TMP/dvstub"; mkdir -p "$DVSTUB"
# osascript: run the do-script payload directly, no GUI, so the build script runs.
cat > "$DVSTUB/osascript" <<'OSA'
#!/bin/sh
for a in "$@"; do last=$a; done
eval "$(printf '%s' "$last" | sed -n 's/.*do script "\(.*\)"$/\1/p')"
OSA
# security cms: decode a profile to a plist covering PROFILE_APPID.
cat > "$DVSTUB/security" <<'SEC'
#!/bin/sh
[ "$1" = cms ] && printf '<key>application-identifier</key>\n<string>TEAMID.%s</string>\n' "${PROFILE_APPID:-com.example.app.uat}"
exit 0
SEC
# xcrun: flutter build produced the app; devicectl install echoes the path it got
# and the bundle id it installed (INSTALL_BUNDLE).
cat > "$DVSTUB/xcrun" <<'XR'
#!/bin/sh
case "$*" in
  *"devicectl device install app"*)
    for a in "$@"; do app=$a; done
    printf 'installing %s\nApp installed:\n bundleID: %s\n' "$app" "${INSTALL_BUNDLE:-com.example.app.uat}" ;;
  *) exit 0 ;;
esac
XR
chmod +x "$DVSTUB/osascript" "$DVSTUB/security" "$DVSTUB/xcrun"
DPROF="$TMP/dvhome/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$DPROF"; : > "$DPROF/x.mobileprovision"
DVB(){ PATH="$DVSTUB:$PATH" HOME="$TMP/dvhome" sh "$REPO/remote/build.sh" \
         --repo "$DVREPO" --app-id com.example.app.uat --flavor uat --device DEVUDID "$@" 2>&1; }

out=$(INSTALL_BUNDLE=com.example.app.uat DVB)
case "$out" in
  *"iphoneos/Runner.app"*"installed  DEVUDID (com.example.app.uat)"*)
    case "$out" in
      *Debug-dev-iphoneos*) no "the device build installs the exact flutter output, not a stale build dir" "picked the stale dir" ;;
      *) ok "the device build installs the exact flutter output, not a stale build dir" ;;
    esac ;;
  *) no "the device build installs the exact flutter output, not a stale build dir" "got: $out" ;;
esac

out=$(INSTALL_BUNDLE=com.example.app.dev DVB); rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$out" | grep -q "not com.example.app.uat"; } \
  && ok "a build that installs the wrong bundle id is caught, not passed (item 45)" \
  || no "a build that installs the wrong bundle id is caught, not passed (item 45)" "rc=$rc: $out"

out=$(PATH="$DVSTUB:$PATH" HOME="$TMP/noprof" sh "$REPO/remote/build.sh" \
        --repo "$DVREPO" --app-id com.example.app.uat --flavor uat --device DEVUDID 2>&1); rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$out" | grep -q "no local provisioning profile"; } \
  && ok "the device build refuses when no profile covers the app (never touches the account)" \
  || no "the device build refuses when no profile covers the app (never touches the account)" "rc=$rc: $out"


echo
echo "build residue in the checkout, told apart from real changes"
# A branch switch on 12 Aug stopped dead on two lock files the session's own
# builds had regenerated. `git status --short` is a flat list, so they looked
# exactly like work someone had done.
if command -v git >/dev/null 2>&1; then
  GR="$TMP/gitrepo"
  git init -q "$GR" 2>/dev/null
  git -C "$GR" config user.email t@t; git -C "$GR" config user.name t
  for f in pubspec.lock ios/Podfile.lock ios/Flutter/Generated.xcconfig lib.dart README.md; do
    mkdir -p "$GR/$(dirname "$f")"; echo one > "$GR/$f"
  done
  git -C "$GR" add -A >/dev/null 2>&1; git -C "$GR" commit -qm first >/dev/null 2>&1
  gs(){ sh -c '. '"$REPO"'/remote/gitstate.sh; gitstate "$1"' _ "$1" 2>&1; }

  out=$(gs "$GR")
  case "$out" in *"tree       clean"*) ok "a clean tree says so" ;;
    *) no "a clean tree says so" "got: $out" ;; esac

  echo two > "$GR/pubspec.lock"; echo two > "$GR/ios/Podfile.lock"
  echo two > "$GR/ios/Flutter/Generated.xcconfig"
  echo two > "$GR/lib.dart"; echo new > "$GR/untracked.txt"
  out=$(gs "$GR" | tr '\n' ' ' | tr -s ' ')
  case "$out" in
    *"changed lib.dart"*) ok "a real edit is listed as a change" ;;
    *) no "a real edit is listed as a change" "got: $out" ;;
  esac
  case "$out" in
    *"residue"*"pubspec.lock"*) ok "a lock file is called build residue" ;;
    *) no "a lock file is called build residue" "got: $out" ;;
  esac
  case "$out" in
    *"residue"*"Generated.xcconfig"*) ok "a generated xcconfig is residue too" ;;
    *) no "a generated xcconfig is residue too" "got: $out" ;;
  esac
  # The distinction is the whole point: a real edit swept in with the lock
  # files would be discarded by the command this prints.
  case "$out" in
    *"checkout --"*"lib.dart"*) no "the discard command covers only the residue" "lib.dart is in it" ;;
    *) ok "the discard command covers only the residue" ;;
  esac
  case "$out" in
    *"untracked 1 file"*) ok "untracked files are counted and excused" ;;
    *) no "untracked files are counted and excused" "got: $out" ;;
  esac
  # zsh ties `path` to PATH, and reading a filename into it emptied PATH for
  # everything that ran after this inside preflight. The Mac's login shell is zsh.
  grep -q 'read -r st _p' "$REPO/remote/gitstate.sh" \
    && ok "the loop variable is not \$path, which zsh ties to \$PATH" \
    || no "the loop variable is not \$path, which zsh ties to \$PATH" "it is back"

  out=$(gs "$TMP/not-a-repo")
  case "$out" in *"not a git checkout"*) ok "a directory that is not a checkout says so" ;;
    *) no "a directory that is not a checkout says so" "got: $out" ;; esac
  out=$(gs "")
  case "$out" in *"REPO not set"*) ok "no REPO says what is missing" ;;
    *) no "no REPO says what is missing" "got: $out" ;; esac
else
  ok "git absent — residue tests skipped"
fi

echo
echo "finding the checkout on the Mac"
# Two URLs for one repository barely look alike, and matching on the directory
# name alone picks the wrong one whenever two repositories share a name.
norm(){ sh -c '
  _norm() { printf "%s" "${1:-}" |
    sed -E "s#^[a-z+]+://##; s#^[^@]+@##; s#:#/#; s#\.git\$##; s#/+\$##" | tr "A-Z" "a-z"; }
  _norm "$1"' _ "$1"; }
a=$(norm 'git@bitbucket.org:acme/brandco-flutter-runner.git')
b=$(norm 'https://bitbucket.org/acme/Brandco-Flutter-Runner')
[ "$a" = "$b" ] && [ "$a" = "bitbucket.org/acme/brandco-flutter-runner" ] \
  && ok "ssh and https forms of one remote match each other" \
  || no "ssh and https forms of one remote match each other" "'$a' vs '$b'"
a=$(norm 'git@github.com:someone/other.git')
[ "$a" = "github.com/someone/other" ] && ok "a different repository does not" \
  || no "a different repository does not" "got '$a'"

# The find has to prune the caches: without it the answer is a screenful of
# .pub-cache clones with the real checkouts lost among them.
for p in .pub-cache node_modules Pods DerivedData Library; do
  grep -q -- "-name $p" "$REPO/remote/findrepo.sh" \
    && ok "findrepo prunes $p" || no "findrepo prunes $p" "not pruned"
done
mkdir -p "$TMP/fakehome/proj/.git" "$TMP/fakehome/.pub-cache/dep/.git"
out=$(HOME="$TMP/fakehome" sh "$REPO/remote/findrepo.sh" 5 2>&1)
case "$out" in
  *"/proj"*) ok "a real checkout is found" ;;
  *) no "a real checkout is found" "got: $out" ;;
esac
case "$out" in
  *pub-cache*) no "a cached clone is not offered as a checkout" "it was listed" ;;
  *) ok "a cached clone is not offered as a checkout" ;;
esac

echo
echo "journeys-first hook (gate a raw coordinate tap once per session)"
# The hook reads a PreToolUse payload on stdin and exits 2 to block, 0 to pass.
# Its marker lives under $TMPDIR keyed by session, so each case gets a fresh one.
HOOK="$REPO/hooks/gate-journey-first.sh"
hk(){ # hk <session> <command-json-string>
  printf '{"session_id":"%s","tool_input":{"command":"%s"}}' "$1" "$2" \
    | TMPDIR="$TMP/hookstate" bash "$HOOK" >/dev/null 2>&1; echo $?
}
mkdir -p "$TMP/hookstate"
[ "$(hk s-tap 'driver.sh tap 293 325')" = 2 ] \
  && ok "a raw driver.sh tap is blocked the first time" \
  || no "a raw driver.sh tap is blocked the first time" "not exit 2"
# Same session, second time: gets out of the way.
hk s-tap 'driver.sh tap 293 325' >/dev/null
[ "$(hk s-tap 'driver.sh tap 40 40')" = 0 ] \
  && ok "the same session is not blocked a second time" \
  || no "the same session is not blocked a second time" "blocked again"
[ "$(hk s-swipe 'driver.sh swipe 100 200 100 500')" = 2 ] \
  && ok "a raw swipe with coordinates is blocked" \
  || no "a raw swipe with coordinates is blocked" "not exit 2"
[ "$(hk s-flag 'driver.sh tap --nodes 200 483')" = 2 ] \
  && ok "a --tree/--nodes flag between verb and coordinates is still caught" \
  || no "a --tree/--nodes flag between verb and coordinates is still caught" "not exit 2"
# The $D form: shell state does not persist between calls, so the assignment
# that defines $D is always in the same command and carries driver.sh with it.
[ "$(hk s-dform 'D=$SKILL/bin/driver.sh; $D tap 179 481')" = 2 ] \
  && ok "the \$D=driver.sh; \$D tap form is caught" \
  || no "the \$D=driver.sh; \$D tap form is caught" "not exit 2"
[ "$(hk s-tapon 'driver.sh tapon "^CONTINUE$"')" = 0 ] \
  && ok "tapon (resolve by label) is not touched" \
  || no "tapon (resolve by label) is not touched" "wrongly blocked"
[ "$(hk s-nondrv 'ls tap 1 2')" = 0 ] \
  && ok "a command without driver.sh is out of scope" \
  || no "a command without driver.sh is out of scope" "wrongly blocked"
# Fail open when the marker cannot be written: a hook that blocks but cannot
# remember it did would ban every raw tap for the session.
printf '{"session_id":"x","tool_input":{"command":"driver.sh tap 1 2"}}' \
  | TMPDIR=/proc/nonexistent-and-unwritable bash "$HOOK" >/dev/null 2>&1
[ $? = 0 ] \
  && ok "an unwritable marker path fails open, not into a ban" \
  || no "an unwritable marker path fails open, not into a ban" "did not exit 0"

echo
echo "device driver: the face-up crash and the recovery invocation (items 50, 46)"
# Both reproduced live on the XS Max, 11 Sep. Offline, a stub _ssh returns a
# canned devdrv.log carrying the ScreenSizeHelper fatal, and a /status that never
# answers forces _start down its recovery path — the path the existing driver.sh
# tests never reach because their stub is always up.
DDIR="$TMP/ddin"; DSTUB="$TMP/dstub"; mkdir -p "$DDIR" "$DSTUB"
cp "$REPO/bin/driver.sh" "$REPO/bin/tree.py" "$REPO/bin/resolve.py" "$REPO/bin/jtok.py" "$DDIR/"
# device.sh WITHOUT an execute bit — the exact condition that broke the item-46
# recovery. driver.sh must call it with `bash`, not the bare path.
printf '#!/usr/bin/env bash\necho ran > "$DEVMARK"\n' > "$DDIR/device.sh"
chmod -x "$DDIR/device.sh" 2>/dev/null || true
echo "stub 1 device" > "$DDIR/devmap"   # _is_device greps "^$DEV " -> "stub "
cat > "$DDIR/lib.sh" <<LIBSH
MAC_HOST=stub; MAC_FQDN=stub.invalid; APP_ID=test.app; DEV=stub; DPORT=1; DRIVER_PORT=1
DRIVER_PORT_BASE=1; RDIR=$TMP/none; JOURNEY_DIR=$TMP/none; SSH_OPTS=(-o X=y)
DEVICE_MAP=$DDIR/devmap
_driver_bind(){ return 0; }
_rebind(){ return 1; }
_ssh(){ echo "ScreenSizeHelper.swift:99: Fatal error: Not implemented yet"; return 0; }
LIBSH
printf '#!/usr/bin/env bash\nfor a in "$@";do case "$a" in http*) u=$a;; esac;done\ncase "$u" in */status) printf 500;; *) printf "{}";; esac\n' > "$DSTUB/curl"
printf '#!/usr/bin/env bash\nexit 0\n' > "$DSTUB/scp"
chmod +x "$DSTUB/curl" "$DSTUB/scp"
rm -f "$TMP/devmark"
dout=$(DEVMARK="$TMP/devmark" PATH="$DSTUB:$PATH" timeout 30 bash "$DDIR/driver.sh" nodes 2>&1)
case "$dout" in
  *"FACE-UP crash (item 50)"*) ok "a ScreenSizeHelper fatal in devdrv.log is named as the face-up crash, not a relay fault" ;;
  *) no "a ScreenSizeHelper fatal in devdrv.log is named as the face-up crash, not a relay fault" "got: $(printf '%s' "$dout" | tail -3)" ;;
esac
[ "$(cat "$TMP/devmark" 2>/dev/null)" = ran ] \
  && ok "the item-46 recovery calls device.sh through bash, so a non-executable device.sh still restarts" \
  || no "the item-46 recovery calls device.sh through bash, so a non-executable device.sh still restarts" "marker not written — recovery did not run device.sh"
case "$dout" in
  *"XCTest session dying"*) no "the face-up hint replaces the misleading XCTest-death message" "both were printed" ;;
  *) ok "the face-up hint replaces the misleading XCTest-death message" ;;
esac

echo
echo "the wall: MJPEG framing and the booted-device list (items 64, 65)"
# The two pieces of remote/wall.py that are pure logic. Everything else in it
# needs a Mac and a simulator, so it is exercised by running it, not here.
wall_out=$(python3 - "$REPO/remote/wall.py" <<'PYEOF'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("wall", sys.argv[1])
w = importlib.util.module_from_spec(spec); spec.loader.exec_module(w)

def check(name, fn):
    """One case. An exception fails THIS case and nothing else.

    The whole block is one python run printing a named result per line, which
    the shell loop below then checks by name. Without this, a raise part-way
    through prints nothing for every later name and the loop reports them all
    as failures of their own — which is how one date-sensitive assertion was
    read as ten broken behaviours (item 86).
    """
    try:
        print(name, fn())
    except Exception as exc:
        print(name, "False", "%s: %s" % (type(exc).__name__, exc))


def part(body):
    return b"--NextFrame\r\nContent-Type:image/jpeg\r\n\r\n" + body + b"\r\n"

# a frame is only complete once the NEXT boundary has arrived
frames, rest = w.split_frames(part(b"AAA") + b"--NextFrame\r\nContent-Type:image/jpeg\r\n\r\nBB")
check("one-complete", lambda: frames == [b"AAA"])
check("partial-kept", lambda: rest.startswith(b"--NextFrame") and rest.endswith(b"BB"))

# several in one read
frames, rest = w.split_frames(part(b"1") + part(b"22") + part(b"333") + b"--NextFrame\r\nContent-Type:image/jpeg\r\n\r\n")
check("three", lambda: frames == [b"1", b"22", b"333"])

# a boundary split across two reads must not lose the frame
buf = part(b"XY") + b"--Next"
frames, buf = w.split_frames(buf)
check("split-boundary-waits", lambda: frames == [])
frames, buf = w.split_frames(buf + b"Frame\r\nContent-Type:image/jpeg\r\n\r\n")
check("split-boundary-then-emits", lambda: frames == [b"XY"])

# nothing at all, and rubbish, are both survivable
check("empty", lambda: w.split_frames(b"") == ([], b""))
check("rubbish", lambda: w.split_frames(b"not multipart at all") == ([], b"not multipart at all"))

# simctl lists every runtime it knows, nearly all of them empty
data = {"devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-18-6": [
        {"udid": "B" * 36, "name": "iPhone 16", "state": "Booted"},
        {"udid": "C" * 36, "name": "iPhone 16 Pro", "state": "Shutdown"},
    ],
    "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [],
    "com.apple.CoreSimulator.SimRuntime.iOS-15-5": [
        {"udid": "A" * 36, "name": "iPhone 8", "state": "Booted"},
    ],
}}
got = w.parse_booted(data)
check("booted-only", lambda: [n for _, n in got] == ["iPhone 8", "iPhone 16"])
check("empty-runtimes", lambda: w.parse_booted({"devices": {}}) == [])
check("no-key", lambda: w.parse_booted({}) == [])

# labels: written by whoever drives, read by the wall, never posted to it
import os, tempfile, time
w.LABELS = tempfile.mkdtemp()
lab = w.parse_label("name=Checkout flow, PR 101\ngroup=brandco\n")
check("label-basic", lambda: lab == {"name": "Checkout flow, PR 101", "group": "brandco"})
# a name with an = in it keeps the rest of the line
check("label-equals", lambda: w.parse_label("name=a=b")["name"] == "a=b")
# comments, blanks, unknown keys and junk are all ignored rather than fatal
check("label-junk", lambda: w.parse_label("# c\n\nnope\nGROUP= g \ncolour=red")["group"] == "g")
check("label-none", lambda: w.parse_label("") == {})

udid = "D" * 36
check("label-missing", lambda: w.read_label(udid) == {})
with open(os.path.join(w.LABELS, udid), "w") as fh:
    fh.write("name=Fresh\ngroup=\n")
got = w.read_label(udid)
check("label-read", lambda: got["name"] == "Fresh" and got["stale"] is False and got["age"] < 5)
# a label nobody has touched for an hour is shown as stale rather than expired.
# Day-hiding is suppressed for this one case: it is a separate behaviour with
# its own cases below, and leaving it on means that between midnight and 02:00
# "two hours ago" is yesterday, the label is hidden rather than stale, and the
# case raises instead of failing (item 86).
old_path = os.path.join(w.LABELS, udid)
os.utime(old_path, (time.time() - 7200, time.time() - 7200))
_hide = w.HIDE_FROM_PREVIOUS_DAY
w.HIDE_FROM_PREVIOUS_DAY = False
check("label-stale", lambda: w.read_label(udid)["stale"] is True)
w.HIDE_FROM_PREVIOUS_DAY = _hide
# an empty file is not a label
with open(os.path.join(w.LABELS, "E" * 36), "w") as fh:
    fh.write("")
check("label-empty-file", lambda: w.read_label("E" * 36) == {})

# who wrote it. A label written before `by` existed must still read cleanly,
# so its absence is a blank rather than a missing key.
check("label-by", lambda: w.parse_label("name=N\nby=purple \u00b7 3fa41c7")["by"] == "purple \u00b7 3fa41c7")
check("label-no-by", lambda: "by" not in w.parse_label("name=N\ngroup=G"))

# A name from an earlier CALENDAR DAY is hidden, not merely greyed (item 67
# piece 4). Nothing removes a label at session end, so a device nobody picks up
# again would otherwise keep its name for good — the wall showed four of those
# on 16 Sep 2026, none of them working.
import datetime
udid2 = "D" * 36
with open(os.path.join(w.LABELS, udid2), "w") as fh:
    fh.write("name=Yesterday\nby=cyan \u00b7 1111111")
p2 = os.path.join(w.LABELS, udid2)

# 10 minutes old, same day -> shown, and not yet greyed
check("day-today-fresh", lambda: w.read_label(udid2).get("name") == "Yesterday")
check("day-today-not-stale", lambda: w.read_label(udid2)["stale"] is False)

# 3 hours old but STILL TODAY -> shown, greyed. A long-running session must not
# lose its name just for going quiet.
now = time.time()
same_day_3h = now - 3 * 3600
if time.localtime(same_day_3h).tm_yday == time.localtime(now).tm_yday:
    os.utime(p2, (same_day_3h, same_day_3h))
    check("day-today-old-kept", lambda: w.read_label(udid2).get("name") == "Yesterday")
    check("day-today-old-greyed", lambda: w.read_label(udid2)["stale"] is True)
else:
    # run started within 3h of midnight; the case is covered by the next one
    check("day-today-old-kept", lambda: True)
    check("day-today-old-greyed", lambda: True)

# yesterday, whatever the hour -> hidden entirely
y = datetime.datetime.now() - datetime.timedelta(days=1)
ts = y.timestamp()
os.utime(p2, (ts, ts))
check("day-yesterday-hidden", lambda: w.read_label(udid2) == {})

# and a name only 10 hours old is still hidden if it crossed midnight, which is
# the whole point of doing this by day rather than by hours
midnight = datetime.datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
late = (midnight - datetime.timedelta(hours=1)).timestamp()
os.utime(p2, (late, late))
check("day-crossed-midnight-hidden", lambda: w.read_label(udid2) == {})
PYEOF
)
for line in one-complete partial-kept three split-boundary-waits split-boundary-then-emits empty rubbish booted-only empty-runtimes no-key label-basic label-equals label-junk label-none label-missing label-read label-stale label-empty-file label-by label-no-by day-today-fresh day-today-not-stale day-today-old-kept day-today-old-greyed day-yesterday-hidden day-crossed-midnight-hidden; do
  case "$wall_out" in
    *"$line True"*) ok "wall.py: $line" ;;
    *)              no "wall.py: $line" "$(printf '%s' "$wall_out" | grep "^$line " || echo 'no result')" ;;
  esac
done

echo "reading a list off the screen (item 72)"
rows_ipad=$($R "." $IPAD --rows < "$FIX/ipad-landscape-keyboard-up.json" 2>/dev/null)

# draw order, not walk order: every y must be >= the one before it
echo "$rows_ipad" | sed 1d | awk '{split($3,f,","); print f[2]+0}' \
  | awk 'NR>1 && $1 < prev { bad=1 } { prev=$1 } END { exit bad?1:0 }' \
  && ok "rows: draw order, top to bottom" \
  || no "rows: draw order, top to bottom" "a y went backwards"

# the count line is the first line and agrees with the rows printed
n=$(echo "$rows_ipad" | sed -n '1s/^n=//p')
printed=$(echo "$rows_ipad" | sed 1d | grep -c .)
[ -n "$n" ] && [ "$n" = "$printed" ] \
  && ok "rows: n= agrees with the rows printed" \
  || no "rows: n= agrees with the rows printed" "n=$n, printed=$printed"

# an empty list is a result, not an error — this is the case a watcher needs,
# because a list that has emptied IS the finding
empty=$($R "ZZZ-NOTHING-MATCHES-THIS" $IPAD --rows < "$FIX/ipad-landscape-keyboard-up.json" 2>/dev/null)
rc=$?
[ "$rc" = 0 ] && [ "$empty" = "n=0" ] \
  && ok "rows: no match exits 0 with n=0" \
  || no "rows: no match exits 0 with n=0" "rc=$rc out='$empty'"

# ... whereas every other mode still treats no match as an error
$R "ZZZ-NOTHING-MATCHES-THIS" $IPAD --point < "$FIX/ipad-landscape-keyboard-up.json" >/dev/null 2>&1
[ "$?" = 3 ] && ok "rows: --point still fails on no match" \
              || no "rows: --point still fails on no match" "expected rc 3"

# the keyboard fixture has nodes under the keyboard, so kbd must appear, and
# every visibility token must be one of the four
echo "$rows_ipad" | sed 1d | grep -q " kbd " \
  && ok "rows: nodes under the keyboard are marked kbd" \
  || no "rows: nodes under the keyboard are marked kbd" "no kbd token"
bad_tok=$(echo "$rows_ipad" | sed 1d | awk '{print $2}' | grep -vE '^(vis|off|kbd|zero)$' | head -1)
[ -z "$bad_tok" ] && ok "rows: visibility tokens are vis/off/kbd/zero" \
                  || no "rows: visibility tokens are vis/off/kbd/zero" "saw '$bad_tok'"

# --json parses, is an array, and carries the same count
json=$($R "." $IPAD --rows --json < "$FIX/ipad-landscape-keyboard-up.json" 2>/dev/null)
echo "$json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert isinstance(d,list) and d, "not a non-empty list"
assert set(d[0]) == {"i","text","vis","frame","centre","enabled"}, d[0].keys()
assert [m["i"] for m in d] == list(range(len(d))), "indices not contiguous"
' 2>/dev/null && ok "rows: --json shape" || no "rows: --json shape" "bad or unparseable JSON"
[ "$(echo "$json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null)" = "$n" ] \
  && ok "rows: --json count matches the text mode" \
  || no "rows: --json count matches the text mode" "differs from n=$n"

echo "a detached helper finds the project conf (item 71)"
cdir="$TMP/conf71"; mkdir -p "$cdir/proj/deep/er" "$cdir/ld" "$cdir/ld-empty" "$cdir/home"
cat > "$cdir/proj/.maestro-mac.conf" <<'CONF'
: "${MAC_HOST:=mac-test}"
: "${MAC_FQDN:=test.local}"
: "${APP_ID:=com.example.item71}"
CONF

# found by walking up from $PWD, as it always was — and remembered
got=$(cd "$cdir/proj/deep/er" && HOME="$cdir/home" LDIR="$cdir/ld" \
      bash -c '. "'"$REPO"'/bin/config.sh" && echo "$APP_ID"' 2>/dev/null)
[ "$got" = "com.example.item71" ] && ok "conf: upward search still works" \
                                  || no "conf: upward search still works" "got '$got'"
[ "$(cat "$cdir/ld/conf-path" 2>/dev/null)" = "$cdir/proj/.maestro-mac.conf" ] \
  && ok "conf: a step-2 find is remembered in \$LDIR" \
  || no "conf: a step-2 find is remembered in \$LDIR" "cache holds '$(cat "$cdir/ld/conf-path" 2>/dev/null)'"

# the case this exists for: started detached, nowhere near the project
got=$(cd / && HOME="$cdir/home" LDIR="$cdir/ld" \
      bash -c '. "'"$REPO"'/bin/config.sh" && echo "$APP_ID"' 2>/dev/null)
[ "$got" = "com.example.item71" ] && ok "conf: a detached cwd falls back to the cache" \
                                  || no "conf: a detached cwd falls back to the cache" "got '$got'"

# with no cache it must still refuse, and say why a detached process fails
out=$(cd / && HOME="$cdir/home" LDIR="$cdir/ld-empty" \
      bash -c '. "'"$REPO"'/bin/config.sh"' 2>&1)
case "$out" in
  *"not configured for this project"*) ok "conf: no cache still refuses" ;;
  *) no "conf: no cache still refuses" "did not refuse" ;;
esac
case "$out" in
  *"started detached"*) ok "conf: the refusal names the detached case" ;;
  *) no "conf: the refusal names the detached case" "no detached hint in the message" ;;
esac

# a cached path that has since gone must not be trusted
rm -f "$cdir/proj/.maestro-mac.conf"
out=$(cd / && HOME="$cdir/home" LDIR="$cdir/ld" \
      bash -c '. "'"$REPO"'/bin/config.sh"' 2>&1)
case "$out" in
  *"not configured for this project"*) ok "conf: a stale cache entry is not trusted" ;;
  *) no "conf: a stale cache entry is not trusted" "accepted a conf that no longer exists" ;;
esac

echo "the swipe route is swipeV2, not swipe (item 69)"
# All three call sites — the CLI verb, the journey verb and _scrollto — must
# post swipeV2. /swipe answers 200 and does nothing, so a leftover here is a
# scroll that silently moves nothing and reports success.
[ "$(grep -c '_post swipeV2 ' "$REPO/bin/driver.sh")" = 3 ] \
  && ok "swipe: all three call sites post swipeV2" \
  || no "swipe: all three call sites post swipeV2" "found $(grep -c '_post swipeV2 ' "$REPO/bin/driver.sh")"
grep -q '_post swipe ' "$REPO/bin/driver.sh" \
  && no "swipe: no call site posts the dead /swipe route" "a bare '_post swipe' remains" \
  || ok "swipe: no call site posts the dead /swipe route"
grep -q 'swipeV2' "$REPO/reference/driver-api.md" \
  && ok "swipe: driver-api.md documents swipeV2" \
  || no "swipe: driver-api.md documents swipeV2" "reference still says swipe works"

echo "watching a list change (item 70)"
W="$TMP/watch"; mkdir -p "$W"
# A stub row source: a different sample per call, with a failed read in the
# middle. Nothing here touches a device.
cat > "$W/stub.sh" <<'STUB'
#!/bin/bash
n=$(cat "$1" 2>/dev/null || echo 0); echo $((n+1)) > "$1"
case $n in
  0|1) echo '[{"i":0,"text":"A","vis":"vis"},{"i":1,"text":"B","vis":"vis"},{"i":2,"text":"C","vis":"vis"}]' ;;
  2)   echo "driver gone" >&2; exit 1 ;;
  3)   echo '[{"i":0,"text":"A","vis":"vis"},{"i":1,"text":"B","vis":"vis"},{"i":2,"text":"C","vis":"vis"}]' ;;
  4)   echo '[{"i":0,"text":"A","vis":"vis"},{"i":1,"text":"D","vis":"vis"}]' ;;
  *)   echo '[]' ;;
esac
STUB
chmod +x "$W/stub.sh"; echo 0 > "$W/n"
wout=$(python3 "$REPO/bin/watch.py" --rows-cmd "$W/stub.sh $W/n" --interval 0.05 \
         --cycles 6 --log "$W/log" --claim-file "$W/claim" --stop-file "$W/stop" 2>&1)

echo "$wout" | grep -q "ERR  rows rc=1 driver gone" \
  && ok "watch: a failed read logs ERR" \
  || no "watch: a failed read logs ERR" "no ERR line"

# The one that matters: the sample after an ERR is identical to the one before
# it, so if the ERR had overwritten the baseline there would be a false CHANGE.
[ "$(echo "$wout" | grep -c '>>> CHANGE')" = 2 ] \
  && ok "watch: an ERR does not become a change" \
  || no "watch: an ERR does not become a change" "$(echo "$wout" | grep -c '>>> CHANGE') changes, expected 2"

echo "$wout" | grep -q "added=\['D'\] removed=\['B', 'C'\]" \
  && ok "watch: names what arrived and what left" \
  || no "watch: names what arrived and what left" "$(echo "$wout" | grep '>>> CHANGE' | head -1)"

# a list that has emptied is the finding, so it must be a change with n=0
echo "$wout" | grep -q "OK n=0" && echo "$wout" | grep -q "removed=\['A', 'D'\]" \
  && ok "watch: an emptied list is a change, not silence" \
  || no "watch: an emptied list is a change, not silence" "no n=0 change"

# the claim is cleared on a clean exit, so a later call can tell it is over
[ ! -e "$W/claim" ] && ok "watch: the claim is cleared on a clean exit" \
                    || no "watch: the claim is cleared on a clean exit" "claim still there"

# counted, not set-based: four rows reading the same text is a real screen
python3 - "$REPO/bin/watch.py" <<'PYW' >/dev/null 2>&1
import importlib.util, sys
spec = importlib.util.spec_from_file_location("w", sys.argv[1])
w = importlib.util.module_from_spec(spec); spec.loader.exec_module(w)
was = [("S", "vis"), ("S", "off"), ("S", "off")]
now = [("S", "vis"), ("S", "vis"), ("S", "vis"), ("S", "off")]
a, r, m = w.diff(was, now)
assert a == ["S"], ("added", a)
assert r == [], ("removed", r)
assert w.diff(was, was) == ([], [], []), "identical samples differ"
assert w.diff([("A", "vis")], []) == ([], ["A"], []), "emptying not reported"
assert w.diff([("A", "vis")], [("A", "off")]) == ([], [], ["A"]), "visibility change"
PYW
[ "$?" = 0 ] && ok "watch: the diff counts duplicates rather than testing membership" \
             || no "watch: the diff counts duplicates rather than testing membership" "see diff()"

# a stop file ends the run, and a stale one from a previous run does not kill
# the next before it has taken a sample
echo 0 > "$W/n2"; : > "$W/stop2"
wout2=$(python3 "$REPO/bin/watch.py" --rows-cmd "$W/stub.sh $W/n2" --interval 0.05 \
          --cycles 3 --log "$W/log2" --stop-file "$W/stop2" 2>&1)
echo "$wout2" | grep -q "^0001 " \
  && ok "watch: a stale stop file does not kill the next run" \
  || no "watch: a stale stop file does not kill the next run" "took no samples"

echo "the watcher lock survives the PID namespace (item 70)"
# A pid cannot be the lock: every Bash call has its own PID namespace, so a pid
# from one call is meaningless to the next. Liveness is the log's mtime.
grep -q '_WATCH_CLAIM' "$REPO/bin/driver.sh" && ! grep -q '_WATCH_PID' "$REPO/bin/driver.sh" \
  && ok "watch: liveness is a claim plus log mtime, not a pid file" \
  || no "watch: liveness is a claim plus log mtime, not a pid file" "a pid file is still in use"
grep -q 'kill -0' "$REPO/bin/driver.sh" \
  && no "watch: nothing tests liveness with kill -0" "kill -0 is back in driver.sh" \
  || ok "watch: nothing tests liveness with kill -0"

echo "a device keeps its driver port (item 73)"
# The seam is _port_for alone: live map, remembered map, and what it hands back.
# _ports_remember would go over SSH, so it is stubbed to a file here.
pf(){ # pf <udid> <live-map> <ports-map>
  ( DRIVER_PORT_BASE=22087; REMEMBERED="$TMP/remembered"
    _ports_remember(){ echo "$1 $2" >> "$REMEMBERED"; }
    source <(sed -n '/^_port_for()/,/^}/p' "$REPO/bin/drivers.sh")
    _port_for "$1" "$2" "$3" )
}
: > "$TMP/remembered"

# nothing known yet: the first device takes 22087, the port Maestro insists on
[ "$(pf A "" "")" = 22087 ] && ok "ports: the first device takes 22087" \
                            || no "ports: the first device takes 22087" "got $(pf A "" "")"

# THE CASE THIS ITEM EXISTS FOR. B is remembered on 22088. A's driver has died,
# so 22087 is free — under the old lowest-free rule B would be handed 22087,
# which is exactly how an iPad came back on an iPhone's port on 16 Sep.
[ "$(pf B "" "A 22087
B 22088")" = 22088 ] \
  && ok "ports: a device whose driver died comes back on its own port" \
  || no "ports: a device whose driver died comes back on its own port" "got $(pf B "" "A 22087
B 22088")"

# and it must not be handed a port another device is remembered on, even when
# no driver is live on it
[ "$(pf C "" "A 22087
B 22088")" = 22089 ] \
  && ok "ports: a new device skips ports others are remembered on" \
  || no "ports: a new device skips ports others are remembered on" "got $(pf C "" "A 22087
B 22088")"

# nor one a live driver is sitting on
[ "$(pf D "X 22087 111
Y 22088 222" "")" = 22089 ] \
  && ok "ports: a new device skips live drivers" \
  || no "ports: a new device skips live drivers" "got $(pf D "X 22087 111
Y 22088 222" "")"

# a remembered port that something else has actually taken is given up rather
# than fought over — correctness beats stickiness
[ "$(pf E "Z 22087 999" "E 22087")" = 22088 ] \
  && ok "ports: a remembered port that is occupied is given up" \
  || no "ports: a remembered port that is occupied is given up" "got $(pf E "Z 22087 999" "E 22087")"

# a device sitting on its own remembered port keeps it (its own live entry must
# not read as someone else occupying it)
[ "$(pf F "F 22090 777" "F 22090")" = 22090 ] \
  && ok "ports: a device already on its remembered port keeps it" \
  || no "ports: a device already on its remembered port keeps it" "got $(pf F "F 22090 777" "F 22090")"

# every new assignment is written down, so it is the last time that port moves
grep -q "^A 22087$" "$TMP/remembered" && grep -q "^C 22089$" "$TMP/remembered" \
  && ok "ports: a new assignment is remembered" \
  || no "ports: a new assignment is remembered" "$(cat "$TMP/remembered" | tr '\n' ' ')"
# ... and a port that was simply recalled is not rewritten
[ "$(grep -c '^B ' "$TMP/remembered" || true)" = 0 ] \
  && ok "ports: recalling a port does not rewrite it" \
  || no "ports: recalling a port does not rewrite it" "B was written again"

grep -q '_free_port' "$REPO/bin/drivers.sh" \
  && no "ports: the lowest-free allocator is gone" "_free_port is still there" \
  || ok "ports: the lowest-free allocator is gone"

echo "the rig (item 76)"
rigfn(){ ( RDIR=/tmp/maestro-mac
           CLAUDE_SESSION_COLOUR=teal CLAUDE_CODE_SESSION_ID=abcdef1234
           source <(sed -n '/^_label_by()/,/^}/p' "$REPO/bin/lib.sh")
           RIG_OWNED="$RDIR/rig"
           source <(sed -n '/^_rig_devices()/,/^}/p' "$REPO/bin/drivers.sh")
           source <(sed -n '/^_rig_mine()/,/^}/p' "$REPO/bin/drivers.sh")
           "$@" ) }

# devices come from the arguments first
[ "$(rigfn _rig_devices AAA BBB | tr '\n' ' ')" = "AAA BBB " ] \
  && ok "rig: named devices win" || no "rig: named devices win" "got $(rigfn _rig_devices AAA BBB | tr '\n' ' ')"
# then RIG_DEVICES from the conf
[ "$(RIG_DEVICES='CCC DDD' rigfn _rig_devices | tr '\n' ' ')" = "CCC DDD " ] \
  && ok "rig: RIG_DEVICES is the fallback" || no "rig: RIG_DEVICES is the fallback" "wrong"
# and with neither it must refuse rather than pick something
rigfn _rig_devices >/dev/null 2>&1 \
  && no "rig: no devices is a refusal, not a guess" "returned success" \
  || ok "rig: no devices is a refusal, not a guess"

# the claim file is per SESSION, so one session's teardown cannot reach another's
m1=$(rigfn _rig_mine)
m2=$( ( RDIR=/tmp/maestro-mac; CLAUDE_SESSION_COLOUR=rose; CLAUDE_CODE_SESSION_ID=9999999zz
        source <(sed -n '/^_label_by()/,/^}/p' "$REPO/bin/lib.sh")
        RIG_OWNED="$RDIR/rig"
        source <(sed -n '/^_rig_mine()/,/^}/p' "$REPO/bin/drivers.sh")
        _rig_mine ) )
[ -n "$m1" ] && [ "$m1" != "$m2" ] \
  && ok "rig: each session claims into its own file" \
  || no "rig: each session claims into its own file" "$m1 vs $m2"
# and that file name must be safe to put in a shell command
case "$m1" in
  *[!A-Za-z0-9./_-]*) no "rig: the claim path has no shell-unsafe characters" "$m1" ;;
  *) ok "rig: the claim path has no shell-unsafe characters" ;;
esac

# rig down must only ever act on the claim file, never on the booted list
sed -n '/^_rig_down()/,/^}/p' "$REPO/bin/drivers.sh" | grep -q '_rig_claimed' \
  && ok "rig: teardown reads the claim, not the booted list" \
  || no "rig: teardown reads the claim, not the booted list" "no _rig_claimed"
sed -n '/^_rig_down()/,/^}/p' "$REPO/bin/drivers.sh" | grep -q '_booted\|down-all' \
  && no "rig: teardown never walks every booted device" "it reads the booted list" \
  || ok "rig: teardown never walks every booted device"

# boots are serialised and waited out (item 74), so _rig_up must settle in the
# same loop that boots, and start drivers only afterwards
rigup=$(sed -n '/^_rig_up()/,/^}/p' "$REPO/bin/drivers.sh")
echo "$rigup" | grep -q '_rig_settle' && ok "rig: a boot is waited out" \
                                      || no "rig: a boot is waited out" "no _rig_settle"
[ "$(echo "$rigup" | grep -n '_rig_settle' | cut -d: -f1)" -lt "$(echo "$rigup" | grep -n '_up_one' | cut -d: -f1)" ] \
  && ok "rig: every boot settles before any driver starts" \
  || no "rig: every boot settles before any driver starts" "drivers start inside the boot loop"

# a device the rig booted gets its wall label written OVER — the stale-label
# half of item 67. _label_default deliberately never overwrites.
sed -n '/^_rig_rename()/,/^}/p' "$REPO/bin/drivers.sh" | grep -q "cat > '\$RDIR/labels" \
  && ok "rig: a booted device is renamed, not merely filled in if blank" \
  || no "rig: a booted device is renamed, not merely filled in if blank" "still conditional"

echo "a wedged simulator answers every tap with success (item 75)"
wcheck(){ ( _WEDGE_SEEN=${1:-0}
        source <(sed -n '/^_wedge_check()/,/^}/p' "$REPO/bin/driver.sh")
        _WEDGE_SEEN=${1:-0}
        _wedge_check "$2" "$3" 2>&1; echo "seen=$_WEDGE_SEEN" ) }
# one identical pair is not enough — a static screen is normal
out=$(wcheck 0 "TREE" "TREE")
case "$out" in *"seen=1"*) ok "wedge: one identical pair only counts it" ;;
               *) no "wedge: one identical pair only counts it" "$out" ;; esac
# two in a row is the signature, and it says what to do
out=$(wcheck 1 "TREE" "TREE")
case "$out" in *"dead touch injection"*) ok "wedge: two in a row warns" ;;
               *) no "wedge: two in a row warns" "$out" ;; esac
case "$out" in *"probe"*) ok "wedge: the warning names the probe" ;;
               *) no "wedge: the warning names the probe" "no probe in message" ;; esac
# a screen that changed resets the count, so an intermittent pair never adds up
out=$(wcheck 1 "TREE" "DIFFERENT")
case "$out" in *"seen=0"*) ok "wedge: a changed screen resets the count" ;;
               *) no "wedge: a changed screen resets the count" "$out" ;; esac
# the probe must refuse to claim a pass it cannot prove
sed -n '/^_probe()/,/^}/p' "$REPO/bin/driver.sh" | grep -q "did not change" \
  && ok "wedge: the probe reports an inconclusive result as inconclusive" \
  || no "wedge: the probe reports an inconclusive result as inconclusive" "claims a pass"

echo "composing journey units without a file (item 77)"
steps=$(printf '%s\n' 'tapon "^A$"; expect "^B$";; settle' | tr ';' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$')
[ "$(printf '%s\n' "$steps" | wc -l | tr -d ' ')" = 3 ] \
  && ok "steps: ';' splits, blanks and padding are dropped" \
  || no "steps: ';' splits, blanks and padding are dropped" "got: $steps"
grep -q 'script --steps' "$REPO/bin/driver.sh" && grep -q 'steps-XXXXXX.journey' "$REPO/bin/driver.sh" \
  && ok "steps: script --steps exists and builds a throwaway journey" \
  || no "steps: script --steps exists and builds a throwaway journey" "missing"
sed -n '/--steps/,/^            fi/p' "$REPO/bin/driver.sh" | grep -q 'rm -f "\$_tmp_journey"' \
  && ok "steps: the throwaway is removed" \
  || no "steps: the throwaway is removed" "left behind"

echo "the app notes are measured (item 78)"
grep -q 'NOTES_WARN_LINES' "$REPO/bin/preflight.sh" \
  && ok "notes: preflight prints the size against a threshold" \
  || no "notes: preflight prints the size against a threshold" "not measured"
grep -q '  archive)' "$REPO/bin/notes.sh" \
  && ok "notes: there is an archive path" || no "notes: there is an archive path" "missing"
# archive must never move anything on its own — losing a live note is worse
# than a long file
sed -n '/^  archive)/,/^    ;;/p' "$REPO/bin/notes.sh" | grep -qE '^\s*(mv|sed -i|rm) ' \
  && no "notes: archive moves nothing by itself" "it edits the notes" \
  || ok "notes: archive moves nothing by itself"

echo "a journey edit that does not match must be loud (item 83)"
JD="$TMP/jed"; mkdir -p "$JD/maestro/journeys"
cat > "$JD/.maestro-mac.conf" <<'CONF'
: "${MAC_HOST:=mac-test}"
: "${MAC_FQDN:=test.local}"
: "${APP_ID:=com.example.t}"
CONF
mkj(){ printf 'launch\ntapon "^Select Store$"\ntext "${STORE}"\ndismiss\ntapon "^SUBMIT$"\n' \
         > "$JD/maestro/journeys/x.journey"; }
jed(){ ( cd "$JD" && MAESTRO_MAC_CONF="$JD/.maestro-mac.conf" \
         bash "$REPO/bin/journey.sh" "$@" 2>&1 ) }

mkj; jed edit x.journey --replace-once 'dismiss' 'settle' >/dev/null 2>&1
grep -q '^settle$' "$JD/maestro/journeys/x.journey" \
  && ok "journey: a matching replace is written" \
  || no "journey: a matching replace is written" "not written"

# THE ITEM. The old idiom rewrote the file unchanged and reported success.
mkj; before=$(cat "$JD/maestro/journeys/x.journey")
# genuinely absent — note 'dismis' would NOT do: it is a substring of 'dismiss'
# and matches, which is correct behaviour and cost this test a false failure
out=$(jed edit x.journey --replace-once 'hideKeyboard' 'settle'); rc=$?
[ "$rc" = 3 ] && ok "journey: a no-match exits non-zero" \
              || no "journey: a no-match exits non-zero" "rc=$rc"
[ "$before" = "$(cat "$JD/maestro/journeys/x.journey")" ] \
  && ok "journey: a no-match writes nothing" || no "journey: a no-match writes nothing" "file changed"
case "$out" in *"did NOT happen"*) ok "journey: a no-match says so plainly" ;;
               *) no "journey: a no-match says so plainly" "$out" ;; esac

# ambiguity is the other silent corruption: replacing the first of several
mkj; out=$(jed edit x.journey --replace-once 'tapon' 'TAPON'); rc=$?
[ "$rc" = 4 ] && ok "journey: an ambiguous match refuses" || no "journey: an ambiguous match refuses" "rc=$rc"
grep -q 'TAPON' "$JD/maestro/journeys/x.journey" \
  && no "journey: an ambiguous match writes nothing" "it replaced one" \
  || ok "journey: an ambiguous match writes nothing"

# the usual cause of a miss is whitespace, so the hint must show it rather than
# print both sides stripped and identical
mkj; out=$(jed edit x.journey --replace-once 'tapon "^SUBMIT$" ' 'x')
case "$out" in *"differ only in whitespace"*) ok "journey: a whitespace-only miss is named as one" ;;
               *) no "journey: a whitespace-only miss is named as one" "$out" ;; esac

mkj; before=$(cat "$JD/maestro/journeys/x.journey")
out=$(jed edit x.journey --replace-once 'launch' 'kill' --dry); rc=$?
[ "$rc" = 0 ] && [ "$before" = "$(cat "$JD/maestro/journeys/x.journey")" ] \
  && ok "journey: --dry shows the diff and writes nothing" \
  || no "journey: --dry shows the diff and writes nothing" "rc=$rc"

# a bare name resolves in the project's journey directory, like driver.sh script
mkj; jed edit x.journey --replace-once 'launch' 'kill' >/dev/null 2>&1
grep -q '^kill$' "$JD/maestro/journeys/x.journey" \
  && ok "journey: a bare name resolves in JOURNEY_DIR" \
  || no "journey: a bare name resolves in JOURNEY_DIR" "not resolved"

echo "a dead session's wall label is reclaimed, a live one is not (item 67)"
# The decision is made by the remote shell, so test the shell script it sends
# rather than mocking ssh: same conditions, same order.
LB="$TMP/labels"; mkdir -p "$LB"
reclaim(){ # reclaim <label-contents> <mine> <live-port-or-empty> <age-secs> -> WROTE|KEPT
  local L="$LB/dev"; printf '%s' "$1" > "$L"
  touch -d "@$(( $(date +%s) - $4 ))" "$L" 2>/dev/null || touch -t "$(date -d @$(( $(date +%s) - $4 )) +%Y%m%d%H%M.%S)" "$L"
  ( MINE=$2; PORT=$3; STALE=3600
    if [ ! -s "$L" ]; then echo WROTE; exit 0; fi
    if grep -qF "by=$MINE" "$L" 2>/dev/null; then echo KEPT; exit 0; fi
    if [ -n "$PORT" ]; then echo KEPT; exit 0; fi
    AGE=$(( $(date +%s) - $(stat -c %Y "$L") ))
    if [ "$AGE" -gt "$STALE" ]; then echo WROTE; else echo KEPT; fi )
}
[ "$(reclaim "" "blue · aaa" "" 0)" = WROTE ] \
  && ok "label: a blank is filled" || no "label: a blank is filled" "not filled"
[ "$(reclaim "by=blue · aaa" "blue · aaa" "" 99999)" = KEPT ] \
  && ok "label: our own name is never rewritten" || no "label: our own name is never rewritten" "rewrote it"
# THE CASE THE ITEM EXISTS FOR — 13h old, no driver, another session's name
[ "$(reclaim "by=orange · zzz" "blue · aaa" "" 46800)" = WROTE ] \
  && ok "label: a dead session's 13h-old label is reclaimed" \
  || no "label: a dead session's 13h-old label is reclaimed" "left stale"
# THE CASE THAT MUST NOT REGRESS — a peer with a live driver keeps its name
[ "$(reclaim "by=orange · zzz" "blue · aaa" "22087" 46800)" = KEPT ] \
  && ok "label: a peer with a live driver keeps its name" \
  || no "label: a peer with a live driver keeps its name" "renamed a live peer"
# ... and a peer whose driver Maestro just tore down is still protected by age
[ "$(reclaim "by=orange · zzz" "blue · aaa" "" 60)" = KEPT ] \
  && ok "label: a recently-named peer survives a torn-down driver" \
  || no "label: a recently-named peer survives a torn-down driver" "renamed too eagerly"
# a session-id mismatch alone must NOT be sufficient — two live sessions share
# this Mac routinely (item 80)
sed -n '/^_label_default()/,/^}/p' "$REPO/bin/drivers.sh" | grep -q 'AGE' \
  && ok "label: the reclaim needs age, not just a mismatch" \
  || no "label: the reclaim needs age, not just a mismatch" "mismatch alone would rename"

echo "no ssh call sits inside a loop reading from stdin (item 84)"
# The lint runs over the whole source, every time. _ssh passes stdin to the
# remote command, so an ssh inside a loop fed by a pipe or a file redirect eats
# every line not yet read — the loop runs once, silently, exit 0.
if python3 "$REPO/bin/lint-stdin.py" "$REPO"/bin/*.sh "$REPO"/remote/*.sh "$REPO"/hooks/*.sh >"$TMP/lint.out" 2>&1; then
  ok "lint: no ssh inside a loop reading from stdin"
else
  no "lint: no ssh inside a loop reading from stdin" "$(head -4 "$TMP/lint.out")"
fi

# and the lint itself has to catch the shape, or it is decoration
LT="$TMP/lintcases"; mkdir -p "$LT"
cat > "$LT/bad.sh" <<'CASE'
list(){
  _booted | while read -r u name; do
    _ssh "echo $u"
  done
}
CASE
python3 "$REPO/bin/lint-stdin.py" "$LT/bad.sh" >/dev/null 2>&1 \
  && no "lint: it catches a pipe into while read" "passed a known-bad file" \
  || ok "lint: it catches a pipe into while read"

cat > "$LT/bad2.sh" <<'CASE'
list(){
  while read -r u p; do
    _ssh "echo $u"
  done < "$MAP"
}
CASE
python3 "$REPO/bin/lint-stdin.py" "$LT/bad2.sh" >/dev/null 2>&1 \
  && no "lint: it catches a file redirect too" "passed a known-bad file" \
  || ok "lint: it catches a file redirect too"

# read -u <fd> is the documented fix (item 36) and must NOT be flagged, or the
# lint trains people to undo it
cat > "$LT/good.sh" <<'CASE'
run(){
  exec {fd}< "$file"
  while IFS= read -r -u "$fd" line; do
    _ssh "echo $line"
  done
  exec {fd}<&-
}
CASE
python3 "$REPO/bin/lint-stdin.py" "$LT/good.sh" >/dev/null 2>&1 \
  && ok "lint: read -u on an explicit fd is not flagged" \
  || no "lint: read -u on an explicit fd is not flagged" "false positive on the documented fix"

# a one-line loop fed by a process substitution is safe — the ssh is in what
# FEEDS the loop, not in its body
cat > "$LT/good2.sh" <<'CASE'
run(){
  while read -r u _; do args+=("$u"); done < <(
    _ssh 'xcrun simctl list devices booted' | sed -n 's/x/y/p')
}
CASE
python3 "$REPO/bin/lint-stdin.py" "$LT/good2.sh" >/dev/null 2>&1 \
  && ok "lint: a substitution feeding a one-line loop is not flagged" \
  || no "lint: a substitution feeding a one-line loop is not flagged" "false positive"

# an ssh that closes its own stdin is the documented escape hatch
cat > "$LT/good3.sh" <<'CASE'
list(){
  _booted | while read -r u name; do
    _ssh "echo $u" </dev/null
  done
}
CASE
python3 "$REPO/bin/lint-stdin.py" "$LT/good3.sh" >/dev/null 2>&1 \
  && ok "lint: </dev/null is accepted as the escape hatch" \
  || no "lint: </dev/null is accepted as the escape hatch" "flagged a safe call"

echo "permission allows for ssh and scp (item 85)"
# Every call to the Mac is an ssh or scp through the Bash tool, and without an
# allow entry each one waits for a prompt. config.sh names what is uncovered at
# the same moment it checks the conf — the first thing a project runs, before
# any SSH. Detection only: a shell script cannot write either settings file.
#
# No Mac and no real config: a scratch project, a redirected HOME, and a fresh
# LDIR per case so the once-per-session marker cannot leak between them.
PA="$TMP/perm"; mkdir -p "$PA/proj/.claude" "$PA/home/.claude"
printf ': "${MAC_HOST:=mac-a mac-b}"\n: "${MAC_FQDN:=e.local}"\n: "${APP_ID:=c.e.a}"\n' \
  > "$PA/proj/.maestro-mac.conf"

perm_run() { # perm_run <case-name> -> stderr of a config.sh load
  ( cd "$PA/proj" && HOME="$PA/home" LDIR="$PA/ldir-$1" bash -c \
      'mkdir -p "$LDIR"; . '"$REPO"'/bin/config.sh' ) 2>&1 >/dev/null
}
perm_set() { printf '%s' "$2" > "$1"; }

perm_set "$PA/home/.claude/settings.json" '{}'
rm -f "$PA/proj/.claude/settings.local.json"
out=$(perm_run none)
printf '%s' "$out" | grep -q "ssh mac-a" && printf '%s' "$out" | grep -q "ssh mac-b" \
  && ok "allows: nothing configured names every uncovered call" \
  || no "allows: nothing configured names every uncovered call" "$out"
printf '%s' "$out" | grep -q 'Bash(ssh mac-\*:\*)' \
  && ok "allows: the suggestion uses the aliases' common prefix" \
  || no "allows: the suggestion uses the aliases' common prefix" "$out"
printf '%s' "$out" | grep -q "settings.local.json" \
  && ok "allows: both candidate files are named" \
  || no "allows: both candidate files are named" "$out"

# A wide entry in the global file covers every project and every alias.
perm_set "$PA/home/.claude/settings.json" \
  '{"permissions":{"allow":["Bash(ssh mac-*:*)","Bash(scp mac-*:*)"]}}'
out=$(perm_run wide)
[ -z "$out" ] && ok "allows: a wide global entry silences it" \
              || no "allows: a wide global entry silences it" "$out"

# A project file covering one alias of two leaves the other uncovered, and only
# the other should be reported.
perm_set "$PA/home/.claude/settings.json" '{}'
perm_set "$PA/proj/.claude/settings.local.json" \
  '{"permissions":{"allow":["Bash(ssh mac-a:*)","Bash(scp mac-a:*)"]}}'
out=$(perm_run partial)
printf '%s' "$out" | grep -q "ssh mac-b" \
  && ! printf '%s' "$out" | grep -q "ssh mac-a " \
  && ok "allows: a narrow project entry covers its own alias only" \
  || no "allows: a narrow project entry covers its own alias only" "$out"

# Once per session. The second load is silent whatever it would have said.
perm_set "$PA/proj/.claude/settings.local.json" '{}'
( cd "$PA/proj" && HOME="$PA/home" LDIR="$PA/ldir-once" bash -c \
    'mkdir -p "$LDIR"; . '"$REPO"'/bin/config.sh' ) >/dev/null 2>&1
out=$( cd "$PA/proj" && HOME="$PA/home" LDIR="$PA/ldir-once" bash -c \
    '. '"$REPO"'/bin/config.sh' 2>&1 >/dev/null )
[ -z "$out" ] && ok "allows: said once per session, not once per call" \
              || no "allows: said once per session, not once per call" "$out"

# A settings file that is not JSON is somebody else's problem to fix, but it
# must not stop the skill loading.
perm_set "$PA/home/.claude/settings.json" 'not json {'
( cd "$PA/proj" && HOME="$PA/home" LDIR="$PA/ldir-bad" bash -c \
    'mkdir -p "$LDIR"; . '"$REPO"'/bin/config.sh' ) >/dev/null 2>&1 \
  && ok "allows: a malformed settings.json does not stop the skill loading" \
  || no "allows: a malformed settings.json does not stop the skill loading" "config.sh returned non-zero"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
