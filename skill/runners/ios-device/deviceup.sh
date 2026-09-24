#!/bin/bash
# Bring up a PERSISTENT XCUITest driver for a physical device, plus the usbmux
# forwarder that makes it reachable from the Mac. Runs ON THE MAC. Called by
# bin/device.sh; not useful from the sandbox.
#
#   deviceup.sh <udid> <port> [workdir]
#
# This is remote/driverup.sh's device counterpart. The launch is identical —
# xcodebuild test-without-building against the re-signed driver products, with
# TEST_RUNNER_PORT choosing the port — with two device-only extras: a usbmux
# forwarder (iproxy.py, beside this file), because the driver's HTTP server binds
# the phone's loopback not the Mac's; and a devicectl tunnel wake immediately
# before, because the tunnel idles out in seconds (physical-device.md §4, §5).
#
# The driver products are the PREBUILT driver-iphoneos, re-signed by hand once
# (physical-device.md §3) because Maestro 2.8.0 cannot build its own device
# driver. If they are missing, this says so rather than trying to build them.
set -uo pipefail
UDID=${1:?usage: deviceup.sh <udid> <port> [workdir]}
PORT=${2:?port}
WORK=${3:-/tmp/maestro-mac}
HERE=$(cd "$(dirname "$0")" && pwd)
XCTR="$HOME/.maestro/maestro-iphoneos-driver-build/driver-iphoneos/Build/Products/maestro-driver-ios-config.xctestrun"

[ -r "$XCTR" ] || { echo "no re-signed device driver at:" >&2
  echo "  $XCTR" >&2
  echo "It is the prebuilt driver-iphoneos, re-signed by hand — see physical-device.md §3." >&2
  exit 1; }

# A locked phone cannot run XCUITest and fails as a connection error, not a lock
# — the single most common way this goes wrong (measured 10 Sep 2026). Refuse
# with the real reason rather than letting it surface as "driver not ready".
case "$(xcrun devicectl device info lockState --device "$UDID" 2>/dev/null | grep -i passcodeRequired)" in
  *[Tt]rue*) echo "the phone is LOCKED (passcodeRequired: true) — unlock it and retry." >&2
             echo "XCUITest cannot attach to a locked screen." >&2; exit 1 ;;
esac

mkdir -p "$WORK"

# The forwarder: Mac 127.0.0.1:PORT -> device 127.0.0.1:PORT. One per device.
if ! pgrep -f "iproxy.py $UDID $PORT" >/dev/null 2>&1; then
  nohup python3 "$HERE/iproxy.py" "$UDID" "$PORT" > "$WORK/iproxy-$PORT.log" 2>&1 &
  sleep 2
  grep -q forwarding "$WORK/iproxy-$PORT.log" 2>/dev/null || {
    echo "forwarder did not bind:" >&2; cat "$WORK/iproxy-$PORT.log" >&2; exit 1; }
fi

# Wake the tunnel immediately before the driver — it drops to idle in seconds,
# and any devicectl call wakes it.
xcrun devicectl device info lockState --device "$UDID" >/dev/null 2>&1

# Already serving on this port? Leave it — relaunching drops whatever the caller
# is part-way through.
if [ "$(curl -s -m 4 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/status" 2>/dev/null)" = 200 ]; then
  echo "already up on $PORT"; exit 0
fi

# One log per phone. A shared ~/devdrv.log was truncated by the second phone's
# bring-up while the first phone's xcodebuild was still appending to it, so a
# failure on either named the other's lines (BACKLOG item 99).
LOG="$HOME/devdrv-$UDID.log"; : > "$LOG"
TEST_RUNNER_PORT=$PORT nohup xcodebuild test-without-building \
  -xctestrun "$XCTR" \
  -destination "id=$UDID" \
  -derivedDataPath "$WORK/dd-$UDID" \
  >> "$LOG" 2>&1 &

# Cold start measured at ~10-30s on the XS Max: xcodebuild launches the runner,
# it binds its server on the phone, the forwarder relays it. Poll, do not sleep.
for _ in $(seq 1 60); do
  if [ "$(curl -s -m 3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/status" 2>/dev/null)" = 200 ]; then
    echo "up on $PORT"; exit 0
  fi
  if grep -qE "Testing failed|TEST EXECUTE FAILED|error:" "$LOG" 2>/dev/null; then
    echo "the device driver failed to start; $LOG ends:" >&2
    tail -5 "$LOG" >&2
    echo "'TEST EXECUTE FAILED' / 'connection was invalidated' with the phone unlocked and" >&2
    echo "devicectl showing it 'connected' is the on-device XCTest session dying (item 46)," >&2
    echo "not the tunnel — measured ~40-70s on Xcode 26.6. Retry; if it keeps dying that" >&2
    echo "fast the toolchain is suspect (a newer Maestro, or a different Xcode version)." >&2
    exit 1
  fi
  sleep 2
done
echo "the device driver did not answer on $PORT within ~120s; $LOG ends:" >&2
tail -5 "$LOG" >&2
exit 1
