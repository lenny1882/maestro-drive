#!/bin/sh
# Android platform runner — STUB.
#
# NOTHING IN THIS FILE HAS BEEN RUN. There is no Android SDK on the Mac this
# package was written against, no emulator has been booted through it, and no
# Maestro Android driver has been started by it. Every command below is what the
# documented tool takes, not what was measured — which is the opposite of how
# the rest of this package is written, and the reason each verb says which of
# the two it is.
#
# Read it as a map of what has to be found out, not as working code. Three verbs
# are unanswered on purpose: filling them in with something plausible is exactly
# how somebody loses an afternoon.
#
# Runs ON THE MAC, except `claim`.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift
ADB=${ADB:-adb}

case "$VERB" in

claim)
  # SHAPE ONLY, and the shapes genuinely differ: an emulator is emulator-NNNN,
  # a network device is host:port, a USB handset is a bare hardware serial.
  #
  # The last of those is the hole. A bare serial has no shape that rules out an
  # iPhone's 00008020-0011223344556677, so `claim` alone cannot tell an Android
  # handset from an iOS one and `PLATFORM` has to be set by hand for it. Said
  # here rather than papered over: a wrong claim sends taps to the wrong phone.
  case "${1:?claim <device-id>}" in
    emulator-[0-9]*) exit 0 ;;
    *:[0-9]*)        exit 0 ;;
  esac
  exit 1
  ;;

devices)
  # `adb devices -l` prints "<serial> <state> <key:value>..." after a header
  # line. DOCUMENTED, NOT MEASURED.
  if [ "${1:-}" = --booted ]; then _want=device; else _want=; fi
  "$ADB" devices -l 2>/dev/null | sed 1d | while read -r _s _st _rest; do
    [ -n "$_s" ] || continue
    [ -n "$_want" ] && [ "$_st" != "$_want" ] && continue
    _name=$(printf '%s' "$_rest" | sed -n 's/.*model:\([^ ]*\).*/\1/p')
    printf '%s\t%s\t%s\n' "$_s" "$_st" "${_name:-$_s}"
  done
  ;;

boot)
  # THE ASYMMETRY THAT MATTERS. An iOS simulator has one UDID whether it is
  # booted or not, so every verb here takes the same id. An Android emulator has
  # an AVD NAME while it is off and a SERIAL (emulator-5554) once it is up, and
  # the serial is assigned by the port it lands on — so `boot` takes a name and
  # every other verb takes a serial, and the two cannot be the same argument.
  #
  # runners/README.md's contract says `boot <id>`, which is written for iOS and
  # is wrong here. Settle that before writing this: either the contract gains a
  # `resolve <name> -> <id>` verb, or `boot` returns the id it booted.
  echo "runners/android boot: unanswered — an AVD name and an emulator serial" >&2
  echo "  are not the same identifier, and the contract assumes they are." >&2
  echo "  See the comment in this file before implementing it." >&2
  exit 2
  ;;

shutdown)
  # DOCUMENTED, NOT MEASURED.
  "$ADB" -s "${1:?shutdown <id>}" emu kill
  ;;

install)
  # DOCUMENTED, NOT MEASURED. -r replaces an existing install, which is what
  # every other install in this package does.
  #
  # The verify-afterwards rule holds exactly as it does on iOS: "install
  # returned 0" and "the app is there" are not the same claim, and `pm list
  # packages` is the second one.
  _id=${1:?install <id> <artifact> [app-id]}; _art=${2:?artifact}; _appid=${3:-}
  "$ADB" -s "$_id" install -r "$_art" || { echo "install failed: $_id" >&2; exit 1; }
  if [ -n "$_appid" ]; then
    "$ADB" -s "$_id" shell pm list packages "$_appid" 2>/dev/null | grep -q "package:$_appid" || {
      echo "install reported success but $_appid is not on $_id afterwards" >&2; exit 1; }
  fi
  echo "installed  $_id"
  ;;

container)
  # A REAL GAP, not a missing line. `container` exists so remote/appcheck.sh can
  # read the installed build's executable timestamp and its Info.plist, and
  # answer "is the app on the device the code under test" — the check two
  # separate sessions worked out from scratch and that caught a build from
  # another branch both times.
  #
  # Android has neither. `pm path <appid>` gives the APK's path on the device,
  # and reading its mtime needs a shell stat on a path the shell user may not be
  # able to see; the version comes from `dumpsys package <appid>` instead of a
  # plist. So appcheck needs an Android answer of its own, not this path.
  echo "runners/android container: unanswered — appcheck's timestamp-and-plist" >&2
  echo "  comparison has no Android equivalent. 'pm path' gives an APK path;" >&2
  echo "  'dumpsys package <id>' gives versionName/versionCode/lastUpdateTime," >&2
  echo "  which is probably the shape appcheck should take here." >&2
  exit 2
  ;;

data-container)
  # DOCUMENTED, NOT MEASURED, and only on a debuggable build: run-as is what
  # gives a non-root shell access to an app's own data directory, and it refuses
  # for a release build. Which is the same restriction the iOS side has in
  # practice, since these are debug builds under test.
  printf '/data/data/%s\n' "${2:?data-container <id> <app-id>}"
  ;;

prefs-read)
  [ "${1:-}" = --raw ] && shift   # the store IS xml here, so --raw is the same
  # DOCUMENTED, NOT MEASURED. SharedPreferences is XML under shared_prefs/, and
  # the default file is <app-id>_preferences.xml — but a Flutter app's
  # shared_preferences plugin writes FlutterSharedPreferences.xml instead, which
  # is the framework showing through the platform and is worth knowing before
  # this is wired to bin/prefs.sh.
  _id=${1:?prefs-read <id> <app-id>}; _appid=${2:?app-id}
  "$ADB" -s "$_id" shell "run-as $_appid sh -c 'cat /data/data/$_appid/shared_prefs/*.xml'"
  ;;

prefs-flush)
  # DOCUMENTED, NOT MEASURED. SharedPreferences.apply() writes on a background
  # thread and is flushed when the activity is stopped, so backgrounding the app
  # is the same trick the iOS side plays with notifyutil.
  "$ADB" -s "${1:?prefs-flush <id> <app-id>}" shell input keyevent KEYCODE_HOME
  sleep 0.5
  ;;

orientations)
  # DOCUMENTED, NOT MEASURED, and it takes the APK rather than an installed
  # path: `aapt dump badging <apk>` reports supports-screens and the manifest's
  # screenOrientation. Needs the build-tools aapt on PATH.
  echo "runners/android orientations: needs aapt against the APK, not a container" >&2
  exit 2
  ;;

screenshot)
  # DOCUMENTED, NOT MEASURED. exec-out rather than shell: `adb shell screencap`
  # mangles the PNG through the pty's newline translation.
  "$ADB" -s "${1:?screenshot <id> <path>}" exec-out screencap -p > "${2:?path}"
  ;;

driver-up|driver-down|driver-scan)
  # UNANSWERED, and the largest of the three. Maestro's Android driver is not
  # XCUITest and shares nothing with it: no xcodebuild, no TEST_RUNNER_PORT, no
  # maestro-driver-iosUITests-Runner process to scan for. It is an instrumented
  # APK reached through `adb forward`, which means the port mapping this package
  # cares so much about is adb's rather than the driver's.
  #
  # What has to be found out before writing these:
  #   which APK, and where Maestro keeps it (~/.maestro/deps has the iOS one)
  #   how its port is chosen, and whether it can be chosen at all — the whole
  #     reason bin/drivers.sh exists is that Maestro's iOS client hardcodes 22087
  #   what `adb forward --list` reports, since that is the driver-scan analogue
  #   whether one emulator can hold one driver, as one simulator does
  echo "runners/android $VERB: unanswered — Maestro's Android driver is an" >&2
  echo "  instrumented APK behind 'adb forward', not an xcodebuild test run." >&2
  echo "  See the comment in this file for what has to be measured first." >&2
  exit 2
  ;;

uninstall)
  # DOCUMENTED, NOT MEASURED. `adb uninstall` removes the package and its data.
  "$ADB" -s "${1:?uninstall <id> <app-id>}" uninstall "${2:?app-id}" >/dev/null 2>&1
  exit 0
  ;;

locked)
  # DOCUMENTED, NOT MEASURED. mDeviceProvisioned / mShowingLockscreen come out of
  # `dumpsys window`; which key is authoritative varies by Android version, which
  # is exactly the kind of thing that has to be measured rather than trusted.
  echo "runners/android locked: not measured — dumpsys window keys vary by version" >&2
  exit 2
  ;;

last-used)
  # UNANSWERED. The iOS answer walks CoreSimulator's per-app data containers for
  # an mtime. An emulator's userdata is a qcow2 image whose mtime moves whenever
  # the emulator writes anything at all, which is not the same question — it
  # says the emulator is running, not that somebody is driving it.
  echo "runners/android last-used: unanswered — an emulator disk image's mtime" >&2
  echo "  says the emulator is running, not that anyone is using it." >&2
  exit 2
  ;;

capture-cmd)
  # PLAUSIBLE, NOT MEASURED. Maestro's capture binary takes the platform as its
  # first argument — the iOS runner passes `ios` — so `android` is the obvious
  # guess and is exactly that, a guess. The wall spawns whatever this prints, so
  # a wrong command here is a tile that never shows a frame.
  echo "$HOME/.maestro/deps/simulator-server android --id ${1:?capture-cmd <id>}"
  exit 0
  ;;

*)
  echo "runners/android: unknown verb '${VERB:-(none)}'" >&2
  exit 2
  ;;
esac
