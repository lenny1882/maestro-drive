#!/bin/bash
# Bring up an XCUITest driver for one simulator, on a port of our choosing.
# Runs ON THE MAC. Called by bin/drivers.sh; not useful from the sandbox.
#
#   driverup.sh <udid> <port> <workdir>
#
# Maestro's own driver is the same build products, launched the same way — the
# only difference is that we choose the port instead of taking 22087. The port
# reaches the runner through xcodebuild's TEST_RUNNER_ prefix convention:
# TEST_RUNNER_PORT in xcodebuild's environment arrives as PORT inside the test
# process, and XCTestHTTPServer.swift reads exactly that
# (`ProcessInfo.processInfo.environment["PORT"] ?? 22087`).
#
# Maestro's client side cannot do this: MaestroSessionManager and
# McpMaestroSessionManager both `sipush 22087` inline with no env read, which is
# why a second device is unreachable through the CLI or the MCP server and
# reachable here.
set -uo pipefail
UDID=${1:?usage: driverup.sh <udid> <port> <workdir>}
PORT=${2:?port}
WORK=${3:-/tmp/maestro-mac/drv}
JAR=$HOME/.maestro/lib/maestro-ios-driver.jar
PRODUCTS=$WORK/driver-iPhoneSimulator

[ -r "$JAR" ] || { echo "no maestro-ios-driver.jar at $JAR" >&2; exit 1; }

# The build products are identical for every device, so extract once and share.
# The .xctestrun refers to its siblings through __TESTROOT__, so the layout has
# to stay as it is in the jar.
if [ ! -r "$PRODUCTS/maestro-driver-ios-config.xctestrun" ]; then
  mkdir -p "$WORK" && cd "$WORK" || exit 1
  unzip -q -o "$JAR" "driver-iPhoneSimulator/*" || exit 1
  cd "$PRODUCTS/Debug-iphonesimulator" || exit 1
  for z in *.zip; do [ -e "$z" ] || continue; unzip -q -o "$z" && rm -f "$z"; done
fi

# Already serving on this port? Leave it alone — relaunching costs ~30s and
# would drop whatever the caller is part-way through.
if curl -s -m 4 -o /dev/null "http://127.0.0.1:$PORT/status" 2>/dev/null; then
  echo "already up on $PORT"; exit 0
fi

LOG=$WORK/driver-$UDID.log
rm -f "$LOG"
TEST_RUNNER_PORT=$PORT nohup xcodebuild test-without-building \
  -xctestrun "$PRODUCTS/maestro-driver-ios-config.xctestrun" \
  -destination "id=$UDID" \
  -derivedDataPath "$WORK/dd-$UDID" \
  > "$LOG" 2>&1 &

# Cold start measured at 20-30s: xcodebuild installs the runner, boots the
# XCTest session, then the server binds. Poll rather than sleep a fixed time.
for _ in $(seq 1 60); do
  if [ "$(curl -s -m 3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/status" 2>/dev/null)" = "200" ]; then
    echo "up on $PORT"; exit 0
  fi
  grep -qE "Testing failed|error:" "$LOG" 2>/dev/null && { echo "xcodebuild failed:" >&2; tail -5 "$LOG" >&2; exit 1; }
  sleep 1
done
echo "driver did not answer on $PORT within 60s; last log lines:" >&2
tail -5 "$LOG" >&2
exit 1
