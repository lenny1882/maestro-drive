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

mkdir -p "$WORK"

# Cable or wifi (BACKLOG item 99, Part 2). A phone on wifi is not on usbmuxd at
# all, so the usbmux forwarder cannot reach it; devicectl still can, through a
# CoreDevice tunnel whose address changes every time the tunnel is rebuilt. The
# prebuilt driver listens on the phone's loopback only, so over wifi it has to
# be the driver from driver/build.sh, started with TEST_RUNNER_BIND set to the
# tunnel address, and the forwarder relays to that address over plain TCP.
_link() {  # prints "<transportType> <tunnelIPAddress>"
  xcrun devicectl device info details --device "$UDID" \
    --json-output "$WORK/details-$UDID.json" >/dev/null 2>&1
  python3 -c '
import json, sys
try:
    c = json.load(open(sys.argv[1]))["result"]["connectionProperties"]
    print(c.get("transportType", "?"), c.get("tunnelIPAddress", ""))
except Exception:
    print("?")' "$WORK/details-$UDID.json"
}
set -- $(_link); LINK=${1:-?}; TUNNEL=${2:-}

# Which driver. The one built from source (driver/build.sh, signed by
# driver/sign.sh) whenever a signed one exists: it is the only one reachable
# over wifi, and over USB it is the only one that survives a touch on a phone
# lying flat — the prebuilt driver crashes in ScreenSizeHelper.swift:99 on the
# first touch (item 50). Measured 24 Sep 2026 on the XS Max reporting faceUp:
# prebuilt, dead on touch 1; source build, 5 touches of 5. The prebuilt driver
# is the fallback, for USB only.
SRCXCTR=${DRIVER_XCTESTRUN:-$(ls -t "$HOME"/maestro-drive-driver/build-*/Build/Products/*.xctestrun 2>/dev/null | head -1)}
SRCOK=
[ -r "$SRCXCTR" ] &&
  codesign --verify --deep --strict "$(dirname "$SRCXCTR")/Debug-iphoneos/maestro-driver-iosUITests-Runner.app" 2>/dev/null &&
  SRCOK=1

if [ "$LINK" = localNetwork ]; then
  [ -n "$TUNNEL" ] || { echo "the phone is on wifi but devicectl gives no tunnel address — is it paired and awake?" >&2; exit 1; }
  [ -n "$SRCOK" ] || { echo "the phone is on wifi, and that needs the driver built from source and signed:" >&2
    echo "  sh $HERE/driver/build.sh" >&2
    echo "  then, from Terminal on the Mac: $HERE/driver/sign.sh '<identity>' <profile> <build-dir>" >&2
    echo "The prebuilt driver listens on the phone's loopback only, which wifi cannot reach." >&2
    exit 1; }
  XCTR=$SRCXCTR
elif [ -n "$SRCOK" ]; then
  XCTR=$SRCXCTR
else
  [ -r "$XCTR" ] || { echo "no device driver: neither a signed build from driver/build.sh nor the prebuilt one at" >&2
    echo "  $XCTR" >&2
    echo "Build one (driver/build.sh, then driver/sign.sh), or re-sign the prebuilt — physical-device.md §3." >&2
    exit 1; }
  echo "note: using the prebuilt driver, which crashes on a phone lying flat (item 50) — driver/build.sh replaces it" >&2
fi

# A locked phone cannot run XCUITest and fails as a connection error, not a lock
# — the single most common way this goes wrong (measured 10 Sep 2026). Refuse
# with the real reason rather than letting it surface as "driver not ready".
case "$(xcrun devicectl device info lockState --device "$UDID" 2>/dev/null | grep -i passcodeRequired)" in
  *[Tt]rue*) echo "the phone is LOCKED (passcodeRequired: true) — unlock it and retry." >&2
             echo "XCUITest cannot attach to a locked screen." >&2; exit 1 ;;
esac

# The forwarder: Mac 127.0.0.1:PORT -> device 127.0.0.1:PORT. One per device.
# Over wifi it is always replaced: the tunnel address it was given may be gone.
# Over USB a running usbmux forwarder is kept, but not a wifi one ($ anchors the
# match to a command line with no --tunnel after the port).
if [ "$LINK" = localNetwork ]; then
  :   # started below, after the wake, with the address the wake leaves
elif ! pgrep -f "iproxy.py $UDID $PORT\$" >/dev/null 2>&1; then
  pkill -f "iproxy.py $UDID " 2>/dev/null
  nohup python3 "$HERE/iproxy.py" "$UDID" "$PORT" > "$WORK/iproxy-$PORT.log" 2>&1 &
  sleep 2
  grep -q forwarding "$WORK/iproxy-$PORT.log" 2>/dev/null || {
    echo "forwarder did not bind:" >&2; cat "$WORK/iproxy-$PORT.log" >&2; exit 1; }
fi

# Wake the tunnel immediately before the driver — it drops to idle in seconds,
# and any devicectl call wakes it.
xcrun devicectl device info lockState --device "$UDID" >/dev/null 2>&1

# Over wifi the wake can rebuild the tunnel with a new address, so the address
# is read now, after it, and the forwarder started with that one. Read before
# the wake, the driver was handed a gone address and failed at once with
# `Bind(49): Can't assign requested address` (measured 24 Sep 2026).
if [ "$LINK" = localNetwork ]; then
  set -- $(_link); TUNNEL=${2:-}
  [ -n "$TUNNEL" ] || { echo "the tunnel address went away after the wake — is the phone still on wifi?" >&2; exit 1; }
  pkill -f "iproxy.py $UDID " 2>/dev/null; sleep 1
  nohup python3 "$HERE/iproxy.py" "$UDID" "$PORT" --tunnel "$TUNNEL" > "$WORK/iproxy-$PORT.log" 2>&1 &
  sleep 2
  grep -q forwarding "$WORK/iproxy-$PORT.log" 2>/dev/null || {
    echo "forwarder did not bind:" >&2; cat "$WORK/iproxy-$PORT.log" >&2; exit 1; }
fi

# Already serving on this port? Leave it — relaunching drops whatever the caller
# is part-way through.
if [ "$(curl -s -m 4 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/status" 2>/dev/null)" = 200 ]; then
  echo "already up on $PORT"; exit 0
fi

# One log per phone. A shared ~/devdrv.log was truncated by the second phone's
# bring-up while the first phone's xcodebuild was still appending to it, so a
# failure on either named the other's lines (BACKLOG item 99).
LOG="$HOME/devdrv-$UDID.log"; : > "$LOG"
# TEST_RUNNER_BIND only over wifi: an empty one would be an address to bind.
# build.sh's xctestrun runs every test in the bundle, so name the server test;
# the prebuilt one already skips the rest.
BIND=; ONLY=
[ "$XCTR" = "$SRCXCTR" ] &&
  ONLY=-only-testing:maestro-driver-iosUITests/maestro_driver_iosUITests/testHttpServer
if [ "$LINK" = localNetwork ]; then
  BIND=$TUNNEL
  pkill -f "xcodebuild test-without-building.*$UDID" 2>/dev/null
fi
env ${BIND:+TEST_RUNNER_BIND=$BIND} TEST_RUNNER_PORT=$PORT \
  nohup xcodebuild test-without-building $ONLY \
  -xctestrun "$XCTR" \
  -destination "id=$UDID" \
  -derivedDataPath "$WORK/dd-$UDID" \
  >> "$LOG" 2>&1 &

# Say what the log says, not one cause for every failure (BACKLOG item 103).
# Each branch is a failure seen on this Mac, in the order they can overlap.
_why() {  # _why <log>
  if grep -qE "Installing built products.*Finished with error|Failed to install the app" "$1" 2>/dev/null; then
    echo "the driver could not be INSTALLED on the phone — it never ran." >&2
    grep -oE "CoreDeviceError error [0-9]+|IXRemoteErrorDomain error [0-9]+|Connection interrupted|disconnected immediately after connecting" "$1" | sort -u | sed 's/^/  /' >&2
    echo "On 24 Sep 2026 this was CoreDeviceError 3002 (IXRemote 6, 'Connection" >&2
    echo "interrupted') four times in a row, and restarting the phone cleared it; the" >&2
    echo "next install took 3s. A second process using the phone's tunnel (a devicectl" >&2
    echo "loop) caused the same error on 10 Sep. Retrying without either does not help." >&2
  elif grep -qE "Bind\(49\)|Can't assign requested address" "$1" 2>/dev/null; then
    echo "the driver could not listen on the tunnel address it was given — the tunnel" >&2
    echo "was rebuilt with a new address before it started. Retry; the address is read" >&2
    echo "again (item 99 Part 2)." >&2
  elif grep -q "ScreenSizeHelper" "$1" 2>/dev/null; then
    echo "the FACE-UP crash (item 50): the prebuilt driver dies on a touch while the" >&2
    echo "phone lies flat. Stand it up, or build the driver from source (driver/build.sh)." >&2
  else
    echo "'TEST EXECUTE FAILED' / 'connection was invalidated' with the phone unlocked and" >&2
    echo "devicectl showing it 'connected' is the on-device XCTest session dying (item 46)," >&2
    echo "not the tunnel. Measured 24 Sep 2026: 60-104s with either driver on a cable," >&2
    echo "and 30-100s over wifi. Retry; driver.sh restarts a registered phone itself." >&2
    echo "If it keeps dying within a couple of minutes, restart CoreDevice on the Mac:" >&2
    echo "  sudo killall -9 remoted   (on 24 Sep that took sessions past 10 minutes)" >&2
  fi
}

# Cold start measured at ~10-30s on the XS Max: xcodebuild launches the runner,
# it binds its server on the phone, the forwarder relays it. Poll, do not sleep.
for _ in $(seq 1 60); do
  if [ "$(curl -s -m 3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/status" 2>/dev/null)" = 200 ]; then
    echo "up on $PORT"; exit 0
  fi
  if grep -qE "Testing failed|TEST EXECUTE FAILED|error:" "$LOG" 2>/dev/null; then
    echo "the device driver failed to start; $LOG ends:" >&2
    tail -5 "$LOG" >&2
    _why "$LOG"
    exit 1
  fi
  sleep 2
done
echo "the device driver did not answer on $PORT within ~120s; $LOG ends:" >&2
tail -5 "$LOG" >&2
_why "$LOG"
exit 1
