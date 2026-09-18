#!/bin/sh
# iOS simulator platform runner — the WORKED EXAMPLE for runners/README.md.
#
# Nothing calls this yet. Every verb below runs the command that `bin/lib.sh`,
# `bin/drivers.sh`, `bin/shot.sh`, `bin/prefs.sh`, `bin/preflight.sh`,
# `remote/build.sh`, `remote/driverup.sh` and `remote/wall.py` already run — they
# are all unchanged and all still in use. This is here to show that the platform
# verbs are one command apiece and that cutting this axis is the cheaper half.
#
# Runs ON THE MAC, except `claim`.
#
# A physical iPhone is a SEPARATE runner, runners/ios-device: it installs with
# devicectl not simctl, needs a profile build, needs a usbmux forwarder for the
# driver, and refuses when the phone is locked. Folding it in here as a branch
# is what bin/build.sh does today, and it is why the UUID-shape test lives in
# the middle of a build script.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift

case "$VERB" in

claim)
  # A simulator UDID is a canonical UUID, 8-4-4-4-12. An XS Max's
  # 00008020-0011223344556677 is not, and belongs to runners/ios-device.
  case "${1:?claim <device-id>}" in
    ????????-????-????-????-????????????) exit 0 ;;
  esac
  exit 1
  ;;

devices)
  # <id> TAB <state> TAB <name> TAB <runtime>. The runtime is the optional
  # fourth column: nothing needs it to identify a device, and the wall groups
  # by it so that two iPhone 16s on different iOS versions sort together with
  # their own kind rather than interleaving.
  #
  # -j and python, not the plain text: simctl's human listing puts the runtime
  # on a heading line above its devices, so a line-at-a-time sed cannot carry it
  # down, and the JSON has it as the key.
  [ "${1:-}" = --booted ] && _only=Booted || _only=
  xcrun simctl list devices available -j 2>/dev/null | ONLY="$_only" python3 -c '
import json, os, sys
only = os.environ.get("ONLY") or None
rows = []
for runtime, devs in (json.load(sys.stdin).get("devices") or {}).items():
    for d in devs:
        st = d.get("state") or ""
        if only and st != only:
            continue
        if not d.get("udid"):
            continue
        rows.append((runtime, d.get("name") or d["udid"], d["udid"], st))
for rt, name, udid, st in sorted(rows):
    print("\t".join((udid, st, name, rt)))
'
  ;;

boot)
  _id=${1:?boot <id>}
  xcrun simctl boot "$_id" 2>/dev/null
  # Wait the boot out. Returning early is what makes the next caller start a
  # driver mid-boot, and a driver begun then is the one that dies.
  xcrun simctl bootstatus "$_id" -b
  ;;

shutdown)
  xcrun simctl shutdown "${1:?shutdown <id>}"
  ;;

install)
  _id=${1:?install <id> <artifact> [app-id]}; _art=${2:?artifact}; _appid=${3:-}
  xcrun simctl install "$_id" "$_art" || { echo "install failed: $_id" >&2; exit 1; }
  # "Install returned 0" and "the app is there" are not the same claim.
  if [ -n "$_appid" ] && ! xcrun simctl get_app_container "$_id" "$_appid" >/dev/null 2>&1; then
    echo "install reported success but $_appid is not on $_id afterwards" >&2
    exit 1
  fi
  echo "installed  $_id"
  ;;

installed-info)
  # A simulator can answer all four. The executable's mtime, NOT the bundle
  # directory's: installing rewrites the directory, so the directory says when
  # it was put there and the binary says what it is.
  _id=${1:?installed-info <id> <app-id>}; _appid=${2:?app-id}
  _c=$(xcrun simctl get_app_container "$_id" "$_appid" 2>/dev/null)
  [ -n "$_c" ] && [ -d "$_c" ] || exit 1
  echo "container=$_c"
  _exe=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$_c/Info.plist" 2>/dev/null)
  _bin=$_c; [ -n "$_exe" ] && [ -f "$_c/$_exe" ] && _bin=$_c/$_exe
  _e=$(stat -f %m "$_bin" 2>/dev/null); [ -n "$_e" ] && echo "epoch=$_e"
  _v=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$_c/Info.plist" 2>/dev/null)
  _b=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$_c/Info.plist" 2>/dev/null)
  [ -n "$_v" ] && echo "version=$_v"
  [ -n "$_b" ] && echo "build=$_b"
  exit 0
  ;;

container)
  xcrun simctl get_app_container "${1:?container <id> <app-id>}" "${2:?app-id}"
  ;;

data-installed-info)
  # A simulator can answer all four. The executable's mtime, NOT the bundle
  # directory's: installing rewrites the directory, so the directory says when
  # it was put there and the binary says what it is.
  _id=${1:?installed-info <id> <app-id>}; _appid=${2:?app-id}
  _c=$(xcrun simctl get_app_container "$_id" "$_appid" 2>/dev/null)
  [ -n "$_c" ] && [ -d "$_c" ] || exit 1
  echo "container=$_c"
  _exe=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$_c/Info.plist" 2>/dev/null)
  _bin=$_c; [ -n "$_exe" ] && [ -f "$_c/$_exe" ] && _bin=$_c/$_exe
  _e=$(stat -f %m "$_bin" 2>/dev/null); [ -n "$_e" ] && echo "epoch=$_e"
  _v=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$_c/Info.plist" 2>/dev/null)
  _b=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$_c/Info.plist" 2>/dev/null)
  [ -n "$_v" ] && echo "version=$_v"
  [ -n "$_b" ] && echo "build=$_b"
  exit 0
  ;;

container)
  xcrun simctl get_app_container "${1:?data-container <id> <app-id>}" "${2:?app-id}" data
  ;;

prefs-flush)
  # iOS flushes NSUserDefaults lazily, so a key written seconds ago is not on
  # disk yet and reads as absent. Backgrounding the app forces the write.
  xcrun simctl spawn "${1:?prefs-flush <id> <app-id>}" \
    notifyutil -p com.apple.mobile.application_did_enter_background 2>/dev/null
  sleep 0.5
  ;;

prefs-read)
  # --raw gives the store as it sits on disk, for when the readable form has
  # mangled something. Everything else gets `plutil -p`.
  _raw=0; [ "${1:-}" = --raw ] && { _raw=1; shift; }
  _id=${1:?prefs-read [--raw] <id> <app-id>}; _appid=${2:?app-id}
  # No `|| exit 1` on the substitution: that exits before the message below and
  # the caller gets a bare status with no reason, which reads as the reader being
  # broken rather than the app being absent or the device shut down.
  _c=$(xcrun simctl get_app_container "$_id" "$_appid" data 2>/dev/null)
  [ -n "$_c" ] || { echo "cannot reach $_appid on $_id — the app is not installed, or the device is not booted" >&2; exit 1; }
  # `defaults read` cannot see an app's container domain, so the plist is read
  # as a file.
  _p="$_c/Library/Preferences/$_appid.plist"
  [ -f "$_p" ] || { echo "no prefs file at $_p" >&2
                    echo "  the app may not have written any NSUserDefaults yet" >&2; exit 1; }
  if [ "$_raw" = 1 ]; then cat "$_p"; else plutil -p "$_p"; fi
  ;;

orientations)
  _c=${1:?orientations <container>}
  _pl="$_c/Info.plist"
  [ -f "$_pl" ] || { echo 'Info.plist not found in app container' >&2; exit 1; }
  for _k in 'UISupportedInterfaceOrientations~ipad:iPad' 'UISupportedInterfaceOrientations:iPhone'; do
    _key=${_k%:*}; _lab=${_k#*:}
    _v=$(defaults read "$_pl" "$_key" 2>/dev/null |
         grep -v '[()]' | sed 's/^[[:space:]]*//' | tr -d '",' | paste -sd ' ' -)
    [ -n "$_v" ] && echo "$_lab:   $_v" || echo "$_lab:   not specified"
  done
  ;;

screenshot)
  xcrun simctl io "${1:?screenshot <id> <path>}" screenshot "${2:?path}" >/dev/null 2>&1
  ;;

driver-up)
  # remote/driverup.sh, unchanged: the same build products out of
  # maestro-ios-driver.jar and the same xcodebuild invocation Maestro uses, with
  # TEST_RUNNER_PORT choosing the port instead of taking 22087.
  _here=$(cd "$(dirname "$0")" && pwd)
  sh "${RDIR:-/tmp/maestro-mac}/driverup.sh" "${1:?driver-up <id> <port>}" "${2:?port}" \
     "${3:-${RDIR:-/tmp/maestro-mac}/drv}" 2>/dev/null ||
  sh "$_here/../../remote/driverup.sh" "$1" "$2" "${3:-/tmp/maestro-mac/drv}"
  ;;

driver-down)
  _id=${1:?driver-down <id>}
  pkill -f "maestro-driver-iosUITests-Runner.*$_id" 2>/dev/null
  pkill -f "xcodebuild.*id=$_id" 2>/dev/null
  exit 0
  ;;

driver-scan)
  # The runner process runs out of the simulator's own data container, so its
  # command line carries the UDID; lsof gives the port it bound. That is the
  # whole map, read from the live processes rather than from a file we wrote.
  # lsof ORs its selectors unless -a is given.
  for _p in $(pgrep -f "maestro-driver-iosUITests-Runner" 2>/dev/null); do
    _u=$(ps -o command= -p "$_p" 2>/dev/null | sed -nE "s|.*/Devices/([0-9A-F-]{36})/.*|\1|p")
    _pt=$(lsof -nP -a -p "$_p" -iTCP -sTCP:LISTEN 2>/dev/null |
          sed -nE "s|.*TCP 127\.0\.0\.1:([0-9]+) \(LISTEN\).*|\1|p" | head -1)
    [ -n "$_u" ] && [ -n "$_pt" ] && echo "$_u $_pt $_p"
  done
  exit 0
  ;;

uninstall)
  # Removing the app removes its data with it, which is the whole point:
  # `driver.sh clearstate` wants a first-launch app, not a logged-out one. There
  # is no "clear the data and keep the app" on a simulator.
  #
  # Absent is not a failure — the caller asked for the app to be gone.
  xcrun simctl uninstall "${1:?uninstall <id> <app-id>}" "${2:?app-id}" 2>/dev/null
  exit 0
  ;;

locked)
  # Exit 0 when the device is locked, 1 when it is not, 2 when the question does
  # not apply. A SIMULATOR is never locked in the sense that matters, and
  # devicectl returns nothing for a simulator udid — so this self-gates and a
  # caller need not know which kind of device it has.
  #
  # Worth asking before blaming the driver: XCUITest cannot attach to a locked
  # springboard and it surfaces as a relay or connection failure rather than as a
  # lock. Measured 10 Sep 2026 — unlocked, the driver starts 3/3; on the PIN
  # screen it fails every time.
  case "$(xcrun devicectl device info lockState --device "${1:?locked <id>}" 2>/dev/null |
          grep -i passcodeRequired)" in
    *[Tt]rue*)  exit 0 ;;
    *[Ff]alse*) exit 1 ;;
  esac
  exit 2
  ;;

last-used)
  # "<id>|<yyyymmdd>|<human>" for every booted device, plus today's date, in one
  # call. `rig reap` needs it to tell a leftover from somebody's live work.
  #
  # Two levels deep, not one. A container directory's mtime only moves when its
  # IMMEDIATE contents change, so the container itself reported 16 Sep for a
  # device driven all day on the 18th; Documents/ and Library/ inside it gave the
  # right answer, which is what a recursive walk would return for the cost of a
  # glob.
  _today=$(date +%Y%m%d)
  for _u in $(xcrun simctl list devices booted | sed -n "s/.*(\([0-9A-Fa-f-]\{36\}\)).*/\1/p"); do
    _d="$HOME/Library/Developer/CoreSimulator/Devices/$_u/data/Containers/Data/Application"
    _l=$(ls -td "$_d"/*/*/ 2>/dev/null | head -1)
    [ -n "$_l" ] || _l=$(ls -td "$_d"/*/ 2>/dev/null | head -1)
    if [ -n "$_l" ]; then
      _e=$(stat -f %m "$_l" 2>/dev/null)
      echo "$_u|$(date -r "$_e" +%Y%m%d 2>/dev/null)|$(date -r "$_e" "+%Y-%m-%d %H:%M" 2>/dev/null)|$_today"
    else
      echo "$_u|||$_today"
    fi
  done
  exit 0
  ;;

capture-cmd)
  # Maestro's own capture binary, one per device, started by the wall's scan
  # loop whether or not a browser is attached. It takes the platform as its
  # first argument, which is where an Android runner would differ.
  echo "$HOME/.maestro/deps/simulator-server ios --id ${1:?capture-cmd <id>}"
  exit 0
  ;;

*)
  echo "runners/ios: unknown verb '${VERB:-(none)}'" >&2
  exit 2
  ;;
esac
