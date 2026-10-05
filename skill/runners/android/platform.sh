#!/bin/sh
# Android platform runner.
#
# MEASURED (BACKLOG item 94, 5.3). Every verb below has run against
# Pixel_6_Pro_API_34 — `sdk_gphone64_x86_64`, API 34 — on the machine this
# package is driven from, reached over item 96's bridge, with the SDK at
# /mnt/sda/User/Programs/android-sdk and Maestro 2.10.0. Each verb says what it
# did and what it printed; where a verb still refuses, the comment says what was
# run to establish that it has to.
#
# Three still refuse, and each refusal is a measurement rather than a gap in the
# writing: `container` (appcheck's timestamp-and-plist pair has no Android
# twin), `orientations` (the answer is in the APK, not in a container path) and
# `driver-up` (item 87's 4.4: a Maestro run brings its own driver and removes
# it, so there is none to start ahead of one).
#
# Runs ON THE MACHINE WITH THE DEVICE, except `claim`.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift
ADB=${ADB:-adb}

case "$VERB" in

claim)
  # MEASURED: `emulator-5554` claimed (0), `00008020-0011` refused
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
  # line. MEASURED, with and without --booted, both printing
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
  # SETTLED (item 87, 4.1): `boot` PRINTS THE ID IT BOOTED as its last
  # line, and the caller uses that from then on. So this takes an AVD name and
  # must end by printing the emulator-NNNN serial it landed on — which means
  # waiting for the device to appear in `adb devices` and working out which of
  # them is new, since the serial comes from the port the emulator took.
  #
  # MEASURED against Pixel_6_Pro_API_34 on this machine, over the
  # bridge (item 96). Three things the writing had to get right:
  #
  #   the serial is not knowable in advance, so the new one is found by
  #   difference against the serials that were there before;
  #   a serial in `adb devices` is not a booted device, so sys.boot_completed
  #   is polled until it reads 1;
  #   the emulator has to outlive this script, so it is detached — a caller
  #   that returns and takes the device with it would be no boot at all.
  #
  # DETACHED MEANS setsid, NOT nohup, and the difference is a booted emulator
  # lost. nohup blocks SIGHUP and leaves the process in the caller's
  # process group; every request over the bridge runs under `timeout`, which
  # manages a group of its own, so the emulator went down with the group a
  # couple of calls later — "Wait for emulator (pid …) 20 seconds to shutdown
  # gracefully", in its own log. setsid gives it its own session and group.
  _avd=${1:?boot <avd name>}
  _emu=${EMULATOR:-}
  [ -n "$_emu" ] || _emu=$(command -v emulator 2>/dev/null)
  [ -n "$_emu" ] || _emu="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}/emulator/emulator"
  [ -x "$_emu" ] || { echo "no emulator binary — set ANDROID_HOME or EMULATOR" >&2; exit 1; }

  # ONE DEADLINE, BOOT_TMO seconds, for the whole boot (item 108). There were
  # two loops of 180 polls each, and both were wrong in a different way:
  #
  #   the first counted a serial only once it read `device`, but a second
  #   emulator booted straight after another sat at `offline` past 180s
  #   ("Loading snapshot 'default_boot'..." the last line of its log) and then
  #   booted — so `boot` reported a failure for an emulator that came up;
  #   the second, on running out, printed the serial and exited 0 whether or not
  #   sys.boot_completed had ever read 1 — success for a device not yet booted.
  #
  # So a new serial counts in ANY state, the baseline is every serial in any
  # state, and running out is a failure that names the serial left behind.
  # `adb wait-for-device` went too: it has no timeout of its own, and the poll
  # below covers it — getprop fails until the device is up.
  #
  # 420 by default. Three emulators booted back to back on this machine (8
  # cores, 31 GB) took 79s, 167s and 226s, load 18 at the end; 180 would have
  # failed the third. drivers.sh gives its transport 30s more than this.
  _tmo=${BOOT_TMO:-420}
  _t0=$(date +%s)
  _left() { echo $((_tmo - ($(date +%s) - _t0))); }
  _serials() { "$ADB" devices 2>/dev/null | sed 1d | awk 'NF{print $1}'; }
  _before=" $(_serials | tr '\n' ' ') "
  _log=${RDIR:-/tmp}/emulator-$_avd.log
  mkdir -p "$(dirname "$_log")" 2>/dev/null || true
  if command -v setsid >/dev/null 2>&1; then
    setsid "$_emu" -avd "$_avd" -no-boot-anim >"$_log" 2>&1 &
  else
    nohup "$_emu" -avd "$_avd" -no-boot-anim >"$_log" 2>&1 &
  fi
  _pid=$!

  _new=
  while :; do
    kill -0 "$_pid" 2>/dev/null || {
      echo "the emulator exited while starting. Its log:" >&2
      tail -5 "$_log" >&2
      exit 1; }
    if [ -z "$_new" ]; then
      for _s in $(_serials); do
        case "$_before" in *" $_s "*) ;; *) _new=$_s; break ;; esac
      done
    fi
    if [ -n "$_new" ] &&
       [ "$("$ADB" -s "$_new" shell getprop sys.boot_completed </dev/null 2>/dev/null | tr -d '\r\n')" = 1 ]; then
      echo "$_new"
      exit 0
    fi
    [ "$(_left)" -gt 0 ] || break
    sleep 1
  done
  if [ -n "$_new" ]; then
    echo "$_new has not finished booting after ${_tmo}s (BOOT_TMO). It is still" >&2
    echo "  running; 'platform.sh shutdown $_new' stops it. Its log:" >&2
  else
    # MEASURED with BOOT_TMO=20: the emulator was still starting and went on to
    # take a serial, so it is named here rather than left to be found.
    echo "no new device appeared within ${_tmo}s (BOOT_TMO). The emulator is" >&2
    echo "  still running as pid $_pid; 'kill $_pid' stops it. Its log:" >&2
  fi
  tail -5 "$_log" >&2
  exit 1
  ;;

shutdown)
  # MEASURED, AND IT RETURNS BEFORE THE DEVICE IS GONE. `adb emu
  # kill` printed "OK: killing emulator, bye bye" and "OK" and came back in
  # 0.00s; the serial was still in `adb devices` three seconds later and gone
  # within fifteen. A caller that shuts down and then counts devices, or boots
  # and expects a fresh serial, will see the old one. `boot` is safe from it —
  # it takes the serials that were there as its baseline — but nothing else here
  # waits for this.
  "$ADB" -s "${1:?shutdown <id>}" emu kill
  ;;

install)
  # MEASURED: -r over a 114MB APK pulled off the device itself,
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
  # MEASURED against com.example.consumer.dev:
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
  # MEASURED, which is what makes this a decision and not a guess.
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
  # WAS ONCE UNREACHABLE. This case was headed `container)` a
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
  # MEASURED, AND THE GLOB IS TOO WIDE. shared_prefs/ held 28 files
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
  # MEASURED, exit 0 — and what it verifies is that the keyevent was
  # accepted, not that anything reached disk; the app was launched rather than
  # written to, so there was nothing pending to flush.
  # SharedPreferences.apply() writes on a background
  # thread and is flushed when the activity is stopped, so backgrounding the app
  # is the same trick the iOS side plays with notifyutil.
  "$ADB" -s "${1:?prefs-flush <id> <app-id>}" shell input keyevent KEYCODE_HOME
  sleep 0.5
  ;;

orientations)
  # STILL REFUSES, and the reason was measured rather than assumed. The
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
  # MEASURED: 1440x3120 8-bit RGBA PNG, 1.6MB, read back by `file`.
  # exec-out rather than shell: `adb shell screencap` mangles the PNG through
  # the pty's newline translation.
  "$ADB" -s "${1:?screenshot <id> <path>}" exec-out screencap -p > "${2:?path}"
  ;;

driver-up)
  # THERE IS NO STANDING DRIVER TO START. Measured against Maestro 2.10.0 on two
  # emulators at once (item 87, 4.4):
  #
  #   every `maestro` run installs dev.mobile.maestro and dev.mobile.maestro.test,
  #     starts `am instrument … -e port <n>` and removes both APKs when it ends;
  #     the driver process appeared about 20s into a run and was gone after it;
  #   the server listens on the DEVICE's port <n> (/proc/net/tcp6 on the
  #     emulator showed 7101 for --driver-host-port 7101) and the host reaches it
  #     through an adb stream per socket (AdbSocketFactory), so nothing binds on
  #     the host and two emulators both on the default 7001 ran side by side;
  #   a second run on the same emulator took the driver from the first, which
  #     failed with DeviceServerDiedException ... Command failed (tcp:7101).
  #
  # So a driver started here would be replaced and uninstalled by the next
  # flow, and nothing in this package speaks its gRPC protocol anyway. The ports
  # map has nothing to allocate either: the port lives on the device.
  echo "runners/android driver-up: Android has no standing driver. Each maestro" >&2
  echo "  run installs, starts and removes its own on the device, so there is" >&2
  echo "  nothing to start ahead of a flow. driver-scan lists runs in flight." >&2
  exit 2
  ;;

driver-down)
  # Stops every maestro run holding this device. MEASURED: TERM ended the run
  # within a second and the driver process with it, but both APKs were still
  # installed afterwards, where a run that finishes removes them. So the device
  # is put back the way a finished run leaves it: force-stop, then uninstall.
  # The other emulator's run carried on and passed.
  #
  # AND THE KILLED RUN'S SESSION RECORD STAYS. Maestro keeps
  # ANDROID_<serial>_<uuid>=<heartbeat ms> in ~/.maestro/sessions, heartbeats
  # every 5s, and counts a record as live for 21s (SessionStore). A run that
  # finds a live record for its device does not start a driver of its own — it
  # expects to share one — so the first run after a TERM failed in 2s with
  # DeviceServerDiedException. Every run on this device is dead by now, so
  # every record for it is stale and is removed. A heartbeat from another
  # device's run that read the file before this write can put one back; it
  # then lapses in 21s on its own.
  _id=${1:?driver-down <id>}
  _pids=$(sh "$0" driver-scan | awk -v d="$_id" '$1==d{print $3}')
  [ -n "$_pids" ] && kill $_pids 2>/dev/null
  _i=0
  while [ -n "$_pids" ] && [ "$_i" -lt 20 ]; do
    _left=
    for _p in $_pids; do kill -0 "$_p" 2>/dev/null && _left="$_left $_p"; done
    _pids=$_left
    sleep 0.5
    _i=$((_i + 1))
  done
  "$ADB" -s "$_id" shell am force-stop dev.mobile.maestro >/dev/null 2>&1
  "$ADB" -s "$_id" uninstall dev.mobile.maestro.test >/dev/null 2>&1
  "$ADB" -s "$_id" uninstall dev.mobile.maestro >/dev/null 2>&1
  _ss="$HOME/.maestro/sessions"
  if [ -f "$_ss" ] && grep -q "^ANDROID_${_id}_" "$_ss"; then
    grep -v "^ANDROID_${_id}_" "$_ss" > "$_ss.$$" && mv -f "$_ss.$$" "$_ss"
  fi
  exit 0
  ;;

driver-scan)
  # "<serial> <port> <pid>" per maestro run in flight: the run IS the driver's
  # lifetime, so the live map is the maestro processes on this machine.
  #
  # The serial and port come from the run's own debug log, the line
  # "Selected device emulator-5554 using port 43091". The command line is not
  # enough: WITHOUT --driver-host-port, `maestro test` PICKS A FREE PORT PER RUN
  # (measured 37131, 42439, 35277, 43091) rather than 7001, and without --device
  # it picks the device itself. The log is the one the process holds open under
  # ~/.maestro/tests/<time>/ — named by time, not pid, so it is found through
  # the process's open files: /proc on Linux (measured), lsof elsewhere (not
  # measured). The ~/.cache/maestro/logs/<time>_<pid>/ log carries the pid but
  # was empty.
  #
  # ONE LOG CAN HOLD TWO RUNS. The directory is named to the second, so two
  # runs started in the same second write to the same maestro.log, and taking
  # its first "Selected device" line gave both processes the other run's
  # device. So the command line goes first and the log only fills in what it
  # left open: a log line counts when it agrees with --device and
  # --driver-host-port wherever those were given, and only when exactly one
  # line does. Anything still unknown prints as "?"; a run whose device cannot
  # be named is left out, since a row is only useful keyed by device.
  for _p in $(pgrep -f 'maestro\.cli\.AppKt' 2>/dev/null); do
    if [ -d "/proc/$_p/fd" ]; then
      _logs=$(for _f in /proc/"$_p"/fd/*; do readlink "$_f" 2>/dev/null; done | grep '/maestro\.log$')
    else
      _logs=$(lsof -a -p "$_p" -Fn 2>/dev/null | sed -n 's/^n\(.*\/maestro\.log\)$/\1/p')
    fi
    _sel=$(for _log in $_logs; do
             sed -n 's/.*Selected device \([^ ]*\) using port \([0-9]*\).*/\1 \2/p' "$_log" 2>/dev/null
           done | sort -u | tr '\n' ';')
    ps -o args= -p "$_p" 2>/dev/null | awk -v pid="$_p" -v sel="$_sel" '{
      d = ""; pt = ""
      for (i = 1; i <= NF; i++) {
        if ($i == "--device" || $i == "--udid") d = $(i + 1)
        else if ($i ~ /^--(device|udid)=/) { d = $i; sub(/^[^=]*=/, "", d) }
        else if ($i == "--driver-host-port") pt = $(i + 1)
        else if ($i ~ /^--driver-host-port=/) { pt = $i; sub(/^[^=]*=/, "", pt) }
      }
      n = split(sel, lines, ";"); hit = 0
      for (j = 1; j <= n; j++) {
        if (split(lines[j], f, " ") != 2) continue
        if ((d == "" || f[1] == d) && (pt == "" || f[2] == pt)) { hit++; hd = f[1]; hp = f[2] }
      }
      if (hit == 1) { d = hd; pt = hp }
      if (pt == "") pt = "?"
      if (d != "") print d, pt, pid
    }'
  done
  exit 0
  ;;

uninstall)
  # MEASURED against dev.mobile.maestro.test, which Maestro puts
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
  # MEASURED, which settled which key to read. On API 34 `dumpsys
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
  # "<id>|<yyyymmdd>|<human>|<today>" for every booted device, for `rig reap`.
  # The answer is the device's LAST TOUCH OR KEY INPUT, from PowerManager.
  #
  # Three candidates were measured (item 87); two answer a different question:
  #   the userdata qcow2's mtime moves whenever the emulator writes anything,
  #     so it says the emulator is running, not that anyone is driving it;
  #   `dumpsys usagestats` lastTimeUsed moved for the launcher and Settings on
  #     an emulator nobody touched for a minute, and Settings' lastTimeVisible
  #     equalled the moment of the read itself;
  #   `dumpsys power` mLastUserActivityTime held still across 90s idle and three
  #     reads, moved on one `adb shell input tap`, and moved on a Maestro flow's
  #     tapOn (326361 -> 455696 ms). Same line on API 34 and API 36.
  #
  # It is uptime milliseconds, so the epoch is now - (uptime - it). Boot sets
  # it (54.3s uptime read 53667 on a fresh API 36 boot), so a device nobody has
  # touched since boot reports its boot time, and one booted on a previous day
  # and never driven since is that day's.
  #
  # NOT COUNTED: a flow that sends no input. launchApp plus assertions left it
  # where it was. Neither does the iOS answer count a flow that writes nothing.
  #
  # Dates are this machine's, as on iOS: today comes from here, so clock skew
  # between devices cannot make a live one look old.
  _now=$(date +%s)
  _today=$(date +%Y%m%d)
  _fmt() { date -d "@$1" "$2" 2>/dev/null || date -r "$1" "$2" 2>/dev/null; }
  for _s in $("$ADB" devices 2>/dev/null | sed -n 's/[[:space:]]*device$//p'); do
    _r=$("$ADB" -s "$_s" shell 'cut -d" " -f1 /proc/uptime; dumpsys power | grep mLastUserActivityTime' </dev/null 2>/dev/null | tr -d '\r')
    _up=$(printf '%s\n' "$_r" | sed -n '1s/\..*//p')
    _la=$(printf '%s\n' "$_r" | sed -n 's/.*mLastUserActivityTime[^=]*=\([0-9]*\).*/\1/p' | head -1)
    if [ -z "$_up" ]; then
      echo "$_s|||$_today"
      continue
    fi
    [ -n "$_la" ] || _la=0
    _e=$((_now - _up + _la / 1000))
    echo "$_s|$(_fmt "$_e" +%Y%m%d)|$(_fmt "$_e" '+%Y-%m-%d %H:%M')|$_today"
  done
  exit 0
  ;;

capture-cmd)
  # STILL A GUESS, and the binary it names was found to be empty. Maestro
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
