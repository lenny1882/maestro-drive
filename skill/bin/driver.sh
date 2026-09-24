#!/bin/bash
# Read the screen straight from the Maestro iOS driver's own HTTP API.
#
# The XCUITest driver (maestro-driver-iosUITests-Runner) is a long-lived
# process that listens on the Mac's 127.0.0.1:22087 for as long as a Maestro
# session is alive. It serves the view hierarchy and screenshots itself — no
# JVM, no SSH round trip, no MCP call. Relayed onto the LAN it is readable from
# a plain curl here:
#
#   /deviceInfo     0.15s   points and pixels, so the scale factor
#   /viewHierarchy  0.28s   the raw XCUIElementSnapshot tree, frames in points
#   /screenshot     0.27s   full-resolution PNG
#   /touch          0.46s   a tap at raw screen coordinates, in points
#   /inputText      1.13s   type into whatever has focus
#
# Compare that with 7.7s for `maestro hierarchy` over SSH, or 2.2s for a
# two-action flow through the MCP server. The frames here are what Maestro
# itself reads before converting them into the bounds that inspect_screen
# reports, so this is also the way to tell a driver problem from a Maestro
# conversion problem (reference/driver-api.md).
#
# It is not a read-only API. /touch takes raw coordinates, so on a screen whose
# reported bounds are wrong you can do the arithmetic yourself and tap the right
# place in one call, with no selector and no Maestro run in the way.
#
#   ./bin/drivers.sh up            # a driver per simulator (do this first)
#   ./bin/driver.sh start          # relay the port, print the base URL
#   DEV=<udid> ./bin/driver.sh ... # drive that simulator, whichever port it is on
#   ./bin/driver.sh info
#   ./bin/driver.sh hierarchy      # raw JSON on stdout
#   ./bin/driver.sh tree           # the same, flattened to one line per node
#   ./bin/driver.sh nodes          # tree plus the unlabelled containers
#   ./bin/driver.sh shot out.png          # upright, in app-space points
#   ./bin/driver.sh shot out.png --on "^Submit$" --pad 20
#   ./bin/driver.sh shot out.png --crop 40,120,300,80 --scale 50
#   ./bin/driver.sh shot out.png --raw    # native pixels, unrotated
#   ./bin/driver.sh static         # has the screen settled?
#   ./bin/driver.sh keyboard       # is the keyboard up?
#   ./bin/driver.sh app            # the app in front, and is it the configured one
#   ./bin/driver.sh tap 200 483    # points, from the top-left of the screen
#   ./bin/driver.sh text "some text"
#   ./bin/driver.sh key delete
#   ./bin/driver.sh erase 20            # delete 20 chars backwards from caret
#   ./bin/driver.sh erase --all         # delete 9999 chars backwards (best-effort)
#   ./bin/driver.sh clear "^Search$"    # select-all-then-delete via long-press
#   ./bin/driver.sh swipe 200 700 200 300 [duration]
#   ./bin/driver.sh orient portrait|landscapeLeft|landscapeRight|upsideDown
#   ./bin/driver.sh launch|kill <bundleId>
#   ./bin/driver.sh stop
#
# On top of the raw routes it resolves elements by label, applying any
# coordinate-space markers in the tree itself (bin/resolve.py,
# reference/driving.md):
#
#   ./bin/driver.sh find "CONTINUE" --explain # every match, and the arithmetic
#   ./bin/driver.sh point "^CONTINUE$"        # just the point
#   ./bin/driver.sh tapon "^CONTINUE$"        # resolve, tap, wait for settle
#   ./bin/driver.sh type "^Search$" "some text"   # reads the text back afterwards
#   ./bin/driver.sh dismiss [--no-key]        # put the keyboard away
#   ./bin/driver.sh blank [--explain]         # where a tap would do nothing
#   ./bin/driver.sh expect|expect-not "^Home$" [timeout]  # timeout>0 waits for it
#   ./bin/driver.sh settle [seconds]          # default 20, or SETTLE=<n>
#   ./bin/driver.sh script a.journey b.journey
#
# Every action verb waits for the screen to go still before it returns, so a
# sleep after one waits for something that has already happened. Add --tree or
# --nodes directly after the verb to read the screen back in the same call —
# an action and the read that follows it are one round trip, not two:
#
#   ./bin/driver.sh tapon --tree "^CONTINUE$"
#   ./bin/driver.sh tap --nodes 200 483
#   ./bin/driver.sh type --tree "^Search$" "some text"
#
# A pattern matching more than one node exits 4 rather than guessing, and a
# match that cannot be tapped — off screen, or under the keyboard — exits 5
# rather than tapping into nothing.
#
# Routes and request shapes were read out of the Maestro jars
# (xcuitest/XCTestDriverClient.class and xcuitest/api/*Request.class) and then
# exercised against the live driver. None of it is documented upstream.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"

HERE=$(cd "$(dirname "$0")" && pwd)

# Which driver, and so which port. One simulator holds one driver and each
# driver has its own port, so DEV decides both — set it and everything below
# goes to that device. Without it, a single running driver is used and several
# are refused rather than guessed at. bin/drivers.sh brings them up.
_driver_bind || exit 1
BASE=$(_driver_base)

_up() { curl -s -o /dev/null -m 5 -w '%{http_code}' "$BASE/status" 2>/dev/null; }

# The cached map can be stale in a way that looks like a dead relay, so re-read
# it once and retry rather than making that the caller's problem.
#
# UNVERIFIED, deliberately kept: this recovers the case where a device's driver
# is still alive but on a different port. Attempts on 12 Aug could not produce
# that case — naming a device to the MCP server or the CLI *destroys* that
# device's driver rather than moving it, which the map refresh in _driver_bind
# already reports correctly. This costs one SSH call on a path that is already
# failing, so it stays; do not describe it in the documentation as a recovery
# that has been seen to work.
_rebind_retry=0
_rebind() {
  [ "$_rebind_retry" = 0 ] || return 1
  _rebind_retry=1
  local was=$DRIVER_PORT
  _driver_bind --fresh || return 1
  [ "$DRIVER_PORT" = "$was" ] && return 1
  BASE=$(_driver_base)
  echo "note: the driver for $DEV moved from $was to $DRIVER_PORT (an MCP call restarts it on ${DRIVER_PORT_BASE})" >&2
  return 0
}

# On a physical device the driver's HTTP server lives on the phone, reached over
# a usbmux tunnel; when the tunnel or the on-device runner drops, this side sees
# only "status did not answer" and the instinct is to blame the relay. The real
# cause is named in ~/devdrv-<udid>.log on the Mac (item 46). That log exists only for a
# device driver run and only a recent one is this session's, so its presence is a
# self-gating device signal — a simulator run adds nothing.
_devdrv_hint() {
  local t
  # A locked phone is the cheapest, commonest and most actionable cause: XCUITest
  # cannot attach to a locked springboard, and it surfaces as this same relay /
  # connection failure rather than as a lock. Measured 10 Sep 2026 — unlocked, the
  # driver starts 3/3; on the PIN screen it fails every time. So check it first.
  # The verb self-gates: exit 2 means the question does not apply to this kind of
  # device, which is what a simulator udid gets, so nothing here needs to know
  # which kind it has.
  if _ssh "sh '$PLATFORM_SH' locked '$DEV'" >/dev/null 2>&1; then
    echo "  the device is LOCKED — unlock it and retry." >&2
    echo "  XCUITest cannot attach to a locked screen; it fails as a relay/connection" >&2
    echo "  error, not as a lock (item 46)." >&2
  fi
  t=$(_ssh 'f=$HOME/devdrv-'"$DEV"'.log; [ -f "$f" ] || exit 0
now=$(date +%s); m=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
[ $((now - m)) -lt 600 ] && tail -6 "$f"' 2>/dev/null)
  [ -n "$t" ] || return 0
  echo "  ~/devdrv-$DEV.log on the Mac (the on-device driver) ends:" >&2
  printf '%s\n' "$t" | sed 's/^/    /' >&2
  # The face-up crash (item 50) has a distinct cause and a distinct fix, so name
  # it before the generic XCTest-death message below — a restart alone does not
  # help while the phone stays flat. Reproduced live 11 Sep: a raw /touch on a
  # face-up XS Max kills the runner at ScreenSizeHelper.swift with "Not
  # implemented yet". The on-device runner still crashes even though the jar's
  # own ScreenSizeHelper.swift handles .faceUp — the runner is built from older
  # source (item 55).
  case "$t" in
    *ScreenSizeHelper*|*"Not implemented yet"*)
      echo "  this is the FACE-UP crash (item 50): the phone is lying flat, reports" >&2
      echo "  .faceUp, and the runner kills itself on the first /touch. STAND THE" >&2
      echo "  PHONE UPRIGHT, then retry — a driver restart alone does not fix it" >&2
      echo "  while it stays flat." >&2
      return 0 ;;
  esac
  # F27, measured: this is the on-device XCTest session dying, NOT the relay and
  # NOT the tunnel — devicectl stays 'connected' through the death. Do not tell
  # the caller to wake the tunnel; the only recovery is a full driver restart.
  echo "  'TEST EXECUTE FAILED' / 'connection was invalidated' is the on-device XCTest" >&2
  echo "  session dying (item 46), not the relay. Measured on Xcode 26.6 it lasts only" >&2
  echo "  ~40-70s even with the CoreDevice tunnel still 'connected', so a full driver" >&2
  echo "  restart is the fix (bin/device.sh up <udid>) — a tunnel wake does nothing." >&2
  echo "  driver.sh restarts a registered device itself. If it keeps dying within a couple" >&2
  echo "  of minutes, restart CoreDevice on the Mac: sudo killall -9 remoted. On 24 Sep that" >&2
  echo "  took sessions from under 2 minutes to over 10; retrying and restarting the phone" >&2
  echo "  did not (item 46)." >&2
}

# Is DEV a physical device this session brought up (bin/device.sh), rather than a
# simulator? Devices are in the registry; simulators are found by the process scan.
_is_device() { [ -n "${DEV:-}" ] && grep -q "^$DEV " "$DEVICE_MAP" 2>/dev/null; }

# Count this phone's automatic restarts, and on the third within ten minutes
# say what fixed that on 24 Sep: restarting CoreDevice on the Mac. Retrying,
# restarting the phone and changing the driver all left sessions dying within
# two minutes; `sudo killall -9 remoted` took them past ten (item 46). It needs
# the Mac user's password, so it is said, not done.
_restarts_note() {
  local f="${LDIR:-${TMPDIR:-/tmp}}/restarts-$DEV" now n
  now=$(date +%s)
  { cat "$f" 2>/dev/null; echo "$now"; } | awk -v t="$now" '$1 > t - 600' > "$f.tmp" &&
    mv -f "$f.tmp" "$f"
  n=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
  [ "${n:-0}" -ge 3 ] || return 0
  echo "note: this is restart $n for $DEV in 10 minutes. Sessions this short came from the" >&2
  echo "  Mac's CoreDevice service on 24 Sep, not the phone or the driver. Restart it on the" >&2
  echo "  Mac, which needs its password:  sudo killall -9 remoted   (item 46)" >&2
}

# Ensure-driver, item 46. A registered device's driver dies mid-session and the
# failure reads as a dead relay on this side. When the phone's driver is not
# answering, restart it through bin/device.sh — which is idempotent and re-runs
# the driver — and let the caller retry. Once per invocation, so a driver that
# will not come back does not loop.
_ensure_dev_retry=0
_ensure_device() {
  [ "$_ensure_dev_retry" = 0 ] || return 1
  _is_device || return 1
  _ensure_dev_retry=1
  echo "note: the device driver for $DEV is not answering — restarting it (item 46)" >&2
  # Name the cause BEFORE restarting. The restart empties the phone's log, so
  # afterwards there is nothing left to read, and a restart that works never
  # reaches the hint in _start. From 11 Sep, when the restart below started
  # working, until 24 Sep, a phone lying flat crashed on every tap and came back
  # silently, and the face-up crash was never named (items 50, 46).
  _devdrv_hint
  _restarts_note
  # bash <script>, not the path alone. device.sh used to ship without an execute
  # bit — the old rsync-to-build/ publish did not chmod and ~/.claude refuses
  # chmod +x — so a direct "$HERE/device.sh" failed with "Permission denied" and
  # the recovery never ran, measured live on the XS Max, 11 Sep. The repo now
  # records the bit and git archive carries it into the release tarball, but the
  # call stays as it is: it costs nothing and it works whatever the mode is.
  bash "$HERE/device.sh" up "$DEV" "$DRIVER_PORT" >&2 || return 1
}

_start() {
  [ "$(_up)" = "200" ] && return 0
  # Locally there is nothing to start. The driver binds this machine's loopback
  # and $BASE already names it, so the relay, the staging and the pkill all go
  # (item 94, 4.1) — and so does the lsof check below, because "is anything
  # listening on $DRIVER_PORT" is the question _up just answered against that
  # very port. What is left is the retry, which is about the driver and not
  # about the transport.
  if _ports_here; then
    _rebind && { _start; return $?; }
    _ensure_device && { _start; return $?; }
    echo "nothing is listening on $DRIVER_PORT — bin/drivers.sh up ${DEV} (or bin/device.sh up ${DEV} for a phone)" >&2
    _devdrv_hint; return 1
  fi
  _ssh "mkdir -p '$RDIR'" >/dev/null
  _push "$HERE/../remote/relay.py" "$RHELP/relay.py" || return 1
  # pkill matches any relay on this DPORT, whatever its target: a stale relay left
  # pointing at the wrong port holds the socket and beats the correct one to it,
  # so an exact <DPORT> <DRIVER_PORT> match would leave it running (seen 10 Sep).
  _ssh "lsof -nP -iTCP:$DRIVER_PORT -sTCP:LISTEN >/dev/null 2>&1 || { echo 'nothing listening on $DRIVER_PORT — bin/drivers.sh up ${DEV} (or bin/device.sh up ${DEV} for a phone)' >&2; exit 1; }
pkill -f 'relay.py $DPORT ' 2>/dev/null
cd '$RDIR' && nohup python3 '$RHELP/relay.py' $DPORT $DRIVER_PORT >/dev/null 2>&1 &
sleep 1" || { _rebind && _start; return $?; }
  [ "$(_up)" = "200" ] || { _rebind && { _start; return $?; }
                            _ensure_device && { _start; return $?; }
                            echo "relay started but $BASE/status did not answer" >&2
                            _devdrv_hint; return 1; }
}

_hier() {
  _start || return 1
  curl -s -m 30 -X POST -H 'Content-Type: application/json' \
    -d "{\"appIds\":[\"$APP_ID\"],\"excludeKeyboardElements\":${EXCLUDE_KEYBOARD:-true}}" \
    "$BASE/viewHierarchy"
}

# A simulator that has stopped taking touches still serves /viewHierarchy
# perfectly, so every read looks healthy and every write is silently discarded.
# Measured 16 Sep 2026 after a load spike: `tapon` and `text` both returned ok,
# the tree read correctly, and nothing reached the app. Two calls went on proving
# it, and the natural reading — "the app is broken" — was the claim under test.
#
# There is no route that asks the driver whether touch injection is alive, so
# this is inferred: an action verb that leaves the hierarchy byte-for-byte
# identical, twice running, is the signature. A genuinely static screen gives a
# false positive, which costs a line of stderr; the missed case costs a session.
_WEDGE_SEEN=0
_wedge_check() {  # _wedge_check <hierarchy-before> <hierarchy-after>
  [ -n "${1:-}" ] && [ "$1" = "${2:-}" ] || { _WEDGE_SEEN=0; return 0; }
  _WEDGE_SEEN=$((_WEDGE_SEEN + 1))
  [ "$_WEDGE_SEEN" -ge 2 ] || return 0
  echo "two actions in a row left the hierarchy byte-identical." >&2
  echo "  That is what a simulator with dead touch injection looks like: reads" >&2
  echo "  keep working, writes are discarded, and every verb still reports ok" >&2
  echo "  (measured 16 Sep 2026 after a load spike). Confirm before concluding" >&2
  echo "  anything about the app:  $0 probe" >&2
  _WEDGE_SEEN=0
}

# Does this device take touches at all? Taps the emptiest point on the screen —
# the one `dismiss` uses, chosen because a tap there is meant to do nothing —
# and reports whether the tree moved. Inconclusive on a screen that genuinely
# never changes, and says so rather than claiming a pass.
_probe() {
  local before after pt
  _ensure_screen || return 1
  before=$(_hier) || { echo "probe: cannot read the hierarchy — the driver is gone, not the touch path" >&2; return 1; }
  pt=$(printf '%s' "$before" | python3 "$HERE/resolve.py" --blank \
         --width "$SCREEN_W" --height "$SCREEN_H" 2>/dev/null)
  [ -n "$pt" ] || { echo "probe: no blank point on this screen to tap safely" >&2; return 2; }
  echo "probe: tapping the blank point $pt" >&2
  _post touch "{\"x\":${pt% *},\"y\":${pt#* },\"duration\":0.1}" >/dev/null || {
    echo "probe: the driver refused the tap — that is the driver, not the device" >&2; return 1; }
  _settle || true
  after=$(_hier)
  if [ "$before" != "$after" ]; then
    echo "probe: the screen changed — touches are reaching the app"
    return 0
  fi
  echo "probe: the screen did not change." >&2
  echo "  Either this screen ignores a tap on empty space, which is normal, or" >&2
  echo "  the simulator has stopped taking touches. Tell them apart by tapping" >&2
  echo "  something that MUST do something (a tab, a back button) and reading" >&2
  echo "  the tree. If that does nothing either, the simulator is wedged:" >&2
  echo "  shut it down and boot another — a restart of the driver will not fix" >&2
  echo "  it, because the driver is answering fine." >&2
  return 3
}

_tree() {  # _tree <tree|nodes>
  _hier | python3 "$HERE/tree.py" "${1:-tree}"
}

_post() {  # _post <route> <json>
  _start || return 1
  curl -s -m 30 -X POST -H 'Content-Type: application/json' -d "$2" "$BASE/$1"
}

_appids='"appIds":["'"$APP_ID"'"]'

# --- element resolution -----------------------------------------------------
# resolve.py turns a label pattern into an absolute point, applying whatever
# coordinate-space markers the tree carries (see its docstring, and
# reference/driving.md).
# Everything below is one round trip per action rather than the read-think-tap
# loop it replaces.

_ensure_screen() {
  [ -n "${SCREEN_W:-}" ] && return 0
  local d
  d=$(_start && curl -s -m 5 "$BASE/deviceInfo") || return 1
  read -r SCREEN_W SCREEN_H <<EOF
$(printf '%s' "$d" | python3 -c 'import json,sys
d=json.load(sys.stdin); print(d["widthPoints"], d["heightPoints"])')
EOF
  [ -n "${SCREEN_W:-}" ] || { echo "could not read screen size from /deviceInfo" >&2; return 1; }
}

# Float comparison, for asking whether a picture is landscape the same way the
# screen is. Shell test(1) is integer-only and these are points.
_gt() { python3 -c "print(1 if float('$1') > float('$2') else 0)"; }

_resolve() {  # _resolve <pattern> [index] [--anyway|--enabled|--disabled] -- prints "x y"
  _ensure_screen || return 1
  local idx=() extra=()
  for _a in "${@:2}"; do
    [ -z "$_a" ] && continue
    case "$_a" in
      --anyway|--enabled|--disabled) extra+=("$_a") ;;
      *) [ ${#idx[@]} -eq 0 ] && idx=(--index "$_a") ;;
    esac
  done
  _hier | python3 "$HERE/resolve.py" "$1" \
    --width "$SCREEN_W" --height "$SCREEN_H" --point "${idx[@]}" "${extra[@]}"
}

# The screen counts as moving while a loading spinner turns, so this waits on
# backend latency as much as on animation — hence 20s rather than the 10 that
# lost a run on 11 Aug when a screen waiting on a slow request came back late. It returns the
# moment the screen is still, so a generous limit costs nothing on a fast
# screen. Override for a whole run with SETTLE=<seconds>.
_settle() {  # _settle [timeout-seconds]
  local limit=${1:-${SETTLE:-20}} waited=0
  # SETTLE=0 turns the wait off for a screen that never goes still — a
  # permanent animation, a video, a spinner the app leaves running. Without
  # this every action would pay the full timeout and then report failure.
  [ "$limit" = 0 ] && return 0
  local empty=0
  while [ "$waited" -lt "$((limit * 5))" ]; do
    case "$(curl -s -m 5 "$BASE/isScreenStatic" 2>/dev/null)" in
      *true*) return 0 ;;
      "")     empty=$((empty + 1)) ;;
      *)      empty=0 ;;
    esac
    # A dead driver answers nothing, and used to be waited out for the full
    # limit and then reported as a moving screen — the same words as a live
    # one, which sent a crashed phone back to be diagnosed as an animation
    # (BACKLOG item 105). Three empty answers in a row is not a screen.
    if [ "$empty" -ge 3 ]; then
      echo "settle: the driver stopped answering after the last action — not a moving screen" >&2
      return 1
    fi
    sleep 0.2
    waited=$((waited + 1))
  done
  if [ "$(curl -s -m 4 -o /dev/null -w '%{http_code}' "$BASE/status" 2>/dev/null)" = 200 ]; then
    echo "settle: screen still moving after ${limit}s — the driver is up, so the screen itself" >&2
    echo "  keeps changing (an animation, a clock, a spinner; a phone's home screen did on 24 Sep)." >&2
    echo "  SETTLE=0 skips the wait for such a screen." >&2
  else
    echo "settle: no still screen after ${limit}s, and the driver is not answering now" >&2
  fi
  return 1
}

_tapon() {  # _tapon <pattern> [index] [--anyway]
  local pt x y
  pt=$(_resolve "$@") || return 1
  x=${pt% *}; y=${pt#* }
  _post touch "{\"x\":$x,\"y\":$y}" >/dev/null || return 1
  _settle
}

# Typing is a tap plus keystrokes and both halves fail quietly, so the result is
# read back rather than assumed (bin/typed.py). TYPE_VERIFY=0 turns it off for
# the case this cannot judge: text that the app immediately transforms or
# clears. It does not judge what the app then DID with the text — see item 14.
_type() {  # _type <pattern> <text>
  _tapon "$1" || return $?
  _post inputText "{\"text\":$(printf '%s' "$2" |
    python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))'),$_appids}" >/dev/null || return 1
  _settle || return 1
  [ "${TYPE_VERIFY:-1}" = 0 ] && return 0
  _hier | python3 "$HERE/typed.py" "$2"
}

# The route is swipeV2, not swipe. POST /swipe is answered 200 whether or not it
# does anything, and on an iPad Pro 11-inch driving a Flutter grid it did
# nothing at all — fourteen consecutive calls, fourteen identical hierarchies
# (16 Sep 2026), while the same payload to /swipeV2 moved the list first try.
# It is NOT simply dead: on an iPhone 16 Pro Max against springboard it paged
# the home screen normally (measured 17 Sep 2026). So /swipe works somewhere and
# not elsewhere, which is worse than a route that never works — swipeV2 is the
# route Maestro itself posts and the one the driver's SwipeRouteHandlerV2 class
# serves, so everything here goes through it. BACKLOG item 69.
_scrollto() {  # _scrollto <pattern> <direction> <timeout>
  local pat=$1 dir=${2:-down} limit=${3:-20} waited=0
  local sw sh mid_x mid_y dx dy
  _ensure_screen || return 1
  sw=$SCREEN_W; sh=$SCREEN_H
  mid_x=$((sw / 2)); mid_y=$((sh / 2))
  case "$dir" in
    down)  dx=0; dy=$((-sh / 4)) ;;
    up)    dx=0; dy=$((sh / 4)) ;;
    left)  dx=$((sw / 4)); dy=0 ;;
    right) dx=$((-sw / 4)); dy=0 ;;
    *) echo "scrollto: direction must be up/down/left/right, got '$dir'" >&2; return 2 ;;
  esac
  while [ "$waited" -lt "$limit" ]; do
    if _resolve "$pat" >/dev/null 2>&1; then return 0; fi
    _post swipeV2 "{\"appId\":\"$APP_ID\",\"startX\":$mid_x,\"startY\":$mid_y,\"endX\":$((mid_x + dx)),\"endY\":$((mid_y + dy)),\"duration\":0.3,$_appids}" >/dev/null || return 1
    _settle || true
    waited=$((waited + 1))
    echo "  scrollto /$pat/ ($dir $waited/${limit})" >&2
  done
  _resolve "$pat" >/dev/null 2>&1 && return 0
  echo "scrollto: /$pat/ not found after $limit swipes $dir" >&2
  return 1
}

# --- watching a list change, with nobody touching the device ----------------
# One watcher per device, because two writing one log made every change arrive
# twice (15 Sep 2026).
#
# It runs in the FOREGROUND and streams. That is deliberate: `nohup ... &` from
# this side is dead by the next call (item 71), so the caller starts this with
# the harness's run_in_background and reads the log — the only mechanism
# measured to survive here.
#
# LIVENESS AND STOPPING GO THROUGH FILES, NOT PIDS. Every Bash call gets its own
# PID namespace, so a pid written by one call means nothing to the next: `kill
# -0` fails on a process that is running fine, and `kill` cannot reach it.
# Measured 17 Sep 2026 while building this — the first cut used a pid file, and
# it reported "NOT watching" over a live watcher and then let a second one
# start, which is the failure the lock exists to prevent. So:
#
#   .claim  written at start, removed on a clean exit
#   .log    the samples; its MTIME is the heartbeat
#   .stop   touched to ask the watcher to finish; it polls for this
#
# A watcher counts as alive when the claim is there AND the log has been written
# to within three intervals. Three, not one: a slow sample is an ERR line, not a
# death, and calling a live watcher dead is how a second one gets started.
# ${LDIR:-...} rather than $LDIR: these are assigned at source time, and a
# caller that sources driver.sh without config.sh — the tests do — would other-
# wise die on `set -u` before reaching any verb.
_WATCH_BASE="${LDIR:-${TMPDIR:-/tmp}}/watch-${DEV:-nodevice}"
_WATCH_CLAIM="$_WATCH_BASE.claim"
_WATCH_LOG="$_WATCH_BASE.log"
_WATCH_STOP="$_WATCH_BASE.stop"

_watch_age() {  # seconds since the log was last written
  local m
  [ -r "$_WATCH_LOG" ] || return 1
  m=$(stat -c %Y "$_WATCH_LOG" 2>/dev/null || stat -f %m "$_WATCH_LOG" 2>/dev/null) || return 1
  echo $(( $(date +%s) - m ))
}

_watch_alive() {  # 0 if a watcher is running for this device
  local age grace interval
  [ -r "$_WATCH_CLAIM" ] || return 1
  interval=$(sed -n 's/.*interval=\([0-9]*\).*/\1/p' "$_WATCH_CLAIM")
  [ -n "$interval" ] || interval=20
  grace=$(( 3 * interval + 15 ))
  age=$(_watch_age) || return 1
  [ "$age" -le "$grace" ]
}

_watch_start() {  # _watch_start <pattern> [--context <pat>] [--interval n] [--cycles n]
  local pat=$1 ctx="" interval=20 cycles=0
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --context)  ctx=$2; shift 2 ;;
      --interval) interval=$2; shift 2 ;;
      --cycles)   cycles=$2; shift 2 ;;
      *) echo "watch: unknown option '$1'" >&2; return 2 ;;
    esac
  done
  if _watch_alive; then
    echo "watch: already watching $DEV — $(cat "$_WATCH_CLAIM"), last sample $(_watch_age)s ago" >&2
    echo "  log: $_WATCH_LOG" >&2
    echo "  A second watcher on one device writes to the same log and every" >&2
    echo "  change then arrives twice. Stop the first: $0 watch stop" >&2
    return 1
  fi
  local rows_cmd ctx_cmd="" conf="${MAESTRO_DRIVE_CONF_FOUND:-}"
  rows_cmd="DEV=$DEV MAESTRO_DRIVE_CONF=$(printf %q "$conf") $0 rows $(printf %q "$pat") --json"
  [ -n "$ctx" ] && ctx_cmd="DEV=$DEV MAESTRO_DRIVE_CONF=$(printf %q "$conf") $0 rows $(printf %q "$ctx") --json"
  : > "$_WATCH_LOG"
  printf 'started=%s interval=%s pattern=%s\n' "$(date +%H:%M:%S)" "$interval" "$pat" > "$_WATCH_CLAIM"
  echo "watch: $DEV every ${interval}s -> $_WATCH_LOG" >&2
  echo "  start this with run_in_background and read the log; nohup does not" >&2
  echo "  survive the call (reference/connection.md). Stop it with:" >&2
  echo "    $0 watch stop" >&2
  python3 "$HERE/watch.py" --rows-cmd "$rows_cmd" --context-cmd "$ctx_cmd" \
    --interval "$interval" --cycles "$cycles" --log "$_WATCH_LOG" \
    --stop-file "$_WATCH_STOP" --claim-file "$_WATCH_CLAIM" --label "$DEV"
}

_watch_status() {
  local samples errs chg alive=1
  if _watch_alive; then
    alive=0
    echo "watching $DEV — $(cat "$_WATCH_CLAIM" | tr -d '\n'), last sample $(_watch_age)s ago"
  elif [ -r "$_WATCH_CLAIM" ]; then
    echo "NOT watching $DEV — a claim is there but the log has not moved for $(_watch_age)s; the watcher is gone"
  else
    # Saying so plainly is the point of this verb. A session reported that it
    # was watching for an hour while nothing ran, because the start had been
    # refused at the permission prompt and nobody checked (15 Sep 2026).
    echo "NOT watching $DEV"
  fi
  if [ -r "$_WATCH_LOG" ]; then
    # grep -c prints 0 and exits 1 when nothing matches, so `|| echo 0` here
    # prints the count TWICE. `|| true` is what is wanted.
    samples=$(grep -c '^[0-9][0-9][0-9][0-9] ' "$_WATCH_LOG" 2>/dev/null || true)
    errs=$(grep -c ' ERR  ' "$_WATCH_LOG" 2>/dev/null || true)
    chg=$(grep -c '>>> CHANGE' "$_WATCH_LOG" 2>/dev/null || true)
    echo "  ${samples:-0} samples, ${errs:-0} failed reads, ${chg:-0} changes"
    echo "  log:  $_WATCH_LOG"
    echo "  last: $(tail -1 "$_WATCH_LOG")"
  else
    echo "  no log at $_WATCH_LOG"
  fi
  return $alive
}

_watch_stop() {
  if _watch_alive; then
    : > "$_WATCH_STOP"
    echo "asked the watcher on $DEV to stop; log kept at $_WATCH_LOG"
    echo "  it exits within one interval — check with: $0 watch status"
  else
    rm -f "$_WATCH_CLAIM" "$_WATCH_STOP"
    echo "no watcher running for $DEV (any stale claim cleared)"
  fi
}

_clear() {  # _clear <pattern> — select-all-then-delete via long-press
  local pt x y
  pt=$(_resolve "$1" "${2:-}") || return 1
  x=${pt% *}; y=${pt#* }
  _post touch "{\"x\":$x,\"y\":$y,\"duration\":1.0}" >/dev/null || return 1
  _settle || true
  # The long-press raises the iOS edit menu; tap "Select All" from it.
  # If "Select All" is not on screen (field is empty, or the menu did not
  # appear), skip — there is nothing to clear.
  if _resolve "^Select All$" >/dev/null 2>&1; then
    _tapon "^Select All$" || return 1
    _post eraseText "{\"charactersToErase\":1,$_appids}" >/dev/null || return 1
    _settle || true
  fi
}

# expect / expect-not answer immediately by default (timeout 0): one resolve,
# present or absent. A timeout argument turns them into a wait-for-condition —
# poll _resolve once a second until it agrees or the limit passes, returning the
# moment it does. This is the only way to wait for something that changes WITHOUT
# the screen moving: a banner clearing on its own timer, a status arriving on a
# poll or a push. `_settle` cannot see those, because the screen is already
# still. The zero default is deliberate — existing journeys must not silently
# start waiting.
#
# A heartbeat line each second on stderr keeps a long wait from reading as a
# hang; a silent poll was mistaken for a stuck loop more than once (item 41).
_expect() {  # _expect <pattern> [absent|enabled|disabled|""] [timeout-seconds]
  local pat=$1 mode=${2:-} limit=${3:-0} waited=0 rc met what suffix="" rflag=""
  [[ "$limit" =~ ^[0-9]+$ ]] || limit=0
  what="/$pat/"
  case "$mode" in
    absent)   what="/$pat/ to clear" ;;
    enabled)  what="/$pat/ enabled"; rflag="--enabled" ;;
    disabled) what="/$pat/ disabled"; rflag="--disabled" ;;
  esac
  [ "$limit" -gt 0 ] && suffix=" after ${limit}s"
  while : ; do
    _resolve "$pat" $rflag >/dev/null 2>&1; rc=$?
    if [ "$mode" = absent ]; then
      [ "$rc" -eq 3 ] && met=1 || met=0
    else
      { [ "$rc" -eq 0 ] || [ "$rc" -eq 4 ]; } && met=1 || met=0
    fi
    [ "$met" -eq 1 ] && return 0
    [ "$waited" -ge "$limit" ] && break
    waited=$((waited + 1))
    echo "  waiting for $what ($waited/${limit}s)" >&2
    sleep 1
  done
  case "$mode" in
    absent)   echo "expect-not: /$pat/ is present$suffix" >&2 ;;
    enabled)  echo "expect: /$pat/ not found or not enabled$suffix" >&2 ;;
    disabled) echo "expect: /$pat/ not found or not disabled$suffix" >&2 ;;
    *)        echo "expect: /$pat/ not found$suffix" >&2 ;;
  esac
  return 1
}

_expect_cmd() {  # _expect_cmd <command> <timeout>
  local cmd=$1 limit=${2:-30} waited=0
  [[ "$limit" =~ ^[0-9]+$ ]] || limit=30
  while : ; do
    if eval "$cmd" >/dev/null 2>&1; then return 0; fi
    [ "$waited" -ge "$limit" ] && break
    waited=$((waited + 1))
    echo "  waiting for command ($waited/${limit}s)" >&2
    sleep 1
  done
  echo "expect-cmd: command did not succeed after ${limit}s" >&2
  return 1
}

# --- putting the keyboard away ----------------------------------------------
# There is no route for it. The driver's own client names eighteen
# (`xcuitest/XCTestDriverClient.class`, re-read 13 Aug 2026) and not one of them
# hides the keyboard, because iOS exposes no API to do it. Maestro's own
# `hideKeyboard` is Kotlin in the client: swipes from the middle of the screen,
# then a check — which upstream documents as flaky, recommending a tap on
# something non-interactive instead.
#
# On the app measured here that advice is simply wrong. Six taps on blank parts
# of the screen and one swipe, on 13 Aug 2026, left the keyboard up every time;
# `key return` put it away every time. So this tries both, in that order,
# because the blank tap cannot do anything else and `key return` can:
#
#   tap the emptiest point   nothing happens if it fails, and on a UIKit app
#                            or a Flutter one that unfocuses on tap it works
#   key return               submits the focused field. On a dropdown with its
#                            list open that may commit a row, so when it is
#                            what worked, this says so rather than leaving the
#                            caller to find out. --no-key stops before it.
#
# Either way the keyboard is read back afterwards. A tap meant to do nothing is
# exactly the kind that fails silently, and session E spent about ten calls and
# five minutes on 13 Aug concluding the keyboard would not drop — from readings
# taken after a command that had re-opened the field and raised it again.

# 0 the keyboard is up, 1 it is down, 2 the driver gave no answer. The third
# case matters: an empty reply read as "down" would make dismiss report success
# on a screen it never touched.
_kb_up() {
  local r
  r=$(_post keyboard "{$_appids}" 2>/dev/null) || return 2
  case "$r" in
    *true*)  return 0 ;;
    *false*) return 1 ;;
  esac
  echo "keyboard: the driver answered '${r:-nothing}'" >&2
  return 2
}

# The keyboard slides out over about a third of a second, so a read taken
# straight after an action still sees it. 0 gone, 1 still there after 3 s,
# 2 the driver gave no answer. Note the inversion against _kb_up, which
# answers the opposite question — getting that wrong made dismiss report
# failure on a screen where `key return` had just worked.
_kb_gone() {
  local waited=0 rc
  while [ "$waited" -lt 15 ]; do
    _kb_up; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 2
    sleep 0.2
    waited=$((waited + 1))
  done
  return 1
}

_blank() {  # _blank [--explain] -- prints "x y", plus detail with --explain
  _ensure_screen || return 1
  _hier | python3 "$HERE/resolve.py" --blank \
    --width "$SCREEN_W" --height "$SCREEN_H" "$@"
}

_dismiss() {  # _dismiss [--no-key]
  local nokey=""
  [ "${1:-}" = --no-key ] && nokey=1
  _ensure_screen || return 1

  local out pt x y rc
  _kb_up; rc=$?
  [ "$rc" -eq 2 ] && return 1
  [ "$rc" -eq 1 ] && { echo "the keyboard is already down"; return 0; }

  out=$(_blank) || return $?
  pt=${out%%$'\n'*}
  x=${pt% *}; y=${pt#* }
  _post touch "{\"x\":$x,\"y\":$y}" >/dev/null || return 1
  _kb_gone; rc=$?
  [ "$rc" -eq 2 ] && return 1
  [ "$rc" -eq 0 ] && { echo "dismissed the keyboard with a tap at $x,$y"
                       _settle || true; return 0; }

  if [ -n "$nokey" ]; then
    echo "dismiss: the tap at $x,$y left the keyboard up, and --no-key rules out \`key return\`" >&2
    return 1
  fi

  _post pressKey '{"key":"return"}' >/dev/null || return 1
  _kb_gone; rc=$?
  [ "$rc" -eq 2 ] && return 1
  if [ "$rc" -eq 0 ]; then
    cat <<MSG
dismissed the keyboard with \`key return\` — the tap at $x,$y did not work on
this screen. Return submits whatever had focus, so if that was a dropdown with
its list open the app may have committed a row. Check the field with \`expect\`
before carrying on.
MSG
    _settle || true
    return 0
  fi
  cat >&2 <<MSG
dismiss: the keyboard is still up after a tap at $x,$y and \`key return\`. Those
are the only two methods iOS leaves; what is left all does something else as
well:
  - tapon <a title or header clear of the keyboard>
  - swipe the form so the target rises above the keyboard instead
  - launch — restarting the app closes it, and loses the screen
Read the screen with '$0 nodes' first. A point this call thought was blank may
have something on it the accessibility tree does not report.
MSG
  return 1
}

# --- screenshots -----------------------------------------------------------
# `/screenshot` hands back the device's native pixels, which on a
# landscape-locked iPad means the picture arrives on its side and at twice the
# points it is measured in. Both were corrected by hand until now — eight
# `sips -r 270` calls in one session, then hand-written crops against a
# 1206x2622 source in another.
#
# So a shot is delivered upright and croppable in the same coordinates as
# everything else here: points, app space, the numbers `driver.sh point` gives.
# --raw opts out and gives the untouched native picture.

_shot() {
  local out="" raw="" on="" idx="" pad=12 crop="" scale="" rc=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --raw)   raw=1; shift ;;
      --on)    on=$2; shift 2 ;;
      --index) idx=$2; shift 2 ;;
      --pad)   pad=$2; shift 2 ;;
      --crop)  crop=$2; shift 2 ;;
      --scale) scale=$2; shift 2 ;;
      -*)      echo "shot: unknown option $1" >&2; return 2 ;;
      *)       out=$1; shift ;;
    esac
  done
  out=${out:-$LDIR/driver-shot.png}
  [ -z "$on" ] || [ -z "$crop" ] || { echo "shot: --on and --crop are two ways to say the same thing; pick one" >&2; return 2; }
  [ -z "$idx" ] || [ -n "$on" ] || { echo "shot: --index only means something with --on" >&2; return 2; }

  _start || return 1
  curl -s -m 20 "$BASE/screenshot" -o "$out" || return 1
  [ -s "$out" ] || { echo "shot: the driver returned an empty image" >&2; return 1; }

  # Untouched, and nothing else to do: one HTTP call, exactly as before.
  if [ -n "$raw" ] && [ -z "$crop$on$scale" ]; then echo "$out"; return 0; fi

  local pw ph
  read -r pw ph <<EOF
$("$HERE/img.sh" --size "$out")
EOF
  [ -n "${ph:-}" ] || { echo "shot: $out is not a PNG" >&2; return 1; }
  _ensure_screen || return 1

  # The hierarchy is only fetched when the picture disagrees with the screen —
  # a portrait image of a landscape screen. On an upright device that is never
  # true, so an iPhone shot costs no extra round trip at all. Which way to turn
  # it needs the status bar, and only the tree carries that.
  local rot=0 hier=""
  if [ -z "$raw" ] && [ "$(_gt "$pw" "$ph")" != "$(_gt "$SCREEN_W" "$SCREEN_H")" ]; then
    hier="$LDIR/.shot-hier.$$.json"
    _hier > "$hier" || { rm -f "$hier"; return 1; }
    rot=$(python3 "$HERE/resolve.py" --width "$SCREEN_W" --height "$SCREEN_H" --space < "$hier" | awk '{print $2}')
    rot=${rot:-0}
  fi

  # Points to pixels, taken from the upright picture against the screen rather
  # than from /deviceInfo — after a rotation the two disagree about which side
  # is which, and this cannot.
  local uw uh sf
  if [ "$rot" = 90 ] || [ "$rot" = 270 ]; then uw=$ph; uh=$pw; else uw=$pw; uh=$ph; fi
  sf=$(python3 -c "print(float($uw) / float($SCREEN_W))")

  # --pad exists to give an element some of its surroundings, so it belongs to
  # --on. An explicit rectangle is taken exactly as written; quietly growing it
  # by 12 points would be a wrong answer nobody would think to look for.
  local rect="" grow=$pad
  [ -n "$on" ] || grow=0
  if [ -n "$on" ]; then
    [ -n "$hier" ] || { hier="$LDIR/.shot-hier.$$.json"; _hier > "$hier" || { rm -f "$hier"; return 1; }; }
    local ridx=()
    [ -z "$idx" ] || ridx=(--index "$idx")
    rect=$(python3 "$HERE/resolve.py" "$on" --width "$SCREEN_W" --height "$SCREEN_H" \
             --rect "${ridx[@]}" < "$hier")
    rc=$?
    if [ "$rc" -ne 0 ]; then
      # The picture is already taken and is still worth having, so say where it
      # is. A full-size file sitting at the path a crop was asked for, with no
      # word about it, is the kind of quiet wrong answer this skill exists to
      # stop.
      echo "shot: nothing to crop to — kept the whole picture at $out" >&2
      rm -f "$hier"; return "$rc"
    fi
  elif [ -n "$crop" ]; then
    rect=$(printf '%s' "$crop" | tr ',' ' ')
  fi
  rm -f "$hier"

  local args=()
  [ "$rot" = 0 ] || args+=(--rotate "$rot")
  if [ -n "$rect" ]; then
    # Padded, then clamped to the screen, then scaled to pixels. Without the
    # clamp a padded rect at the edge of the screen asks for pixels that are
    # not in the file, and the crop silently comes back the wrong size.
    args+=(--crop "$(python3 -c "
import sys
x, y, w, h = (float(v) for v in sys.argv[1:5])
pad, sw, sh, sf = (float(v) for v in sys.argv[5:9])
x0, y0 = max(0.0, x - pad), max(0.0, y - pad)
x1, y1 = min(sw, x + w + pad), min(sh, y + h + pad)
print('%g,%g,%g,%g' % (x0 * sf, y0 * sf, (x1 - x0) * sf, (y1 - y0) * sf))" \
      $rect "$grow" "$SCREEN_W" "$SCREEN_H" "$sf")")
  fi
  [ -z "$scale" ] || args+=(--scale "$scale")
  [ ${#args[@]} -gt 0 ] || { echo "$out"; return 0; }
  "$HERE/img.sh" "$out" "${args[@]}"
}

# --- journey files ----------------------------------------------------------
# A journey is a plain list of the actions above, one per line, `#` for
# comments and ${VAR} expanded from the environment. `include` chains another
# journey, resolved relative to the including file. Journeys live wherever you
# put them — nothing here ships one, and nothing here knows about any
# particular app. See journeys/README.md for the command list.

_journey_seen=""

_journey() {  # _journey <file> <depth>
  local file=$1 depth=${2:-0} here line n=0 rc fd
  [ -r "$file" ] || { echo "journey: cannot read $file" >&2; return 1; }
  here=$(cd "$(dirname "$file")" && pwd)/$(basename "$file")
  case " $_journey_seen " in
    *" $here "*) echo "journey: $file includes itself (cycle)" >&2; return 1 ;;
  esac
  [ "$depth" -gt 10 ] && { echo "journey: includes nested deeper than 10" >&2; return 1; }
  _journey_seen="$_journey_seen $here"

  # Read the file on its own auto-assigned fd, never stdin. A verb can shell out
  # to ssh (via _ssh, which passes stdin through to the remote by design — see
  # lib.sh), and an ssh on fd 0 would swallow the rest of the journey and end the
  # loop cleanly with status 0 — a run reporting success on a screen it never
  # reached, the worst failure this toolkit can have (item 36). The fd is
  # per-call, so nested `include`s each get their own and do not clobber the
  # parent's read. fd is closed on the normal end and the failure path below;
  # the argument-error returns abort the whole run, so their leak dies with it.
  exec {fd}< "$file" || { echo "journey: cannot read $file" >&2; return 1; }
  while IFS= read -r -u "$fd" line; do
    n=$((n + 1))
    case "${line#"${line%%[![:space:]]*}"}" in ''|'#'*) continue ;; esac
    local -a a
    # Split the line first, then expand ${VAR} inside each token — see
    # bin/jtok.py for why that order matters. One consequence worth knowing
    # here: the log below echoes the line as written, so ${APP_PIN} is no longer
    # printed in full on every step that uses it.
    mapfile -d '' -t a < <(printf '%s' "$line" | python3 "$HERE/jtok.py") || return 2
    rc=0
    case "${a[0]}" in
      tapon)      _tapon "${a[@]:1}" || rc=$? ;;
      tapon?)     _resolve "${a[1]}" >/dev/null 2>&1 && _tapon "${a[1]}" "${a[2]:-}" || true ;;
      scrollto)   [ "${#a[@]}" -ge 2 ] || { echo "journey: $file:$n — scrollto needs a pattern" >&2; return 2; }
                  _scrollto "${a[1]}" "${a[2]:-down}" "${a[3]:-20}" || rc=$? ;;
      tap)        _post touch "{\"x\":${a[1]},\"y\":${a[2]}}" >/dev/null && _settle || rc=$? ;;
      # Both take the rest of the line, so they mean here what they mean from
      # the command line. Quoting is still the clearer way to write it, but
      # forgetting it no longer silently shortens what gets typed.
      type)       [ "${#a[@]}" -ge 3 ] || { echo "journey: $file:$n — type needs a pattern and some text" >&2; return 2; }
                  _type "${a[1]}" "${a[*]:2}" || rc=$? ;;
      text)       [ "${#a[@]}" -ge 2 ] || { echo "journey: $file:$n — text needs something to type" >&2; return 2; }
                  _post inputText "{\"text\":$(printf '%s' "${a[*]:1}" |
                    python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))'),$_appids}" >/dev/null &&
                    _settle || rc=$? ;;
      key)        _post pressKey "{\"key\":\"${a[1]}\"}" >/dev/null && _settle || rc=$? ;;
      button)     _post pressButton "{\"button\":\"${a[1]}\"}" >/dev/null && _settle || rc=$? ;;
      erase)      if [ "${a[1]:-}" = "--all" ]; then
                    _post eraseText "{\"charactersToErase\":9999,$_appids}" >/dev/null || rc=$?
                  else
                    _post eraseText "{\"charactersToErase\":${a[1]:-50},$_appids}" >/dev/null || rc=$?
                  fi ;;
      clear)      [ "${#a[@]}" -ge 2 ] || { echo "journey: $file:$n — clear needs a pattern" >&2; return 2; }
                  _clear "${a[1]}" "${a[2]:-}" || rc=$? ;;
      swipe)      _post swipeV2 "{\"appId\":\"$APP_ID\",\"startX\":${a[1]},\"startY\":${a[2]},\"endX\":${a[3]},\"endY\":${a[4]},\"duration\":${a[5]:-0.4},$_appids}" >/dev/null &&
                    _settle || rc=$? ;;
      dismiss)    _dismiss "${a[1]:-}" || rc=$? ;;
      expect)     case "${a[2]:-}" in
                    enabled|disabled) _expect "${a[1]}" "${a[2]}" "${a[3]:-}" || rc=$? ;;
                    *)                _expect "${a[1]}" "" "${a[2]:-}" || rc=$? ;;
                  esac ;;
      expect-not) _expect "${a[1]}" absent "${a[2]:-}" || rc=$? ;;
      expect-cmd) [ "${#a[@]}" -ge 2 ] || { echo "journey: $file:$n — expect-cmd needs a command and a timeout" >&2; return 2; }
                  _expect_cmd "${a[1]}" "${a[2]:-30}" || rc=$? ;;
      settle)     _settle "${a[1]:-10}" || rc=$? ;;
      wait)       sleep "${a[1]}" ;;
      launch)     _post launchApp "{\"bundleId\":\"${a[1]:-$APP_ID}\"}" >/dev/null && _settle 30 || rc=$? ;;
      kill)       _post terminateApp "{\"appId\":\"${a[1]:-$APP_ID}\"}" >/dev/null || rc=$? ;;
      log)        echo "  ${a[*]:1}" ;;
      include)    _journey "$(dirname "$file")/${a[1]}" "$((depth + 1))" || rc=$? ;;
      include-if) [ "${#a[@]}" -ge 3 ] || { echo "journey: $file:$n — include-if needs a pattern and a file" >&2; return 2; }
                  if _resolve "${a[1]}" >/dev/null 2>&1; then
                    _journey "$(dirname "$file")/${a[2]}" "$((depth + 1))" || rc=$?
                  fi ;;
      include-if-not) [ "${#a[@]}" -ge 3 ] || { echo "journey: $file:$n — include-if-not needs a pattern and a file" >&2; return 2; }
                  if ! _resolve "${a[1]}" >/dev/null 2>&1; then
                    _journey "$(dirname "$file")/${a[2]}" "$((depth + 1))" || rc=$?
                  fi ;;
      clearstate) _ssh "sh '$PLATFORM_SH' uninstall '$(_dev)' '$APP_ID'; echo cleared" || rc=$? ;;
      *)          echo "journey: $file:$n unknown command '${a[0]}'" >&2; return 1 ;;
    esac
    if [ "$rc" -ne 0 ]; then
      echo "journey: FAILED at $file:$n — $line" >&2
      echo "--- screen at the point of failure ---" >&2
      "$0" tree >&2
      exec {fd}<&-
      return "$rc"
    fi
    echo "  ok   $file:$n  $line"
  done
  # The loop ends at EOF unless something stopped it early. Assert the file was
  # actually exhausted: input still on the fd means the run did not reach the end,
  # which must fail loudly rather than pass (item 36).
  if IFS= read -r -u "$fd" line; then
    echo "journey: $file stopped after line $n with '$line' still to run — did not reach the end (item 36)" >&2
    exec {fd}<&-
    return 1
  fi
  exec {fd}<&-
}

# --- one call, one round trip -----------------------------------------------
# Two things that made exploration cost twice what it should (BACKLOG.md item 7).
#
# `--tree` / `--nodes` reads the screen back in the same invocation, so
# `tapon X` followed by a separate `nodes` becomes `tapon --tree X`. It goes
# directly after the verb, never at the end: `type` takes the rest of the line
# as the text to type, and a flag on the end would be typed rather than obeyed.
#
# The read still happens when the action fails. That is the moment you most
# want to see the screen, and the action's own exit status is unaffected.
CMD=${1:-start}
THEN=
case "${1:-}" in
  tap|tapon|type|text|key|button|erase|swipe|launch|orient|dismiss|clear|scrollto)
    case "${2:-}" in
      --tree|--nodes|--text) THEN=${2#--}; set -- "$1" "${@:3}" ;;
    esac ;;
esac

case "${1:-start}" in
  start)  _start && echo "$BASE" ;;
  stop)   # There is no relay locally, so this verb has nothing to stop — and it
          # must not read as having stopped the driver, which is still up and is
          # bin/drivers.sh down's to take away.
          if _ports_here; then
            echo "no relay in local transport — nothing to stop. The driver itself: bin/drivers.sh down ${DEV}"
          else
            _ssh "pkill -f 'relay.py $DPORT ' && echo stopped || echo 'not running'"
          fi ;;
  info)   _start && curl -s -m 5 "$BASE/deviceInfo"; echo ;;
  hierarchy) _hier ;;
  tree|nodes|text) _tree "$1" ;;
  shot) shift; _shot "$@" ;;
  static)   _start && curl -s -m 10 "$BASE/isScreenStatic"; echo ;;
  keyboard) _post keyboard "{$_appids}"; echo ;;
  # Two answers, because the route gives only one of them (BACKLOG item 104).
  # runningApp takes a list of bundle ids and returns whichever is in front,
  # or com.apple.springboard when none of them is, so it cannot name any other
  # app: with Settings in front it said springboard on both phones. The screen
  # tree can, by the name on its application node.
  app)      _hier > "${LDIR:-${TMPDIR:-/tmp}}/app-hier.$$" || exit 1
            fg=$(python3 -c '
import json, sys
def w(n):
    if n.get("elementType") == 2 and n.get("label"):
        return n["label"]
    for c in n.get("children") or []:
        r = w(c)
        if r: return r
try:
    print(w(json.load(open(sys.argv[1])).get("axElement", {})) or "")
except Exception:
    print("")' "${LDIR:-${TMPDIR:-/tmp}}/app-hier.$$")
            rm -f "${LDIR:-${TMPDIR:-/tmp}}/app-hier.$$"
            ra=$(_post runningApp "{$_appids}" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("runningAppBundleId",""))
except Exception: print("")')
            echo "in front:      ${fg:-unknown (no application node in the tree)}"
            if [ "$ra" = "$APP_ID" ]; then echo "configured app $APP_ID: in front"
            else echo "configured app $APP_ID: not in front"; fi ;;
  tap)      [ $# -ge 3 ] || { echo "usage: $0 tap <x> <y> [seconds]" >&2; exit 2; }
            # a duration turns the tap into a long press, so only send one when asked
            if [ -n "${4:-}" ]; then _post touch "{\"x\":$2,\"y\":$3,\"duration\":$4}"
            else _post touch "{\"x\":$2,\"y\":$3}"; fi; echo ;;
  text)     shift; _post inputText "{\"text\":$(printf '%s' "$*" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))'),$_appids}"; echo ;;
  key)      _post pressKey "{\"key\":\"${2:?key name, e.g. delete / return}\"}"; echo ;;
  button)   _post pressButton "{\"button\":\"${2:?button name, e.g. home}\"}"; echo ;;
  erase)    if [ "${2:-}" = "--all" ]; then
              _post eraseText "{\"charactersToErase\":9999,$_appids}"; echo
            else
              _post eraseText "{\"charactersToErase\":${2:-50},$_appids}"; echo
            fi ;;
  clear)    _clear "${2:?usage: $0 clear <pattern> [index]}" "${3:-}" ;;
  scrollto) _scrollto "${2:?usage: $0 scrollto <pattern> [up|down|left|right] [max-swipes]}" "${3:-down}" "${4:-20}" ;;
  clearstate) _ssh "sh '$PLATFORM_SH' uninstall '$(_dev)' '$APP_ID'; echo cleared" ;;
  swipe)    [ $# -ge 5 ] || { echo "usage: $0 swipe <x1> <y1> <x2> <y2> [duration]" >&2; exit 2; }
            _post swipeV2 "{\"appId\":\"$APP_ID\",\"startX\":$2,\"startY\":$3,\"endX\":$4,\"endY\":$5,\"duration\":${6:-0.4},$_appids}"; echo ;;
  orient)   # camelCase on the wire; PORTRAIT / LANDSCAPE_LEFT are rejected
            _post setOrientation "{\"orientation\":\"${2:?portrait|landscapeLeft|landscapeRight|upsideDown}\"}"; echo ;;
  launch)   _post launchApp "{\"bundleId\":\"${2:-$APP_ID}\"}"; echo ;;
  kill)     _post terminateApp "{\"appId\":\"${2:-$APP_ID}\"}"; echo ;;
  find)     shift; _ensure_screen || exit 1
            pat=${1:?usage: $0 find <pattern> [--explain]}; shift
            _hier | python3 "$HERE/resolve.py" "$pat" \
              --width "$SCREEN_W" --height "$SCREEN_H" "$@" ;;
  rows)     shift; _ensure_screen || exit 1
            # Every match in draw order, one line each, with its visibility.
            # `find` diagnoses one element; this reads a list off the screen, and
            # an empty list is a result (n=0) rather than an error — a list that
            # has emptied is the finding a watcher exists to catch. BACKLOG 72.
            pat=${1:?usage: $0 rows <pattern> [--json] [--include-hidden]}; shift
            _hier | python3 "$HERE/resolve.py" "$pat" --rows \
              --width "$SCREEN_W" --height "$SCREEN_H" "$@" ;;
  watch)    shift
            case "${1:-}" in
              status) _watch_status ;;
              stop)   _watch_stop ;;
              "")     echo "usage: $0 watch <pattern> [--context <pat>] [--interval n] [--cycles n]" >&2
                      echo "       $0 watch status | stop" >&2; exit 2 ;;
              *)      _watch_start "$@" ;;
            esac ;;
  probe)    _probe ;;
  point)    _resolve "${2:?usage: $0 point <pattern> [index]}" "${3:-}" ;;
  tapon)    [ $# -ge 2 ] || { echo "usage: $0 tapon <pattern> [index] [--anyway]" >&2; exit 2; }
            shift; _tapon "$@" ;;
  type)     pat=${2:?usage: $0 type <pattern> <text...>}; shift 2
            [ $# -ge 1 ] || { echo "usage: $0 type <pattern> <text...>" >&2; exit 2; }
            # "$*" rather than "$1": `text` has always joined its arguments and
            # this quietly ignored everything after the first, which is the same
            # silent shortening the journey verbs had.
            _type "$pat" "$*" ;;
  blank)    shift; _blank "$@" ;;
  dismiss)  shift; _dismiss "$@" ;;
  expect)   case "${3:-}" in
              enabled|disabled) _expect "${2:?usage: $0 expect <pattern> [enabled|disabled] [timeout]}" "$3" "${4:-}" ;;
              *)                _expect "${2:?usage: $0 expect <pattern> [timeout]}" "" "${3:-}" ;;
            esac ;;
  expect-not) _expect "${2:?usage: $0 expect-not <pattern> [timeout]}" absent "${3:-}" ;;
  expect-cmd) _expect_cmd "${2:?usage: $0 expect-cmd <command> [timeout]}" "${3:-30}" ;;
  settle)   _settle "${2:-10}" ;;
  script)   shift
            # --steps runs a sequence with no file. SKILL.md has always said to
            # "recompose units on the command line", and until 17 Sep 2026 there
            # was no way to: `script` took file names only, so trying a variant
            # meant writing a scratch .journey into $TMPDIR. One session wrote
            # six of them in an afternoon — invisible to the project, untested,
            # and a fresh set every time.
            if [ "${1:-}" = --steps ]; then
              [ $# -ge 2 ] || { echo "usage: $0 script --steps 'tapon \"^X$\"; expect \"^Y$\"'" >&2; exit 2; }
              shift
              _tmp_journey=$(mktemp "${LDIR:-${TMPDIR:-/tmp}}/steps-XXXXXX.journey")
              # `;` separates steps; a newline works too, so a quoted multi-line
              # argument is the same thing written out.
              printf '%s\n' "$*" | tr ';' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' > "$_tmp_journey"
              echo "== --steps ($(grep -c . "$_tmp_journey") steps)"
              _journey "$_tmp_journey" 0; _rc=$?
              rm -f "$_tmp_journey"
              exit $_rc
            fi
            [ $# -ge 1 ] || { echo "usage: $0 script <journey> [journey...] | $0 script --steps '<step>; <step>'" >&2; exit 2; }
            for j in "$@"; do
              # a bare name resolves in the project's journey directory, so a
              # journey can be named rather than pathed from wherever you are
              [ -r "$j" ] || { [ -r "$JOURNEY_DIR/$j" ] && j="$JOURNEY_DIR/$j"; }
              echo "== $j"
              _journey "$j" 0 || exit $?
            done ;;
  *) echo "usage: $0 [start|stop|info|hierarchy|tree|nodes|shot <file> [--raw|--on <pat>|--crop x,y,w,h|--scale pct]|static|keyboard|app|find <pat>|rows <pat>|probe|watch <pat>|watch status|watch stop|point <pat>|blank|dismiss [--no-key]|tapon <pat>|type <pat> <text...>|clear <pat>|scrollto <pat> [dir] [max]|clearstate|expect[-not] <pat>|settle|script <journey...>|script --steps '<step>; <step>'|tap <x> <y>|text <s>|key <name>|button <name>|erase [n|--all]|swipe <x1> <y1> <x2> <y2>|orient <o>|launch [id]|kill [id]]
       every action verb takes --tree or --nodes directly after the verb, which
       prints the screen once the action has settled: $0 tapon --tree '^SAVE\$'
       the action verbs wait for the screen to go still by themselves — do not
       add a sleep. SETTLE=0 turns that wait off, SETTLE=<n> shortens it." >&2; exit 2 ;;
esac
rc=$?

# The journey verbs have always waited for the screen to go still; the CLI ones
# did not, so a caller had to guess a sleep after every tap. Measured across
# four sessions, 42 sleeps were covering exactly this gap and 112 more were
# added after `tapon` and `type`, which already waited. Now everything waits.
#
# A settle timeout does not fail the verb. The tap happened; the screen merely
# has not stopped moving, `_settle` has already said so on stderr, and the
# caller is testing whether the action went through. Journeys keep the stricter
# rule, because a batch running on into a moving screen is how one goes wrong.
case "$CMD" in
  # launch gets the longer wait the journey verb has always used: a cold start
  # is the slowest thing here and 20 s has not always been enough for one.
  launch) [ "$rc" -eq 0 ] && { _settle "${SETTLE:-30}" || true; } ;;
  tap|text|key|button|erase|swipe|orient) [ "$rc" -eq 0 ] && { _settle || true; } ;;
esac
[ -n "$THEN" ] && _tree "$THEN"
exit $rc
