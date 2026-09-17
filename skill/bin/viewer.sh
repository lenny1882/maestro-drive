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
      echo "no Maestro viewer is running on $MAC_HOST"
      echo "  one starts with every 'maestro mcp' — reconnect the MCP server, or run"
      echo "  maestro mcp --viewer-port=<port> yourself"
      exit 1
    fi
    echo "$ports" | while read -r port n; do
      echo "viewer on 127.0.0.1:$port — $n device(s) listed"
    done
    ;;

  stop)
    _ssh "pkill -f 'relay.py $VPORT ' && echo stopped || echo 'not running'"
    ;;

  start)
    ports=$(_viewer_ports)
    if [ -z "$ports" ]; then
      echo "no Maestro viewer is running on $MAC_HOST, so there is nothing to republish." >&2
      echo "  A viewer starts with every 'maestro mcp'. Reconnect the MCP server," >&2
      echo "  or start one yourself:  maestro mcp --viewer-port=<port>" >&2
      echo "  Do NOT run 'maestro studio' — it starts its own XCUITest driver and" >&2
      echo "  destroys the driver bin/drivers.sh is holding." >&2
      echo "  To watch simulators, use bin/wall.sh instead." >&2
      exit 1
    fi

    # Most devices listed wins; with one viewer that is simply the one there is.
    rport=$(echo "$ports" | sort -k2 -rn | head -1 | awk '{print $1}')
    echo "republishing the viewer on 127.0.0.1:$rport" >&2

    _ssh "mkdir -p '$RDIR'"
    scp "${SSH_OPTS[@]}" "$HERE/../remote/relay.py" "$MAC_HOST:$RDIR/relay.py" >/dev/null || exit 1

    # relay.py explains its own failures on stderr. An earlier version sent them
    # to /dev/null and printed a guess instead, so the one line that said what
    # was wrong was never seen by anyone (backlog 64).
    _ssh "pkill -f 'relay.py $VPORT ' 2>/dev/null; sleep 1
cd '$RDIR' && nohup python3 relay.py $VPORT $rport > relay.log 2>&1 &
sleep 2
cat '$RDIR/relay.log'"

    ip=$(_macip) || ip=""
    for url in "$VIEWER_URL" "http://$MAC_FQDN:$VPORT/" "${ip:+http://$ip:$VPORT/}"; do
      [ -n "$url" ] || continue
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$url")
      if [ "$code" = "200" ]; then
        echo "$url"
        echo "note: the device picture will be blank from here — the viewer's stream" >&2
        echo "      URL is an absolute 127.0.0.1 address. Use bin/wall.sh to watch." >&2
        exit 0
      fi
    done
    echo "the relay is up but nothing answered on port $VPORT (tried ${VIEWER_URL:+$VIEWER_URL, }$MAC_FQDN${ip:+, $ip})" >&2
    exit 1
    ;;

  *) echo "usage: $0 [start|list|stop]" >&2; exit 2 ;;
esac
