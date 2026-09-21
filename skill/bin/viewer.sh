#!/bin/bash
# Republish a Maestro Viewer on the Mac's LAN interface.
#
#   ./bin/viewer.sh          # find the live viewers, republish one, print the URL
#   ./bin/viewer.sh list     # which viewers are running, and on which port
#   ./bin/viewer.sh stop
#
# **To watch simulators, use bin/wall.sh, not this.** Maestro's viewer hands the
# browser a device stream at an absolute `http://127.0.0.1:<random>/stream.mjpeg`,
# so the picture is fetched from whatever machine the browser is on and a remote
# browser gets nothing. No relay can fix that. It also attaches a device only
# when exactly one simulator is booted. bin/wall.sh serves every simulator from
# one port of its own and has neither problem. Backlog 64, 65.
#
# What is left here is the rest of the viewer — its command rows and its device
# list — which do work through a relay, for a session that wants them.
#
# The port is discovered, never assumed. `maestro mcp` starts its viewer on "a
# free local port" unless `--viewer-port` says otherwise, so every session gets
# a different one: two sessions on 15 Sep held 9999 and 10001. $VPORT is only
# the port this republishes *on*.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)

# Every live viewer, as "port devices". A Maestro MCP server's viewer is the
# listening socket that answers /api/device/targets.
_viewer_ports() {
  _ssh '
for p in $(pgrep -f "maestro.cli.AppKt mcp" 2>/dev/null); do
  for port in $(lsof -nP -a -p "$p" -iTCP -sTCP:LISTEN 2>/dev/null |
                sed -nE "s|.*TCP 127\.0\.0\.1:([0-9]+) \(LISTEN\).*|\1|p"); do
    n=$(curl -s --max-time 4 "http://127.0.0.1:$port/api/device/targets" |
        grep -o "deviceId" | grep -c .)
    [ "${n:-0}" -gt 0 ] && echo "$port $n"
  done
done'
}

case "${1:-start}" in
  list)
    ports=$(_viewer_ports)
    if [ -z "$ports" ]; then
      echo "no Maestro viewer is running on $(_where)"
      echo "  one starts with every 'maestro mcp' — reconnect the MCP server, or run"
      echo "  maestro mcp --viewer-port=<port> yourself"
      exit 1
    fi
    echo "$ports" | while read -r port n; do
      echo "viewer on 127.0.0.1:$port — $n device(s) listed"
    done
    ;;

  stop)
    # Nothing is republished locally, so there is no relay to kill — and this
    # must not read as having stopped the viewer, which is Maestro's and lives
    # as long as the MCP server does.
    if [ "${TRANSPORT:-ssh}" = local ]; then
      echo "no relay in local transport — nothing to stop. The viewer belongs to 'maestro mcp'."
    else
      _ssh "pkill -f 'relay.py $VPORT ' && echo stopped || echo 'not running'"
    fi
    ;;

  start)
    ports=$(_viewer_ports)
    if [ -z "$ports" ]; then
      echo "no Maestro viewer is running on $(_where), so there is nothing to republish." >&2
      echo "  A viewer starts with every 'maestro mcp'. Reconnect the MCP server," >&2
      echo "  or start one yourself:  maestro mcp --viewer-port=<port>" >&2
      echo "  Do NOT run 'maestro studio' — it starts its own XCUITest driver and" >&2
      echo "  destroys the driver bin/drivers.sh is holding." >&2
      echo "  To watch simulators, use bin/wall.sh instead." >&2
      exit 1
    fi

    # Most devices listed wins; with one viewer that is simply the one there is.
    rport=$(echo "$ports" | sort -k2 -rn | head -1 | awk '{print $1}')

    if [ "${TRANSPORT:-ssh}" = local ]; then
      # The viewer is already on this machine's loopback and so is the browser
      # that reads it, so there is nothing to republish (item 94, 4.1) — and the
      # absolute 127.0.0.1 stream URL, which is why the picture is blank across
      # ssh and why bin/wall.sh exists, resolves here. $VPORT is the port this
      # republishes *on*, so it has no meaning either; the URL is the viewer's
      # own port.
      urls=("$VIEWER_URL" "http://127.0.0.1:$rport/")
      tried="${VIEWER_URL:+$VIEWER_URL, }127.0.0.1:$rport"
      blank_note=0
    else
      echo "republishing the viewer on 127.0.0.1:$rport" >&2

      _ssh "mkdir -p '$RDIR'"
      _push "$HERE/../remote/relay.py" "$RHELP/relay.py" || exit 1

      # relay.py explains its own failures on stderr. An earlier version sent them
      # to /dev/null and printed a guess instead, so the one line that said what
      # was wrong was never seen by anyone (backlog 64).
      _ssh "pkill -f 'relay.py $VPORT ' 2>/dev/null; sleep 1
cd '$RDIR' && nohup python3 '$RHELP/relay.py' $VPORT $rport > relay.log 2>&1 &
sleep 2
cat '$RDIR/relay.log'"

      ip=$(_macip) || ip=""
      urls=("$VIEWER_URL" "http://$(_urlhost):$VPORT/" "${ip:+http://$ip:$VPORT/}")
      tried="${VIEWER_URL:+$VIEWER_URL, }$(_urlhost)${ip:+, $ip}"
      blank_note=1
    fi

    for url in "${urls[@]}"; do
      [ -n "$url" ] || continue
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$url")
      if [ "$code" = "200" ]; then
        echo "$url"
        if [ "$blank_note" = 1 ]; then
          echo "note: the device picture will be blank from here — the viewer's stream" >&2
          echo "      URL is an absolute 127.0.0.1 address. Use bin/wall.sh to watch." >&2
        fi
        exit 0
      fi
    done
    if [ "${TRANSPORT:-ssh}" = local ]; then
      echo "the viewer is listed on port $rport but nothing answered there (tried $tried)" >&2
    else
      echo "the relay is up but nothing answered on port $VPORT (tried $tried)" >&2
    fi
    exit 1
    ;;

  *) echo "usage: $0 [start|list|stop]" >&2; exit 2 ;;
esac
