#!/bin/bash
# Physical-device drivers — the counterpart to bin/drivers.sh (simulators).
#
#   bin/device.sh up <udid> [port]   # forwarder + persistent driver, then register
#   bin/device.sh down <udid>        # tear both down, unregister
#   bin/device.sh list               # what is registered
#
# A phone's XCUITest driver binds its HTTP server ON THE PHONE, so it needs a
# usbmux forwarder the simulator path never does, and the device tunnel idles
# out in seconds. device.sh brings both up on the Mac (remote/deviceup.sh) and
# registers the device so bin/driver.sh drives it EXACTLY like a simulator:
#
#   bin/device.sh up 00008020-0011...          # once
#   DEV=00008020-0011... bin/driver.sh nodes   # then drive it as usual
#
# The prebuilt device driver must have been re-signed by hand first — Maestro
# 2.8.0 cannot build its own (physical-device.md §3). Everything physical-device
# is in physical-device.md; this is BACKLOG.md item 45's device path, and the
# ensure-driver recovery is item 46.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)

# Devices sit above the simulator port range so a phone and a booted simulator
# can never land on the same port.
: "${DEVICE_PORT_BASE:=22187}"

_register() {  # _register <udid> <port>
  { grep -v "^$1 " "$DEVICE_MAP" 2>/dev/null; echo "$1 $2 device"; } > "$DEVICE_MAP.tmp" &&
    mv -f "$DEVICE_MAP.tmp" "$DEVICE_MAP"
}
_unregister() {  # _unregister <udid>
  grep -v "^$1 " "$DEVICE_MAP" 2>/dev/null > "$DEVICE_MAP.tmp"
  mv -f "$DEVICE_MAP.tmp" "$DEVICE_MAP" 2>/dev/null || rm -f "$DEVICE_MAP.tmp"
}

case "${1:-list}" in
  up)
    udid=${2:?usage: device.sh up <udid> [port]}
    port=${3:-$DEVICE_PORT_BASE}
    # A phone is runners/ios-device's whatever PLATFORM says, because that is
    # what this script is for. The module carries deviceup.sh and iproxy.py and
    # bin/install.sh pushes all three together (BACKLOG item 87, 5.4).
    PL="$RMODS/ios-device/platform.sh"
    "$HERE/runner.sh" platform claim "$udid" 2>/dev/null ||
      PLATFORM=ios-device "$HERE/runner.sh" platform claim "$udid" >/dev/null 2>&1 || {
        echo "device: $udid is not a physical device udid — a simulator is bin/drivers.sh up" >&2
        exit 2; }
    _ssh "mkdir -p '$RMODS/ios-device'" >/dev/null
    scp "${SSH_OPTS[@]}" "$HERE/../runners/ios-device/platform.sh" \
        "$HERE/../runners/ios-device/deviceup.sh" "$HERE/../runners/ios-device/iproxy.py" \
        "$MAC_HOST:$RMODS/ios-device/" >/dev/null ||
      { echo "device: could not copy the ios-device module" >&2; exit 1; }
    # The driver cold-starts in tens of seconds; the default timeout is too short.
    out=$(TMO=${TMO:-180} _ssh "RDIR='$RDIR' sh '$PL' driver-up '$udid' '$port'"); rc=$?
    printf '%s\n' "$out"
    [ "$rc" -eq 0 ] || { echo "device: bring-up failed — not registered." >&2; exit "$rc"; }
    _register "$udid" "$port"
    echo "registered $udid on port $port"
    echo "drive it:  DEV=$udid $HERE/driver.sh nodes"
    ;;
  down)
    udid=${2:?usage: device.sh down <udid>}
    _ssh "sh '$RMODS/ios-device/platform.sh' driver-down '$udid'
          echo 'stopped driver and forwarder for $udid'"
    _unregister "$udid"
    echo "unregistered $udid"
    ;;
  list|"")
    if [ -s "$DEVICE_MAP" ]; then
      printf '%-40s %-7s %s\n' UDID PORT STATE
      # Read the whole map BEFORE the loop. `done < "$DEVICE_MAP"` puts the file
      # on the loop's stdin, and _ssh passes stdin to the remote command, so the
      # first probe ate the rest of the file and only one device was ever
      # listed. Found 17 Sep 2026 by bin/lint-stdin.py, which exists because the
      # same trap had just been walked into three times in one afternoon.
      rows=(); mapfile -t rows < "$DEVICE_MAP"
      for row in "${rows[@]}"; do
        set -- $row; u=${1:-}; p=${2:-}
        [ -n "$u" ] && [ -n "$p" ] || continue
        st=$(TMO=15 _ssh "curl -s -m 4 -o /dev/null -w '%{http_code}' http://127.0.0.1:$p/status 2>/dev/null")
        printf '%-40s %-7s %s\n' "$u" "$p" "$([ "$st" = 200 ] && echo up || echo "GONE (status=$st)")"
      done
    else
      echo "no physical devices registered — bin/device.sh up <udid>"
    fi
    ;;
  *) echo "usage: device.sh up <udid> [port] | down <udid> | list" >&2; exit 2 ;;
esac
