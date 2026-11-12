#!/bin/sh
# Flutter framework runner — the WORKED EXAMPLE for runners/README.md.
#
# Nothing calls this yet. It exists to prove the contract fits the code that is
# already here, and it does that by delegating: every verb below either runs one
# of the scripts that holds the Flutter logic today, or names the exact lines
# that do. No Flutter logic has been moved out of `remote/build.sh`,
# `remote/vmservice.sh`, `bin/net.sh`, `bin/publish.sh`, `bin/prefs.sh`,
# `bin/preflight.sh` or `remote/gitstate.sh` — they are all unchanged and all
# still in use.
#
# build.sh and vmservice.sh are this module's own files and sit beside this one,
# on both sides: bin/install.sh pushes runners/ keeping its layout. They were in
# remote/ before the seam existed.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift
HERE=$(cd "$(dirname "$0")" && pwd)

# curl through the sandbox proxy when there is one, direct when there is not.
# That is the whole difference between reading the LAN-published relay from here
# and reading the Mac's own loopback over SSH, and it is why one verb serves
# both sides rather than two.
_curl() {
  if [ -n "${grpc_proxy:-}" ]; then curl -s -x "$grpc_proxy" "$@"; else curl -s "$@"; fi
}

# A VM Service flag read, reduced to on|off|unknown.
_vmget() {
  case "$(_curl --max-time 8 "$1" 2>/dev/null)" in
    *'"enabled":true'*)  echo on ;;
    *'"enabled":false'*) echo off ;;
    *)                   echo unknown ;;
  esac
}

case "$VERB" in

claim)
  _repo=${1:?claim <repo>}
  # A Flutter app, not merely a Dart package: pubspec.yaml alone is also a pure
  # Dart library, which builds with `dart` and has no ios/ or android/ at all.
  if [ -r "$_repo/pubspec.yaml" ] && grep -q '^[[:space:]]*flutter:' "$_repo/pubspec.yaml"; then
    echo "pubspec.yaml declares a flutter dependency"
    exit 0
  fi
  exit 1
  ;;

describe)
  # remote/build.sh --detect, unchanged. It reports the fvm-pinned SDK, the
  # CocoaPods GEM_HOME, the flavour derived from the app id, the entrypoint and
  # the last build, and writes nothing.
  #
  # --env prints FLUTTER=, FLAVOR=, TARGET= and GEM_HOME= instead, one per line,
  # for a dependent that reads values rather than the report (item 172). It
  # exits 1 where the report says NOT DECIDED.
  _repo=${1:?describe <repo> [<app-id>] [--env]}; _appid=${2:-}; _env=
  [ "$_appid" = --env ] && { _appid=; _env=--env; }
  [ "${3:-}" = --env ] && _env=--env
  sh "$HERE/build.sh" --repo "$_repo" ${_appid:+--app-id "$_appid"} --detect $_env
  ;;

variants)
  # --platform is accepted and IGNORED, which is the right answer here rather
  # than an omission: a Flutter flavour spans both platforms — one `--flavor
  # uat` builds the iOS app and the Android one — so the list does not differ.
  # React Native's does. (item 87, 4.2)
  [ "${2:-}" = --platform ] && set -- "$1"
  # build.sh owns the rule — a flavour is real only when BOTH halves exist, an
  # ios/*.xcodeproj xcscheme of that name and a lib/main_<f>.dart. It asks it by
  # calling it rather than reproducing the test, so the two cannot drift.
  sh "$HERE/build.sh" --repo "${1:?variants <repo>}" --list-variants
  ;;

variant-for-appid)
  # Same, and --platform is ignored for the same reason.
  [ "${3:-}" = --platform ] && set -- "$1" "$2"
  # Same: the bundle id is the evidence, and build.sh knows how to read it out
  # of project.pbxproj.
  sh "$HERE/build.sh" --repo "${1:?variant-for-appid <repo> <app-id>}" \
     --app-id "${2:?app-id}" --variant-for
  ;;

build)
  # remote/build.sh --build-only: it builds and stops, printing `artifact <path>`
  # as a line of its own. Installing that artefact is platform.sh install.
  _repo=${1:?build <repo> --platform <p> --mode <m> [--variant <v>] [--target <t>]}; shift
  _plat=ios; _mode=debug; _variant=; _target=; _dev=
  while [ $# -gt 0 ]; do
    case $1 in
      --platform) _plat=$2; shift 2 ;;
      --mode)     _mode=$2; _modeset=1; shift 2 ;;
      --variant)  _variant=$2; shift 2 ;;
      --target)   _target=$2; shift 2 ;;
      --app-id)   _appid=$2; shift 2 ;;
      --device)   _dev=$2; shift 2 ;;
      *) echo "runners/flutter build: unknown argument $1" >&2; exit 2 ;;
    esac
  done

  # The platform decides HOW the build runs, not just what it produces. A
  # physical iPhone needs a profile build in the Mac's GUI session, because
  # codesign fails in an SSH one — hence --device rather than --install. The
  # udid is passed rather than read from $DEV: this runs on the far side of an
  # SSH call and the sandbox's environment does not cross it.
  case "$_plat" in
    ios)        set -- --repo "$_repo" --build-only ;;
    ios-device)
      [ -n "$_dev" ] || { echo "runners/flutter build: --platform ios-device needs --device <udid>" >&2; exit 2; }
      set -- --repo "$_repo" --build-only --device "$_dev" ;;
    android|android-device)
      echo "runners/flutter build: Flutter-on-Android is the combination this seam" >&2
      echo "  exists for, and remote/build.sh has no android path — it runs" >&2
      echo "  'flutter build ios' only. See runners/README.md." >&2
      exit 2 ;;
    *) echo "runners/flutter build: unknown platform '$_plat'" >&2; exit 2 ;;
  esac
  [ "$_mode" = release ] && set -- "$@" --release
  # A phone builds profile unless debug is asked for by name: the default mode
  # is debug, and every earlier caller got profile on a phone (item 176).
  [ "$_plat" = ios-device ] && [ "${_modeset:-}" = 1 ] && [ "$_mode" = debug ] && set -- "$@" --debug
  [ -n "${_appid:-}" ] && set -- "$@" --app-id "$_appid"
  [ -n "$_variant" ] && set -- "$@" --flavor "$_variant"
  [ -n "$_target" ] && set -- "$@" --target "$_target"
  sh "$HERE/build.sh" "$@"
  ;;

version)
  # pubspec.yaml's `version: 3.0.4+43` is exactly the pair iOS reports as
  # CFBundleShortVersionString and CFBundleVersion, so the two compare directly
  # with no mapping.
  _repo=${1:?version <repo>}
  _v=$(sed -n 's/^version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$_repo/pubspec.yaml" 2>/dev/null | head -1)
  [ -n "$_v" ] || { echo "runners/flutter version: no version: line in $_repo/pubspec.yaml" >&2; exit 2; }
  echo "$_v"
  exit 0
  ;;

residue)
  # The same five patterns as `_gs_residue` in remote/gitstate.sh, which is
  # still the live copy. Wiring call site 1 leaves only one of the two.
  cat <<'GLOBS'
pubspec.lock
*/pubspec.lock
Podfile.lock
*/Podfile.lock
*/Flutter/Generated.xcconfig
*/Flutter/flutter_export_environment.sh
.flutter-plugins
.flutter-plugins-dependencies
GLOBS
  exit 0
  ;;

devsession)
  # `pgrep -fl flutter_tools`, as bin/preflight.sh runs it. pgrep's status is
  # lost through a pipe, so the output is tested rather than $?.
  _f=$(pgrep -fl flutter_tools 2>/dev/null | head -2)
  if [ -n "$_f" ]; then printf '%s\n' "$_f"; exit 0; fi
  echo 'none — nothing started the app with flutter run, so there is no Dart VM'
  echo '       Service: bin/net.sh and bin/publish.sh will come back empty.'
  echo '       Driving still works. Ask the user before starting one.'
  exit 1
  ;;

device-check)
  # Before `flutter run` on a physical iPhone (item 176). Flutter's bundled
  # artifacts/libusbmuxd/iproxy has been x86_64 only: on an Apple-silicon Mac
  # without Rosetta the app builds, installs and launches, and only then does the
  # run die with "Flutter failed to run .../iproxy ... built with the incorrect
  # architecture" (iPhone 11 Pro, Flutter 3.41.9, Mac oi-jamesl-mac, 11 Nov 2026).
  # Asked before the build, not after it.
  _fl=${1:?device-check <flutter-bin>}
  _root=$(cd "$(dirname "$_fl")/.." 2>/dev/null && pwd -P)
  _ip="$_root/bin/cache/artifacts/libusbmuxd/iproxy"
  _m=$(uname -m)
  [ "$_m" = arm64 ] || { echo "rosetta: not needed on $_m"; exit 0; }
  if [ -e "$_ip" ]; then
    _a=$(lipo -archs "$_ip" 2>/dev/null)
    case " $_a " in *" arm64 "*) echo "rosetta: not needed, Flutter's iproxy is $_a"; exit 0 ;; esac
  fi
  if arch -x86_64 /usr/bin/true 2>/dev/null; then echo "rosetta: installed"; exit 0; fi
  echo "ROSETTA IS NOT INSTALLED on this Mac, and flutter run on a phone needs it:" >&2
  echo "  Flutter's iproxy (${_ip}) is ${_a:-x86_64 once downloaded}, and without Rosetta" >&2
  echo "  the run dies after the install with 'built with the incorrect architecture'." >&2
  echo "  Install it on the Mac, which needs an administrator:" >&2
  echo "    sudo softwareupdate --install-rosetta --agree-to-license" >&2
  exit 1
  ;;

run-diagnose)
  # Name the phone failure a `flutter run` log shows (item 176). Exit 0 with each
  # cause named, 1 when the log shows none of them. A run that reached its VM
  # Service recovered from whatever it warned about first, so the stall and
  # discovery causes are only named when it did not.
  _log=${1:?run-diagnose <flutter-run-log>}
  [ -r "$_log" ] || { echo "run-diagnose: cannot read $_log" >&2; exit 2; }
  _n=0
  if grep -q "incorrect architecture" "$_log"; then
    _n=1
    echo "ROSETTA: Flutter's bundled iproxy is x86_64 and this Mac has no Rosetta. The app is"
    echo "  installed; the run cannot reach it. On the Mac, as an administrator:"
    echo "    sudo softwareupdate --install-rosetta --agree-to-license"
  fi
  if ! grep -qE "A Dart VM Service on|Dart VM Service .* is available at" "$_log"; then
    if grep -q "LLDB is taking longer than expected" "$_log"; then
      _n=1
      echo "LLDB STALL: lldb attached but never handed the app on. Measured on an iPhone 11 Pro"
      echo "  (iOS 26.5.2, Xcode 27.2) this went silent for 11 minutes, with device support for"
      echo "  the phone present. Stop the run rather than wait. The app is installed: launch it"
      echo "  (xcrun devicectl device process launch --device <udid> <bundle-id>), read its URI"
      echo "  with framework.sh vm-url <udid> <flutter-bin>, and flutter attach -d <udid>"
      echo "  --debug-url=<uri>, which needs neither LLDB nor mDNS."
    fi
    if grep -qE "errno = 65.*5353|port = 5353|could not access the local network" "$_log"; then
      _n=1
      echo "MDNS BLOCKED: Flutter's VM Service discovery on UDP 5353 failed (errno 65, No route to"
      echo "  host). Granting Local Network and Automation > Xcode to Terminal did not clear it"
      echo "  (11 Nov 2026). Skip discovery: framework.sh vm-url <udid> <flutter-bin> reads the"
      echo "  URI from the phone's log, then flutter attach -d <udid> --debug-url=<uri>."
    fi
    if grep -q "Dart VM Service was not discovered" "$_log"; then
      _n=1
      echo "NO VM SERVICE: flutter run gave up finding the app's Dart VM Service, so hot reload,"
      echo "  inspect and traffic have nothing to talk to. The causes above say why, if named."
    fi
  fi
  [ "$_n" = 1 ] && exit 0
  echo "run-diagnose: no known phone failure in $_log"
  exit 1
  ;;

vm-url)
  # The app's Dart VM Service URI as the phone logs it, for `flutter attach
  # --debug-url=<it>`, which skips both LLDB and mDNS discovery (item 176). Run it
  # just before or after launching the debug build (devicectl device process
  # launch): it waits up to <seconds> for the app's "The Dart VM service is
  # listening on" line and prints the URI. The URI is the phone's own loopback;
  # flutter attach forwards it. Measured on the XS Max (iOS 18.7.9, Flutter
  # 3.41.9, 12 Nov 2026): attach came up and a hot reload went through.
  _udid=${1:?vm-url <udid> <flutter-bin> [seconds]}; _fl=${2:?flutter-bin}; _w=${3:-30}
  _t=${TMPDIR:-/tmp}/vm-url-$_udid.$$
  sh "$0" logs "$_udid" "$_fl" > "$_t" 2>&1 &
  _p=$!
  _u=
  for _i in $(seq 1 "$_w"); do
    _u=$(grep -o 'VM service is listening on http://[^ ]*' "$_t" 2>/dev/null | tail -1 | sed 's/.*listening on //')
    [ -n "$_u" ] && break
    kill -0 "$_p" 2>/dev/null || break
    sleep 1
  done
  pkill -P "$_p" 2>/dev/null; kill "$_p" 2>/dev/null; wait "$_p" 2>/dev/null
  pkill -f "idevicesyslog -u $_udid" 2>/dev/null
  if [ -n "$_u" ]; then rm -f "$_t"; echo "$_u"; exit 0; fi
  echo "vm-url: no 'VM service is listening' line from $_udid in ${_w}s — is a debug build running?" >&2
  sed 's/^/  /' "$_t" | tail -3 >&2; rm -f "$_t"
  exit 1
  ;;

logs)
  # The app's print/debugPrint output from a phone (item 176). Release-mode
  # flutter run and `devicectl device process launch --console` show none, `log
  # stream` has no device option and devicectl has no syslog subcommand. `flutter
  # logs -d <udid>` printed only its "Showing ... logs:" header on the XS Max
  # (Flutter 3.41.9, 12 Nov 2026), from the project directory or not, while the
  # idevicesyslog bundled in the same SDK streamed the app's `flutter:` lines. So
  # this runs that idevicesyslog with the SDK's libraries and keeps those lines.
  _udid=${1:?logs <udid> <flutter-bin>}; _fl=${2:?flutter-bin}
  sh "$0" device-check "$_fl" >/dev/null || exit 1
  _a="$(cd "$(dirname "$_fl")/.." 2>/dev/null && pwd -P)/bin/cache/artifacts"
  [ -x "$_a/libimobiledevice/idevicesyslog" ] || {
    echo "logs: no $_a/libimobiledevice/idevicesyslog — run 'flutter precache --ios' on the Mac" >&2; exit 1; }
  _dl=$(for _d in "$_a"/*/; do printf '%s:' "$_d"; done)
  DYLD_LIBRARY_PATH="$_dl" "$_a/libimobiledevice/idevicesyslog" -u "$_udid" 2>&1 |
    grep --line-buffered -E 'flutter: |No device found|Library not loaded'
  ;;

inspect)
  # remote/vmservice.sh, unchanged: the flutter run logs first because a file
  # survives however long the build took, then the last VM_LOG_WINDOW of the
  # simulator log. It caches, re-validates, and keeps the two failures apart.
  _dev=${1:?inspect <device> <cache>}; _cache=${2:?cache}
  bash "$HERE/vmservice.sh" "$_dev" "$_cache"
  ;;

traffic-arm)
  # dart:io HTTP profiling is OFF by default and lives on the isolate, so it has
  # to be re-armed after anything that replaces the isolate: a restart, a hot
  # restart, clearState. Prints what it found and what it left, because "already
  # on" and "was off, now on" are different facts — in the second, nothing before
  # this moment was recorded and a short list is not a quiet app.
  _base=${1:?traffic-arm <base> <session>}; _iso=${2:?session}
  _was=$(_vmget "$_base/ext.dart.io.httpEnableTimelineLogging?isolateId=$_iso")
  case "$_was" in
    on)  echo "on on"; exit 0 ;;
    off) _vmget "$_base/ext.dart.io.httpEnableTimelineLogging?isolateId=$_iso&enabled=true" >/dev/null
         echo "off $(_vmget "$_base/ext.dart.io.httpEnableTimelineLogging?isolateId=$_iso")"
         exit 0 ;;
    *)   echo "unknown unknown"; exit 1 ;;
  esac
  ;;

traffic-list)
  _base=${1:?traffic-list <base> <session>}; _iso=${2:?session}
  _out=${LDIR:-${TMPDIR:-/tmp}}/runner-net.json
  _curl "$_base/ext.dart.io.getHttpProfile?isolateId=$_iso" > "$_out" || exit 1
  python3 "$HERE/net.py" list "$_out"
  ;;

traffic-one)
  _base=${1:?traffic-one <base> <session> <id>}; _iso=${2:?session}; _id=${3:?id}
  _out=${LDIR:-${TMPDIR:-/tmp}}/runner-net1.json
  _curl "$_base/ext.dart.io.getHttpProfileRequest?isolateId=$_iso&id=$_id" > "$_out" || exit 1
  python3 "$HERE/net.py" one "$_out"
  ;;

prefs-prefix)
  # shared_preferences writes every key as flutter.<key> into NSUserDefaults,
  # which is why bin/prefs.sh defaults its filter to exactly this.
  echo flutter
  exit 0
  ;;

*)
  echo "runners/flutter: unknown verb '${VERB:-(none)}'" >&2
  exit 2
  ;;
esac
