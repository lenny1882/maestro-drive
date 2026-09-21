#!/bin/bash
# Every booted simulator, live, on one page — one URL that never changes.
#
#   ./bin/wall.sh            # start (or restart), print the URL
#   ./bin/wall.sh stop
#   ./bin/wall.sh status
#   ./bin/wall.sh log        # the last of the wall's own log, on the Mac
#
#   ./bin/wall.sh label [<udid>] <name> [--group <g>]   # name a tile
#   ./bin/wall.sh unlabel [<udid>]                      # clear it
#
# A name says what is being driven — "Checkout flow, PR 101" — where the tile
# otherwise says only which handset. The session driving the simulator sets it,
# over the same SSH it drives through; the wall only reads. Each label records
# which session wrote it, so a wrong name on a shared Mac is traceable. Devices sharing a
# --group are shown together under a heading, so several projects on one Mac
# stay apart. bin/drivers.sh up sets a default, and down clears it.
#
# This replaces bin/viewer.sh for watching. Maestro's own viewer cannot be
# published: `maestro mcp` puts it on "a free local port" so no URL is stable,
# it only attaches a device when exactly one simulator is booted, one viewer
# holds one device, and the stream URL it hands the browser is an absolute
# 127.0.0.1 address on a random port that no relay can carry. remote/wall.py
# spawns Maestro's capture binary per device and re-serves every stream from
# this one port instead. Backlog 64 and 65.
#
# It needs SimulatorKit where the capture binary looks for it. Xcode 27 moved
# it, so `status` says so rather than leaving a blank page to explain itself.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)

# $WALLPORT is ours and never moves, which is the whole point of the wall, so
# the only thing that differs between the transports is which host to name —
# and WALL_URL still overrides both (item 94, 4.3).
_url() {
  [ -n "$WALL_URL" ] && { printf '%s' "$WALL_URL"; return; }
  printf 'http://%s:%s/' "$(_urlhost)" "$WALLPORT"
}

# Which interface the wall serves on. Across a network the browser is on another
# machine, so it must be every interface. Locally the browser is on this one,
# and a wall bound to 0.0.0.0 here would put every app screen on whatever
# network this machine is sitting on. WALL_URL means the wall is reached some
# other way — a tunnel, a reverse proxy — so it takes the open bind with it.
_bind() {
  if _ports_here && [ -z "$WALL_URL" ]; then printf '127.0.0.1'
  else printf '0.0.0.0'
  fi
}

# The capture binary loads Apple's private SimulatorKit from a path compiled
# into it. Xcode 27 dropped that directory. Nothing else in the wall can work
# until this is right, so it is checked first and reported in full.
_check_simulatorkit() {
  local out
  # Apple's private framework, loaded by Apple's capture binary. It is not a
  # question about the wall, it is a question about iOS — and it was the first
  # thing `start` and `status` did, so on any other platform the wall refused to
  # start over a framework that has nothing to do with it. Found running 4.3
  # against this Linux machine, where PLATFORM is android.
  [ "${PLATFORM:-ios}" = ios ] || return 0
  out=$(_ssh '~/.maestro/deps/simulator-server verify 2>&1 | grep -E "^\[[a-z]+\] ios:"')
  case "$out" in
    \[ok\]*) return 0 ;;
    "")      echo "could not run simulator-server verify on $(_where)" >&2; return 1 ;;
    *)
      cat >&2 <<MSG
$out

Maestro's capture binary loads SimulatorKit from a path compiled into it, and
Xcode 27 moved the framework to Contents/SharedFrameworks. Put the path back:

  sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks
  sudo ln -s /Applications/Xcode.app/Contents/SharedFrameworks/SimulatorKit.framework \\
             /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/

Xcode is an App Store install, so an Xcode update removes the symlink again.
MSG
      return 1 ;;
  esac
}

case "${1:-start}" in
  label)
    shift
    udid=""; name=""; group=""
    # The udid is optional and positional, so it is recognised by shape rather
    # than by a flag — anything that is not 36 characters of hex is the name.
    if [ $# -gt 0 ] && printf '%s' "$1" | grep -qE '^[0-9A-Fa-f-]{36}$'; then
      udid=$1; shift
    fi
    # Everything that is not a udid and not --group used to fall through to the
    # catch-all and BECOME the label, so `wall.sh label --help` set the label to
    # "--help" instead of printing this usage line, and a mistyped --groupp
    # wrote itself into the name. Neither said anything: both exit 0 and print
    # the label they just wrote as though it were what was asked for.
    #
    # The cost is not the wrong text, it is whose device it lands on. With no
    # udid the label goes to whatever _dev resolves to, which on a Mac two
    # sessions are sharing is whichever device has a driver up — reported
    # 18 Sep 2026 by the sister project's session, which ran `label --help` to
    # check the syntax and overwrote a peer's label doing it. Item 67 exists
    # because a label is evidence of who is driving what; this erased it by
    # accident, from a command whose intent was to read the usage.
    _label_usage() { echo "usage: $0 label [<udid>] <name> [--group <g>]"; }
    endflags=0
    while [ $# -gt 0 ]; do
      if [ "$endflags" = 1 ]; then
        name="${name:+$name }$1"; shift; continue
      fi
      case "$1" in
        # A label that genuinely starts with a dash goes after --, which is the
        # convention every other tool uses and the reason an unknown flag can be
        # refused rather than absorbed.
        --) endflags=1; shift ;;
        -h|--help) _label_usage; exit 0 ;;
        --group) [ $# -ge 2 ] || { echo "label: --group needs a value" >&2; exit 2; }
                 group=$2; shift 2 ;;
        --group=*) group=${1#--group=}; shift ;;
        -*) echo "label: unknown option $1" >&2
            _label_usage >&2
            echo "  a label starting with a dash goes after --:  $0 label -- $1" >&2
            exit 2 ;;
        *) name="${name:+$name }$1"; shift ;;
      esac
    done
    [ -n "$name" ] || { _label_usage >&2; exit 2; }
    [ -n "$udid" ] || udid=$(_dev) || exit 1
    printf 'name=%s\ngroup=%s\nby=%s\n' "$name" "$group" "$(_label_by)" |
      _ssh "mkdir -p '$RDIR/labels' && cat > '$RDIR/labels/$udid'" || exit 1
    echo "$udid: $name${group:+  (group: $group)}"
    ;;

  unlabel)
    shift
    udid=${1:-}
    [ -n "$udid" ] || udid=$(_dev) || exit 1
    _ssh "rm -f '$RDIR/labels/$udid'" && echo "$udid: label cleared"
    ;;

  stop)
    _ssh "pkill -f 'wall.py $WALLPORT' && echo stopped || echo 'not running'"
    ;;

  status)
    _check_simulatorkit
    _ssh "pgrep -f 'wall.py $WALLPORT' >/dev/null && echo 'wall: running' || echo 'wall: not running'"
    url=$(_url)
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$url")
    echo "$url -> HTTP $code"
    [ "$code" = "200" ] && _ssh "curl -s --max-time 8 http://127.0.0.1:$WALLPORT/api/devices"
    echo
    ;;

  log)
    _ssh "tail -n 40 '$RDIR/wall.log' 2>/dev/null || echo 'no log yet'"
    ;;

  start)
    _check_simulatorkit || exit 1
    _ssh "mkdir -p '$RDIR' '$RHELP' '$RMODS/${PLATFORM:-ios}'"
    _push "$HERE/../remote/wall.py" "$RHELP/wall.py" || exit 1
    # wall.py asks the platform which devices exist and what streams one, and it
    # looks for the module beside itself. Sent here as well as by bin/install.sh
    # so that starting the wall never depends on install.sh having been run.
    _push "$HERE/../runners/${PLATFORM:-ios}/platform.sh" \
          "$RMODS/${PLATFORM:-ios}/platform.sh" || exit 1

    # Start it, then show what it said. viewer.sh sent the remote script's
    # stderr to /dev/null, so the one line explaining a failure — "no service on
    # port N to republish" — was never seen by anyone. Do not repeat that.
    _ssh "pkill -f 'wall.py $WALLPORT' 2>/dev/null; sleep 1
cd '$RDIR' && nohup python3 '$RHELP/wall.py' $WALLPORT $(_bind) > wall.log 2>&1 &
sleep 6
tail -n 20 '$RDIR/wall.log'"

    url=$(_url)
    for _ in 1 2 3 4 5; do
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$url")
      [ "$code" = "200" ] && { echo; echo "$url"; exit 0; }
      sleep 2
    done
    echo "the wall did not answer on $url (HTTP $code)" >&2
    echo "  its own log:  $0 log" >&2
    exit 1
    ;;

  *) echo "usage: $0 [start|stop|status|log|label|unlabel]" >&2; exit 2 ;;
esac
