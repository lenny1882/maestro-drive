#!/bin/sh
# Physical iPhone platform runner.
#
# A separate module from runners/ios and not a branch inside it, because almost
# nothing carries over: devicectl instead of simctl, a driver that binds the
# PHONE's loopback and needs a usbmux forwarder to be reachable at all, a tunnel
# that idles out in seconds, a build that cannot be signed over SSH, and a lock
# screen that stops XCUITest dead while reporting a connection error.
#
# physical-device.md is the 516 lines behind each of those. Read it before
# changing anything here.
#
# Runs ON THE MAC, except `claim`.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift
HERE=$(cd "$(dirname "$0")" && pwd)

case "$VERB" in

claim)
  # A simulator UDID is a canonical UUID, 8-4-4-4-12. A phone's is not — the
  # XS Max is 00008020-000A396C3606002E. So the two modules' claims are exact
  # complements and a device can only ever belong to one of them.
  case "${1:?claim <device-id>}" in
    ????????-????-????-????-????????????) exit 1 ;;
  esac
  exit 0
  ;;

devices)
  # devicectl lists SIMULATORS TOO, and puts them first, so the physical rows
  # are below however many simulators the Mac has — a `head` over this output
  # will show none of them. Filter on the Reality column rather than trusting
  # the order.
  #
  # --booted has no meaning for a phone: it is connected or it is not. The flag
  # is accepted and maps to "connected", so a caller written for simulators asks
  # the question it means.
  [ "${1:-}" = --booted ] && _only=connected || _only=
  xcrun devicectl list devices 2>/dev/null |
    awk -v only="$_only" '
      /physical/ {
        # "<name...> <udid> (UDID) <state...> <model...> physical"
        for (i = 1; i <= NF; i++) if ($i == "(UDID)") { u = $(i-1); ui = i; break }
        if (u == "") next
        name = ""; for (i = 1; i < ui - 1; i++) name = name (name ? " " : "") $i
        st = $(ui + 1)
        if (only != "" && st !~ only) next
        printf "%s\t%s\t%s\n", u, st, name
      }'
  ;;

boot|shutdown)
  # A phone is not booted by anything on the Mac. Exit 2 is the answer, not a
  # failure — the caller must not treat "cannot boot it" as "it is unavailable".
  echo "runners/ios-device $VERB: a phone is connected or it is not; nothing here boots one" >&2
  exit 2
  ;;

install)
  # devicectl, not simctl. And the id it PUT ON THE PHONE is compared, not
  # merely searched for: a grep of the installed list passes even when this
  # install placed a different bundle and a previous one left the wanted id
  # behind. That is the check that caught a stale .app being installed over a
  # fresh build on 11 Sep 2026.
  _id=${1:?install <id> <artifact> [app-id]}; _art=${2:?artifact}; _appid=${3:-}
  _out=$(xcrun devicectl device install app --device "$_id" "$_art" 2>&1) || {
    printf '%s\n' "$_out" >&2; echo "install failed: $_id" >&2; exit 1; }
  if [ -n "$_appid" ]; then
    _got=$(printf '%s\n' "$_out" | sed -n 's/.*bundleID: *\([A-Za-z0-9._-][A-Za-z0-9._-]*\).*/\1/p' | tail -1)
    if [ "$_got" != "$_appid" ]; then
      echo "install put '${_got:-nothing}' on $_id, not $_appid — the wrong build was installed" >&2
      exit 1
    fi
  fi
  echo "installed  $_id${_appid:+ ($_appid)}"
  ;;

locked)
  # THE FIRST THING TO ASK when a driver will not attach. XCUITest cannot attach
  # to a locked springboard and it surfaces as a relay or connection failure
  # rather than as a lock — measured 10 Sep 2026: unlocked, the driver starts
  # 3/3; on the PIN screen it fails every time.
  case "$(xcrun devicectl device info lockState --device "${1:?locked <id>}" 2>/dev/null |
          grep -i passcodeRequired)" in
    *[Tt]rue*)  exit 0 ;;
    *[Ff]alse*) exit 1 ;;
  esac
  exit 2
  ;;

driver-up)
  # deviceup.sh beside this file: the PREBUILT driver-iphoneos products,
  # re-signed by hand once, because Maestro 2.8.0 cannot build its own device
  # driver. Plus the two device-only extras — a usbmux forwarder, because the
  # driver's HTTP server binds the phone's loopback and not the Mac's, and a
  # devicectl tunnel wake immediately before, because the tunnel idles out in
  # seconds.
  sh "$HERE/deviceup.sh" "${1:?driver-up <id> <port>}" "${2:?port}" "${3:-${RDIR:-/tmp/maestro-mac}}"
  ;;

driver-down)
  _id=${1:?driver-down <id>}
  pkill -f "xcodebuild test-without-building.*$_id" 2>/dev/null
  pkill -f "iproxy.py $_id" 2>/dev/null
  exit 0
  ;;

driver-scan)
  # The FORWARDER is the scan, and that is the whole difference from the
  # simulator. A simulator's runner listens on the Mac, so lsof finds its port;
  # a phone's listens on the phone, and the only Mac-side process that knows the
  # pairing is iproxy.py, whose command line carries both halves:
  #
  #   python3 .../iproxy.py 00008020-000A396C3606002E 22090
  #
  # Reading that is a live scan in the same sense as the simulator's. It
  # replaces the local registry bin/device.sh used to keep, which was a file we
  # wrote rather than a fact about the machine — and which therefore listed
  # devices whose forwarder had died.
  for _p in $(pgrep -f "iproxy\.py " 2>/dev/null); do
    set -- $(ps -o command= -p "$_p" 2>/dev/null | sed -n 's|.*iproxy\.py  *\([^ ]*\)  *\([0-9][0-9]*\).*|\1 \2|p')
    [ -n "${1:-}" ] && [ -n "${2:-}" ] && echo "$1 $2 $_p"
  done
  exit 0
  ;;

installed-info)
  # A phone gives version and build and NOTHING ELSE — devicectl's app record
  # carries bundleIdentifier, version, bundleVersion and a containerAccessible
  # flag, and no timestamp of any kind. Measured 18 Sep 2026.
  #
  # So `epoch` and `container` are simply absent here, and appcheck falls back
  # to comparing the installed version+build against what the checkout would
  # produce. That is a different claim from the timestamp one and a weaker one,
  # and appcheck says which it made.
  _id=${1:?installed-info <id> <app-id>}; _appid=${2:?app-id}
  xcrun devicectl device info apps --device "$_id" --json-output /dev/stdout 2>/dev/null |
    APPID="$_appid" python3 -c '
import json, os, sys
want = os.environ["APPID"]
try:
    apps = json.load(sys.stdin)["result"]["apps"]
except Exception:
    sys.exit(1)
for a in apps:
    if a.get("bundleIdentifier") == want:
        if a.get("version"):       print("version=%s" % a["version"])
        if a.get("bundleVersion"): print("build=%s" % a["bundleVersion"])
        sys.exit(0)
sys.exit(1)
'
  ;;

container|data-container|prefs-read|prefs-flush|orientations|last-used)
  # UNANSWERED, and the same hole runners/android has. All of these assume a
  # readable app container, and a phone does not give you one: the app's bundle
  # and its data live inside the sandbox, and nothing short of a development
  # container download reaches them.
  #
  # The consequence is worth stating plainly rather than leaving as a missing
  # verb: remote/appcheck.sh cannot run on a device, so "is the app on this
  # phone the code under test" — the check that caught a build from another
  # branch twice — has no device form. That question wants one answer covering
  # every platform with no readable container, not one per platform.
  echo "runners/ios-device $VERB: a phone has no readable app container, so this" >&2
  echo "  has no answer yet. appcheck therefore cannot run against a device." >&2
  exit 2
  ;;

screenshot)
  # Two differences from simctl, both measured 18 Sep 2026 and both of which
  # exit 64 and write nothing — which reads as the device refusing rather than
  # as the command being wrong:
  #   the subcommand is `capture screenshot`, not `screenshot`
  #   the path is --destination, not a positional, and must end .png
  xcrun devicectl device capture screenshot \
    --device "${1:?screenshot <id> <path>}" --destination "${2:?path}" >/dev/null 2>&1
  ;;

capture-cmd)
  # UNANSWERED. Maestro's capture binary takes a platform word — `ios` for a
  # simulator — and whether it drives a physical device at all is not something
  # this package has established. A wrong command here is a wall tile that never
  # shows a frame, so it says nothing rather than guessing.
  echo "runners/ios-device capture-cmd: not established for a physical device" >&2
  exit 2
  ;;

*)
  echo "runners/ios-device: unknown verb '${VERB:-(none)}'" >&2
  exit 2
  ;;
esac
