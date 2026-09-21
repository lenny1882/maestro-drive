#!/bin/sh
# Android platform runner.
#
# MEASURED 21 Sep 2026 (BACKLOG item 94, 5.3). Every verb below has run against
# Pixel_6_Pro_API_34 — `sdk_gphone64_x86_64`, API 34 — on the machine this
# package is driven from, reached over item 96's bridge, with the SDK at
# /mnt/sda/User/Programs/android-sdk and Maestro 2.10.0. Each verb says what it
# did and what it printed; where a verb still refuses, the comment says what was
# run to establish that it has to.
#
# Four still refuse, and each refusal is a measurement rather than a gap in the
# writing: `container` (appcheck's timestamp-and-plist pair has no Android
# twin), `orientations` (the answer is in the APK, not in a container path),
# `last-used` (an emulator image's mtime answers a different question) and the
# driver trio (item 87's 4.4 — the port question IS answered, in the comment
# there; the three verbs are that item's to write).
#
# Runs ON THE MACHINE WITH THE DEVICE, except `claim`.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift
ADB=${ADB:-adb}

case "$VERB" in

claim)
  # MEASURED 21 Sep 2026: `emulator-5554` claimed (0), `00008020-0011` refused
  # (1). The shapes genuinely differ: an emulator is emulator-NNNN,
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
  # line. MEASURED 21 Sep 2026, with and without --booted, both printing
  # `emulator-5554  device  sdk_gphone64_x86_64` — the model key is the system
  # image's name, not the AVD's, so it is a label and never an id.
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
  # SETTLED 18 Sep (item 87, 4.1): `boot` PRINTS THE ID IT BOOTED as its last
  # line, and the caller uses that from then on. So this takes an AVD name and
  # must end by printing the emulator-NNNN serial it landed on — which means
  # waiting for the device to appear in `adb devices` and working out which of
  # them is new, since the serial comes from the port the emulator took.
  #
  # MEASURED 21 Sep 2026 against Pixel_6_Pro_API_34 on this machine, over the
  # bridge (item 96). Three things the writing had to get right:
  #
  #   the serial is not knowable in advance, so the new one is found by
  #   difference against the serials that were there before;
  #   `adb wait-for-device` returns while Android is still starting, so
  #   sys.boot_completed is polled after it;
  #   the emulator has to outlive this script, so it is detached — a caller
  #   that returns and takes the device with it would be no boot at all.
  #
  # DETACHED MEANS setsid, NOT nohup, and the difference cost a booted emulator
  # on 21 Sep. nohup blocks SIGHUP and leaves the process in the caller's
  # process group; every request over the bridge runs under `timeout`, which
  # manages a group of its own, so the emulator went down with the group a
  # couple of calls later — "Wait for emulator (pid …) 20 seconds to shutdown
  # gracefully", in its own log. setsid gives it its own session and group.
  _avd=${1:?boot <avd name>}
  _emu=${EMULATOR:-}
  [ -n "$_emu" ] || _emu=$(command -v emulator 2>/dev/null)
  [ -n "$_emu" ] || _emu="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}/emulator/emulator"
  [ -x "$_emu" ] || { echo "no emulator binary — set ANDROID_HOME or EMULATOR" >&2; exit 1; }

  _before=$("$ADB" devices 2>/dev/null | sed -n 's/[[:space:]]*device$//p' | tr '\n' ' ')
  _log=${RDIR:-/tmp}/emulator-$_avd.log
  mkdir -p "$(dirname "$_log")" 2>/dev/null || true
  if command -v setsid >/dev/null 2>&1; then
    setsid "$_emu" -avd "$_avd" -no-boot-anim >"$_log" 2>&1 &
  else
    nohup "$_emu" -avd "$_avd" -no-boot-anim >"$_log" 2>&1 &
  fi
  _pid=$!

  _new=
  _i=0
  while [ "$_i" -lt 180 ]; do
    kill -0 "$_pid" 2>/dev/null || {
      echo "the emulator exited while starting. Its log:" >&2
      tail -5 "$_log" >&2
      exit 1; }
    for _s in $("$ADB" devices 2>/dev/null | sed -n 's/[[:space:]]*device$//p'); do
      case " $_before " in *" $_s "*) ;; *) _new=$_s; break ;; esac
    done
    [ -n "$_new" ] && break
    sleep 1
    _i=$((_i + 1))
  done
  [ -n "$_new" ] || { echo "no new device appeared within 180s. Its log:" >&2; tail -5 "$_log" >&2; exit 1; }

  "$ADB" -s "$_new" wait-for-device
  _i=0
  while [ "$_i" -lt 180 ]; do
    [ "$("$ADB" -s "$_new" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')" = 1 ] && break
    sleep 1
    _i=$((_i + 1))
  done
  echo "$_new"
  ;;

shutdown)
  # MEASURED 21 Sep 2026, AND IT RETURNS BEFORE THE DEVICE IS GONE. `adb emu
  # kill` printed "OK: killing emulator, bye bye" and "OK" and came back in
  # 0.00s; the serial was still in `adb devices` three seconds later and gone
  # within fifteen. A caller that shuts down and then counts devices, or boots
  # and expects a fresh serial, will see the old one. `boot` is safe from it —
  # it takes the serials that were there as its baseline — but nothing else here
  # waits for this.
  "$ADB" -s "${1:?shutdown <id>}" emu kill
  ;;

install)
  # MEASURED 21 Sep 2026: -r over a 114MB APK pulled off the device itself,
  # 1.1s, and the verify path exercised by passing an app id that is not there —
  # adb said Success, this said so and exited 1.
  #
  # ADB'S CHATTER GOES TO STDERR. adb prints "Performing Streamed Install" and
  # "Success" on stdout and `simctl install` prints nothing at all; a caller
  # reading this verb's stdout has to get the same thing from both platforms,
  # which is the one line at the end.
  #
  # The verify-afterwards rule holds exactly as it does on iOS: "install
  # returned 0" and "the app is there" are not the same claim, and `pm list
  # packages` is the second one.
  _id=${1:?install <id> <artifact> [app-id]}; _art=${2:?artifact}; _appid=${3:-}
  "$ADB" -s "$_id" install -r "$_art" >&2 || { echo "install failed: $_id" >&2; exit 1; }
  if [ -n "$_appid" ]; then
    "$ADB" -s "$_id" shell pm list packages "$_appid" 2>/dev/null | grep -q "package:$_appid" || {
      echo "install reported success but $_appid is not on $_id afterwards" >&2; exit 1; }
  fi
  echo "installed  $_id"
  ;;

installed-info)
  # MEASURED 21 Sep 2026 against com.prodirectsport.consumer.dev:
  #   build=100 / version=3.0.6-dev / when=2026-04-02 16:55:14
  # The order is dumpsys's, not this awk's — build comes out before version — so
  # nothing may read these positionally. `dumpsys package <id>` reports versionName,
  # versionCode and lastUpdateTime — so Android can answer version, build AND a
  # timestamp, which is more than a phone gives and is why `container` being
  # unanswerable here does not cost the check.
  _id=${1:?installed-info <id> <app-id>}; _appid=${2:?app-id}
  "$ADB" -s "$_id" shell dumpsys package "$_appid" 2>/dev/null | awk '
    /versionName=/   { sub(/.*versionName=/, ""); print "version=" $1 }
    /versionCode=/   { sub(/.*versionCode=/, ""); print "build=" $1 }
    /lastUpdateTime=/{ sub(/.*lastUpdateTime=/, ""); print "when=" $0 }'
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
  #
  # MEASURED 21 Sep 2026, which is what makes this a decision and not a guess.
  # `pm path` returned one line, /data/app/~~RBAphDQNstG_kXWPZCmDKw==/com.prodi
  # rectsport.consumer.dev-oC-6omk0Ep1anPl6_A5VMQ==/base.apk, and both hashed
  # segments are regenerated by every install — so the path is not stable across
  # builds and cannot stand in for a bundle identity. `installed-info`'s
  # lastUpdateTime answers what appcheck is really asking.
  echo "runners/android container: unanswered — appcheck's timestamp-and-plist" >&2
  echo "  comparison has no Android equivalent. 'pm path' gives an APK path;" >&2
  echo "  'dumpsys package <id>' gives versionName/versionCode/lastUpdateTime," >&2
  echo "  which is probably the shape appcheck should take here." >&2
  exit 2
  ;;

data-container)
  # WAS UNREACHABLE UNTIL 21 Sep 2026. This case was headed `container)` a
  # second time, so `case` took the first one and nothing could ever reach it:
  # `data-container`, which runners/README.md names and bin/prefs.sh will use,
  # answered "unknown verb". Beside it sat `data-installed-info`, a verb the
  # contract does not have, carrying a second copy of `installed-info`'s body.
  # Both were found by running every verb in the contract against a device,
  # which is the only way a duplicate case label shows up at all.
  #
  # MEASURED, and only on a debuggable build: run-as is what gives a non-root
  # shell access to an app's own data directory, and it refuses for a release
  # build. Which is the same restriction the iOS side has in practice, since
  # these are debug builds under test.
  printf '/data/data/%s\n' "${2:?data-container <id> <app-id>}"
  ;;

prefs-read)
  [ "${1:-}" = --raw ] && shift   # the store IS xml here, so --raw is the same
  # MEASURED 21 Sep 2026, AND THE GLOB IS TOO WIDE. shared_prefs/ held 28 files
  # for this app — both the ones the comment expected, <app-id>_preferences.xml
  # and Flutter's FlutterSharedPreferences.xml, plus the ones every SDK in the
  # build leaves: Firebase, Facebook, AWS, WebView, Exponea. `cat *.xml` returns
  # all 28 concatenated, so what comes back is 28 XML documents in one stream,
  # each with its own <?xml?> declaration — not a store any parser will read.
  #
  # Left as it is on purpose: bin/prefs.sh is not wired to this verb yet (item
  # 87, unit 6), and which file it should ask for is that unit's decision, not
  # one to guess here. What is settled is that it has to ask for one.
  _id=${1:?prefs-read <id> <app-id>}; _appid=${2:?app-id}
  "$ADB" -s "$_id" shell "run-as $_appid sh -c 'cat /data/data/$_appid/shared_prefs/*.xml'"
  ;;

prefs-flush)
  # MEASURED 21 Sep 2026, exit 0 — and what it verifies is that the keyevent was
  # accepted, not that anything reached disk; the app was launched rather than
  # written to, so there was nothing pending to flush.
  # SharedPreferences.apply() writes on a background
  # thread and is flushed when the activity is stopped, so backgrounding the app
  # is the same trick the iOS side plays with notifyutil.
  "$ADB" -s "${1:?prefs-flush <id> <app-id>}" shell input keyevent KEYCODE_HOME
  sleep 0.5
  ;;

orientations)
  # STILL REFUSES, and 21 Sep 2026 measured why rather than assuming it. The
  # contract passes a container path; on Android the answer is inside the APK,
  # which this verb is not given and which `container` cannot hand it either.
  #
  # Both halves were run against the app's own base.apk, pulled off the device:
  #   aapt dump badging   ->  supports-screens: 'small' 'normal' 'large' 'xlarge'
  #                           and NO orientation line at all
  #   aapt2 dump xmltree --file AndroidManifest.xml
  #                       ->  android:screenOrientation(0x0101001e)=1, portrait
  # So it takes aapt2 and the manifest, not aapt and badging, and it needs the
  # artifact. Wiring it means changing what the caller passes.
  echo "runners/android orientations: needs aapt2 against the APK's manifest," >&2
  echo "  not a container path. See the comment in this file for the command." >&2
  exit 2
  ;;

screenshot)
  # MEASURED 21 Sep 2026: 1440x3120 8-bit RGBA PNG, 1.6MB, read back by `file`.
  # exec-out rather than shell: `adb shell screencap` mangles the PNG through
  # the pty's newline translation.
  "$ADB" -s "${1:?screenshot <id> <path>}" exec-out screencap -p > "${2:?path}"
  ;;

driver-up|driver-down|driver-scan)
  # UNANSWERED, and the largest of the three. Maestro's Android driver is not
  # XCUITest and shares nothing with it: no xcodebuild, no TEST_RUNNER_PORT, no
  # maestro-driver-iosUITests-Runner process to scan for. It is an instrumented
  # APK reached through `adb forward`, which means the port mapping this package
  # cares so much about is adb's rather than the driver's.
  #
  # ALL FOUR QUESTIONS WERE ANSWERED 21 Sep 2026 against Maestro 2.10.0. Item
  # 87's 4.4 carries the answers and the commands; in short:
  #
  #   THE PORT CAN BE CHOSEN. `maestro --driver-host-port <n>` is a global
  #     option, DEFAULT_DRIVER_HOST_PORT=7001 in maestro/android/
  #     AndroidDeviceConnection, and it is validated at startup — `1` gave
  #     "Requested driver host port 1 is not available" and exit 1. So Android
  #     does NOT repeat the iOS client's hardcoded 22087, and several devices at
  #     once crosses platforms.
  #   THE APKS are maestro-app.apk and maestro-server.apk, inside Maestro's own
  #     maestro-client.jar rather than ~/.maestro/deps, installed as
  #     dev.mobile.maestro and dev.mobile.maestro.test for the length of a run
  #     and gone again afterwards.
  #   `adb forward --list` IS NOT THE ANALOGUE. It stayed empty throughout a
  #     flow: Maestro talks to the adb server through dadb, so there is no
  #     forward to scan and no host socket on the chosen port either.
  #
  # What is left here is writing the three verbs, which is 87's 4.4 and not
  # this item's.
  echo "runners/android $VERB: unanswered — Maestro's Android driver is an" >&2
  echo "  instrumented APK behind 'adb forward', not an xcodebuild test run." >&2
  echo "  See the comment in this file for what has to be measured first." >&2
  exit 2
  ;;

uninstall)
  # MEASURED 21 Sep 2026 against dev.mobile.maestro.test, which Maestro puts
  # back on its next run — AND IT CANNOT FAIL. The redirect and the bare exit 0
  # mean a package that is not there, a device that is not there and a refused
  # removal all look alike from outside. That is deliberate on iOS, where
  # uninstall is a best-effort tidy-up; it is recorded here because a caller
  # must not read this exit status as "the app is gone".
  # `adb uninstall` removes the package and its data.
  "$ADB" -s "${1:?uninstall <id> <app-id>}" uninstall "${2:?app-id}" >/dev/null 2>&1
  exit 0
  ;;

locked)
  # MEASURED 21 Sep 2026, which settled which key to read. On API 34 `dumpsys
  # window` has no mShowingLockscreen at all; the keyguard's own state is
  # mIsShowing, under KeyguardStateMonitor, and mDreamingLockscreen is the
  # screensaver rather than the lock. mAwake tracks the screen and not the lock:
  # KEYCODE_SLEEP took mAwake false with mIsShowing still false, KEYCODE_WAKEUP
  # took it back — so reading mAwake would call a sleeping unlocked emulator
  # locked, which is the mistake this verb exists to avoid.
  #
  # Exit 0 locked, 1 not, 2 the question does not apply — the iOS convention.
  #
  # Measured: asleep 1, awake 1, and a serial that is not attached 2 — dumpsys
  # prints nothing, the key is absent, and "the question does not apply" is the
  # honest answer to a device that is not there.
  #
  # ONE HALF IS UNMEASURED AND SAYS SO: the AVD has no secure lock set, so
  # mIsShowing never went true. The false path is measured both asleep and
  # awake; the true path is read off the key's own meaning.
  case "$("$ADB" -s "${1:?locked <id>}" shell dumpsys window 2>/dev/null |
          sed -n 's/.*mIsShowing=\([a-z]*\).*/\1/p' | head -1)" in
    true)  exit 0 ;;
    false) exit 1 ;;
  esac
  exit 2
  ;;

last-used)
  # STILL REFUSES, and 21 Sep 2026 confirmed the reason rather than assuming it.
  # The iOS answer walks CoreSimulator's per-app data containers for an mtime.
  # An emulator's userdata is a qcow2 image whose mtime moves whenever the
  # emulator writes anything at all, which is not the same question — it says
  # the emulator is running, not that somebody is driving it. `rig reap` wants
  # the second, so a wrong answer here is worse than none: it would keep a
  # forgotten emulator alive forever.
  echo "runners/android last-used: unanswered — an emulator disk image's mtime" >&2
  echo "  says the emulator is running, not that anyone is using it." >&2
  exit 2
  ;;

capture-cmd)
  # STILL A GUESS, and 21 Sep 2026 found the binary it names is empty. Maestro
  # 2.10.0 leaves ~/.maestro/deps/simulator-server ZERO BYTES on this machine —
  # executable, and it exits 0 having done nothing. So the command below runs
  # and produces no frames, which is worse than failing: the wall gets a tile
  # that never updates and no error to explain it.
  #
  # The shape is still the obvious one — the capture binary takes the platform
  # as its first argument and the iOS runner passes `ios` — but where an Android
  # capture actually comes from on a machine with no iOS simulator is unmeasured.
  # Whoever wires the wall to Android starts here.
  echo "$HOME/.maestro/deps/simulator-server android --id ${1:?capture-cmd <id>}"
  exit 0
  ;;

*)
  echo "runners/android: unknown verb '${VERB:-(none)}'" >&2
  exit 2
  ;;
esac
