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

# "<was> <now>", each on|off|unknown. The module runs here rather than on the
# machine with the device, and reaches the endpoint through $grpc_proxy across
# ssh and directly in local transport — it reads the variable lib.sh sets.
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
# Locally there is nothing to resolve and no ssh to ask. The endpoint and
# whatever reads the published URL are both on this machine, and since 4.1 there
# is no relay in between either — so `start` writes the endpoint's own port on
# the loopback and MACIP is never read. Asking ssh -G for a host that is not in
# the conf would fail on a question with no reason to be asked.
if _ports_here; then
  :
elif [ "$TRANSPORT" = bridge ]; then
  # The device is on this machine and this process still cannot reach its
  # loopback, so the published URI names the machine the way the ssh transport
  # names the Mac (item 96).
  MACIP=$(_macip) || exit 1
else
  _pick_host
  MACIP=$(ssh -G "$MAC_HOST" 2>/dev/null | awk '/^hostname /{print $2}')
  [ -n "$MACIP" ] || { echo "could not resolve a LAN IP for '$MAC_HOST' — ssh -G returned no hostname" >&2; exit 1; }
fi

case "${1:-start}" in
  stop)
    # No relay was started locally, so there is nothing to kill — but the state
    # file is real either way and stop's job is to make the next status say
    # "nothing published" rather than point at an endpoint nobody is watching.
    if _ports_here; then
      echo "no relay in local transport — cleared the published endpoint"
    else
      _ssh "pkill -f 'relay.py $PUBPORT' && echo stopped || echo 'nothing running'"
    fi
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

    # Locally the endpoint the framework just reported IS reachable from here —
    # it is bound to this machine's loopback, which is the one this script
    # curls. So there is no relay to start and $PUBPORT names nothing: the
    # published URI is the debug endpoint's own port (item 94, 4.1). The state
    # file, the per-device suffix and the arming below are unchanged, because
    # they are about the app and not about the transport.
    if _ports_here; then
      printf 'http://127.0.0.1:%s%s %s\n' "$RPORT" "$RPATH" "$ISO" > "$STATE"
    else
      _ssh "pkill -f 'relay.py $PUBPORT' 2>/dev/null
          nohup python3 '$RHELP/relay.py' $PUBPORT $RPORT >/dev/null 2>&1 &
          sleep 1
          lsof -nP -iTCP:$PUBPORT -sTCP:LISTEN >/dev/null 2>&1 && echo 'relay up' || echo 'relay FAILED'"

      printf 'http://%s:%s%s %s\n' "$MACIP" "$PUBPORT" "$RPATH" "$ISO" > "$STATE"
    fi
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
