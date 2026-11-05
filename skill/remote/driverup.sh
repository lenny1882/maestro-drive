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

# Already serving on this port? Leave it alone — relaunching costs ~30s and
# would drop whatever the caller is part-way through.
if curl -s -m 4 -o /dev/null "http://127.0.0.1:$PORT/status" 2>/dev/null; then
  echo "already up on $PORT"; exit 0
fi

# The build products are identical for every device, so extract once and share,
# and extract again when the jar changes (item 131). Maestro 2.12.1 replaced the
# jar and the .xctestrun came out byte-identical, so the old runner stayed in use
# with nothing to show for it: this compares the jar, not what came out of it.
# The .xctestrun refers to its siblings through __TESTROOT__, so the layout has
# to stay as it is in the jar. Built aside and moved in, so a second device
# starting at the same moment never sees a half-written tree.
JARSUM=$(cksum < "$JAR")
if [ ! -r "$PRODUCTS/maestro-driver-ios-config.xctestrun" ] ||
   [ "$(cat "$PRODUCTS/.jar-cksum" 2>/dev/null)" != "$JARSUM" ]; then
  NEW=$WORK/.extract.$$
  rm -rf "$NEW"; mkdir -p "$NEW" || exit 1
  ( cd "$NEW" && unzip -q -o "$JAR" "driver-iPhoneSimulator/*" &&
    cd driver-iPhoneSimulator/Debug-iphonesimulator &&
    for z in *.zip; do [ -e "$z" ] || continue; unzip -q -o "$z" && rm -f "$z"; done
  ) || { rm -rf "$NEW"; echo "could not extract the driver from $JAR" >&2; exit 1; }
  printf '%s\n' "$JARSUM" > "$NEW/driver-iPhoneSimulator/.jar-cksum"
  rm -rf "$PRODUCTS"
  mv "$NEW/driver-iPhoneSimulator" "$PRODUCTS" || exit 1
  rm -rf "$NEW"
fi

LOG=$WORK/driver-$UDID.log
rm -f "$LOG"
# The next start deletes the log above, so a retry that works would take the
# failure's only evidence with it (item 143). A failed start keeps a copy, and the
# newest five per device stay.
_keep_log() {
  _kept=$WORK/driver-$UDID.failed-$(date +%Y%m%d-%H%M%S).log
  cp "$LOG" "$_kept" 2>/dev/null && echo "log kept: $_kept" >&2
  ls -t "$WORK"/driver-"$UDID".failed-*.log 2>/dev/null | tail -n +6 | while read -r _old; do rm -f "$_old"; done
}
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
  grep -qE "Testing failed|error:" "$LOG" 2>/dev/null && { echo "xcodebuild failed:" >&2; tail -5 "$LOG" >&2; _keep_log; exit 1; }
  sleep 1
done
echo "driver did not answer on $PORT within 60s; last log lines:" >&2
tail -5 "$LOG" >&2
_keep_log
exit 1
