#!/bin/bash
# Republish the Mac's loopback-bound Dart VM Service on its LAN interface, so
# it can be read directly from a Bash call instead of over SSH.
#
#   ./publish.sh          # start (or reuse) the relay, print the local base URI
#   ./publish.sh status
#   ./publish.sh stop
#
# Measured: 0.050s a read this way, 0.368s over SSH. The relay is the Mac's own
# process, so unlike a tunnel it survives across our calls (reference/connection.md).
#
# Starting also turns dart:io HTTP profiling on, because it is OFF by default
# and nothing says so: bin/net.sh comes back with an empty request list that
# looks exactly like an app making no calls. That cost one session six minutes
# and another the whole line of evidence — it read the source instead and never
# found out why. The flag lives on the isolate, so it has to be set again after
# anything that replaces the isolate: a restart, a hot restart, clearState.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

: "${PUBPORT:=9100}"
# State is kept per device so concurrent reviews of different branches or
# simulators do not overwrite each other's base URI and isolate id (item 24).
# The suffix is the selected device; when none can be resolved it falls back to
# the shared name, so a single-device session behaves exactly as before.
_dsuffix() { local dv=${DEV:-}; [ -n "$dv" ] || dv=$(_dev 2>/dev/null) || dv=; printf '%s' "$dv"; }
_sfx=$(_dsuffix)
STATE="$LDIR/published${_sfx:+-$_sfx}.state"

# Finding the app's debug endpoint, and arming its traffic capture, are the
# framework's job — the Dart VM Service for Flutter, Metro for React Native,
# nothing at all for a plain Xcode app (BACKLOG item 87, call site 4). Publishing
# it is not: relay.py forwards a loopback port to the LAN and does not care what
# is behind it, so the relay, the state file and the per-device suffix stay here.
HERE=$(cd "$(dirname "$0")" && pwd)
FW_LOCAL=$("$HERE/runner.sh" path framework) || exit 1
FW_REMOTE=$("$HERE/runner.sh" rpath framework) || exit 1

# _vm <base> <rpc-with-query>   — a VM Service call through the sandbox proxy.
# Kept for the by-hand recipe _report prints; nothing above it uses it now.
_vm() { curl -s -x "$grpc_proxy" --max-time 8 "$1/$2" 2>/dev/null; }

# "<was> <now>", each on|off|unknown. The module runs here in the sandbox and
# reaches the published relay through $grpc_proxy.
_arm() { # _arm <base> <isolate>
  sh "$FW_LOCAL" traffic-arm "$1" "$2" 2>/dev/null || true
}

# Everything a later ad-hoc call needs, in one place. Both sessions reviewed on
# 12 Aug went hunting through lib.sh and config.sh for $LDIR before they could
# make a single VM Service call of their own — five and six round trips.
_report() { # _report <base> <isolate> <profiling-state>
  cat <<TXT
  base URI    $1
  isolate     $2
  profiling   $3
  state file  $STATE

  read it:    $(dirname "$0")/net.sh            # list requests
              $(dirname "$0")/net.sh <id>       # one request in full
  by hand:    read -r BASE ISO < "$STATE"
              curl -s -x "\$grpc_proxy" "\$BASE/getVM"
TXT
}
# MAC_HOST may name several aliases (item 18); ssh -G takes a single host, and
# given the whole list it returns no hostname, so MACIP comes back empty and the
# published URI is built with no host at all — http://:9100/... (item 39). Narrow
# to the alias that answers first (a no-op for a single-host config), then read
# its LAN IP.
_pick_host
MACIP=$(ssh -G "$MAC_HOST" 2>/dev/null | awk '/^hostname /{print $2}')
[ -n "$MACIP" ] || { echo "could not resolve a LAN IP for '$MAC_HOST' — ssh -G returned no hostname" >&2; exit 1; }

case "${1:-start}" in
  stop)
    _ssh "pkill -f 'relay.py $PUBPORT' && echo stopped || echo 'nothing running'"
    rm -f "$STATE"
    ;;
  status)
    read -r BASE ISO < "$STATE" 2>/dev/null || { echo "nothing published — run: $0"; exit 1; }
    if [ -n "$BASE" ] && _vm "$BASE" getVersion | grep -q '"type"'; then
      echo "reachable"
      _report "$BASE" "$ISO" "$(_arm "$BASE" "$ISO" | awk '{print $2}')"
    else
      echo "not reachable — the app has probably restarted. Re-run: $0" ; exit 1
    fi
    ;;
  start)
    d=$(_dev) || exit 1
    STATE="$LDIR/published-$d.state"      # the resolved device is authoritative here
    # No pipe on the remote side. `| tail -1` there would hand back tail's exit
    # status, which is always 0, and the whole point here is telling an exit 2
    # ("this framework has no debug endpoint") from an exit 1 ("it has one and
    # the app is not running under it"). Tail locally instead.
    V=$(_ssh "RDIR='$RDIR' sh '$FW_REMOTE' inspect '$d' '$RDIR/vmservice-$d'")
    _rc=$?
    V=$(printf '%s\n' "$V" | tail -1)
    if [ "$_rc" = 2 ]; then
      echo "the ${RUNNER:-?} runner has no debug endpoint to publish, so there is" >&2
      echo "  nothing for the relay to point at and bin/net.sh will stay empty." >&2
      echo "  That is a fact about this framework, not a broken relay." >&2
      exit 2
    fi
    [ "$_rc" = 0 ] || exit 1
    VBASE=${V%% *}; ISO=${V##* }
    [ -n "$VBASE" ] || { echo "no debug endpoint — is a dev session running? bin/preflight.sh says." >&2; exit 1; }
    RPORT=$(printf '%s' "$VBASE" | sed -E 's|.*:([0-9]+)/.*|\1|')
    RPATH=$(printf '%s' "$VBASE" | sed -E 's|.*:[0-9]+||')

    _ssh "pkill -f 'relay.py $PUBPORT' 2>/dev/null
          nohup python3 '$RDIR/relay.py' $PUBPORT $RPORT >/dev/null 2>&1 &
          sleep 1
          lsof -nP -iTCP:$PUBPORT -sTCP:LISTEN >/dev/null 2>&1 && echo 'relay up' || echo 'relay FAILED'"

    printf 'http://%s:%s%s %s\n' "$MACIP" "$PUBPORT" "$RPATH" "$ISO" > "$STATE"
    read -r PBASE _ < "$STATE"

    read -r was now <<< "$(_arm "$PBASE" "$ISO")"
    was=${was:-unknown}; now=${now:-unknown}
    case "$was:$now" in
      off:on) note="was off, now on — only calls made from here on are captured" ;;
      on:on)  note="already on" ;;
      *)      note="could not be set ($was -> $now); net.sh may come back empty" ;;
    esac

    _report "$PBASE" "$ISO" "$now  ($note)"
    ;;
  *) echo "usage: publish.sh [start|status|stop]" >&2; exit 2 ;;
esac
