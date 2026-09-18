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
# remote/ until 18 Sep, which is where they were before the seam existed.
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
  _repo=${1:?describe <repo>}; _appid=${2:-}
  sh "$HERE/build.sh" --repo "$_repo" ${_appid:+--app-id "$_appid"} --detect
  ;;

variants)
  # build.sh owns the rule — a flavour is real only when BOTH halves exist, an
  # ios/*.xcodeproj xcscheme of that name and a lib/main_<f>.dart. This asked it
  # by reproducing the test until 18 Sep; now it asks it by calling it, so the
  # two cannot drift.
  sh "$HERE/build.sh" --repo "${1:?variants <repo>}" --list-variants
  ;;

variant-for-appid)
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
      --mode)     _mode=$2; shift 2 ;;
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
  [ -n "${_appid:-}" ] && set -- "$@" --app-id "$_appid"
  [ -n "$_variant" ] && set -- "$@" --flavor "$_variant"
  [ -n "$_target" ] && set -- "$@" --target "$_target"
  sh "$HERE/build.sh" "$@"
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
