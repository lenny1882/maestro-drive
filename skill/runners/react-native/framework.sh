#!/bin/sh
# React Native framework runner — STUB.
#
# NOTHING IN THIS FILE HAS BEEN RUN. No React Native checkout has been built
# through it and no Metro session has been read by it. Every command below is
# what the documented tool takes, not what was measured, and each verb says
# which of the two it is.
#
# The verb worth reading first is `traffic-list`, because its honest answer is
# "React Native has no equivalent" — and saying that plainly is the whole reason
# the contract has an exit status for it.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift
: "${RDIR:=/tmp/maestro-mac}"
HERE=$(cd "$(dirname "$0")" && pwd)
: "${NVM_DIR:=$HOME/.nvm}"

# The bin dir of a node react-native accepts, as the first word of a line
# whose rest says why. See project.py node.
_node_bin() { python3 "$HERE/project.py" node "$1" "$NVM_DIR"; }

case "$VERB" in

claim)
  # A package.json that depends on react-native. Checked in dependencies rather
  # than anywhere in the file, so a repo that merely mentions it in a script or
  # a devDependency for tooling does not claim the checkout.
  _repo=${1:?claim <repo>}
  [ -r "$_repo/package.json" ] || exit 1
  if python3 - "$_repo/package.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
sys.exit(0 if "react-native" in (d.get("dependencies") or {}) else 1)
PY
  then
    echo "package.json depends on react-native"
    exit 0
  fi
  exit 1
  ;;

describe)
  # One fact per line, labelled, writing nothing — the shape of the Flutter
  # build.sh --detect. The facts are the ones that fail as something else:
  #   the node on PATH is nvm's default, not one react-native accepts, and
  #     Gradle's autolinking step dies running it rather than naming node
  #   node_modules is absent, and the build fails deep inside Gradle
  #   no android/ (an Expo app before `expo prebuild`), so there is no Gradle
  #     project to run at all
  _repo=${1:?describe <repo>}; _appid=${2:-}
  [ -r "$_repo/package.json" ] || { echo "describe: no package.json in $_repo" >&2; exit 1; }
  python3 - "$_repo/package.json" <<'PY'
import json, sys
d = (json.load(open(sys.argv[1])).get("dependencies") or {})
print("react-native", d.get("react-native", "unknown"))
if "expo" in d:
    print("expo        ", d["expo"])
PY
  if _n=$(_node_bin "$_repo" 2>&1); then
    echo "node        $("${_n%% *}/node" --version)  ${_n%% *}  (${_n#* })"
  else
    echo "node        none usable — $_n"
  fi
  [ -d "$_repo/node_modules" ] || echo "deps        node_modules is absent — run npm install; the build fails inside Gradle without it"
  if [ -d "$_repo/android" ]; then
    _fl=$(python3 "$HERE/project.py" flavours "$_repo" | tr '\n' ' ')
    echo "android     $_repo/android"
    echo "flavours    ${_fl:-none}"
    if [ -n "$_appid" ]; then
      if _v=$(python3 "$HERE/project.py" for-appid "$_repo" "$_appid" 2>&1); then
        echo "app id      $_appid builds as ${_v:-the only variant}"
      else
        echo "app id      $_v"
      fi
    fi
    _sdk=$(sed -n 's/^sdk\.dir=//p' "$_repo/android/local.properties" 2>/dev/null)
    echo "sdk         ${_sdk:-${ANDROID_HOME:-${ANDROID_SDK_ROOT:-none — set ANDROID_HOME or android/local.properties sdk.dir}}}"
    echo "java        ${JAVA_HOME:-$(command -v java 2>/dev/null || echo 'none on PATH')}"
    for _m in debug release; do
      _a=$(find "$_repo/android/app/build/outputs/apk" -name "*-$_m.apk" 2>/dev/null | head -1)
      [ -n "$_a" ] && echo "last build  $_a  $(date -r "$_a" '+%Y-%m-%d %H:%M')"
    done
  else
    echo "android     none — no android/ directory; an Expo app needs 'npx expo prebuild' first"
  fi
  [ -d "$_repo/ios" ] || echo "ios         none — no ios/ directory"
  exit 0
  ;;

variants)
  # item 87, 4.2: `variants <repo> [--platform <p>]`. Android product flavours
  # come from android/app/build.gradle. iOS schemes are not read yet: the
  # checkout this was written against has no ios/.
  _repo=${1:?variants <repo> [--platform <p>]}; _plat=${3:-android}
  [ "${2:-}" = --platform ] || _plat=android
  case "$_plat" in
    android|android-device) python3 "$HERE/project.py" flavours "$_repo" ;;
    *) echo "runners/react-native variants: $_plat schemes are not read yet —" >&2
       echo "  written against a checkout with android/ only." >&2
       exit 2 ;;
  esac
  ;;

variant-for-appid)
  # On Android the evidence is applicationId and applicationIdSuffix per
  # flavour and per build type in build.gradle. Prints the flavour, or nothing
  # when the project has none and the app id is its own.
  _repo=${1:?variant-for-appid <repo> <app-id> [--platform <p>]}; _id=${2:?app-id}
  _plat=android; [ "${3:-}" = --platform ] && _plat=${4:-android}
  case "$_plat" in
    android|android-device) python3 "$HERE/project.py" for-appid "$_repo" "$_id" ;;
    *) echo "runners/react-native variant-for-appid: $_plat is not read yet — see variants." >&2
       exit 2 ;;
  esac
  ;;

build)
  # Stops at the artefact and installs nothing, as the contract requires.
  # Android only: ./gradlew assemble<Flavour><Mode> in android/, with a node
  # react-native accepts at the front of PATH, because Expo's and React
  # Native's Gradle plugins run node for autolinking and for the JS bundle.
  #
  # The artefact is the file Gradle's output-metadata.json names in the
  # variant's own output directory, not a glob over outputs/apk: the tree holds
  # stale APKs from earlier builds, and a wildcard picking one of those over the
  # fresh output is a bug this package has already had once.
  _repo=${1:?build <repo> --platform <p> --mode <m> [--variant <v>]}; shift
  _plat=android; _mode=debug; _variant=; _appid=
  while [ $# -gt 0 ]; do
    case $1 in
      --platform) _plat=$2; shift 2 ;;
      --mode)     _mode=$2; shift 2 ;;
      --variant)  _variant=$2; shift 2 ;;
      --app-id)   _appid=$2; shift 2 ;;
      --target|--device) shift 2 ;;
      *) echo "runners/react-native build: unknown argument $1" >&2; exit 2 ;;
    esac
  done
  case "$_plat" in
    android|android-device) ;;
    *) echo "runners/react-native build: $_plat is not written — the checkout it was" >&2
       echo "  written against has android/ only." >&2
       exit 2 ;;
  esac
  case "$_mode" in
    debug|release) ;;
    *) echo "runners/react-native build: --mode $_mode — React Native builds debug or release" >&2; exit 2 ;;
  esac
  [ -x "$_repo/android/gradlew" ] || { echo "runners/react-native build: no android/gradlew in $_repo —
  an Expo app needs 'npx expo prebuild' first" >&2; exit 1; }
  [ -d "$_repo/node_modules" ] || { echo "runners/react-native build: node_modules is absent in $_repo — run npm install" >&2; exit 1; }
  _n=$(_node_bin "$_repo") || exit 1
  _nb=${_n%% *}

  # The app id is the evidence for the flavour, as on iOS: when it names one,
  # build that one, and refuse rather than guess when it names several.
  if [ -z "$_variant" ] && [ -n "$_appid" ]; then
    _variant=$(python3 "$HERE/project.py" for-appid "$_repo" "$_appid") || exit 1
  fi
  if [ -z "$_variant" ] && [ -n "$(python3 "$HERE/project.py" flavours "$_repo")" ]; then
    echo "runners/react-native build: the project has flavours and nothing says which:" >&2
    python3 "$HERE/project.py" flavours "$_repo" | sed 's/^/  /' >&2
    echo "  pass --flavor, or set APP_ID to the one under test." >&2
    exit 2
  fi
  _cap() { printf '%.1s' "$1" | tr '[:lower:]' '[:upper:]'; printf '%s' "${1#?}"; }
  _task="assemble$(_cap "$_variant")$(_cap "$_mode")"
  _out="$_repo/android/app/build/outputs/apk/${_variant:+$_variant/}$_mode"

  # Gradle's output goes to stderr so that stdout carries only the artefact.
  echo "build       $_task with node $("$_nb/node" --version)" >&2
  _t0=$(date +%s)
  (cd "$_repo/android" && PATH="$_nb:$PATH" ./gradlew --console=plain "$_task") >&2 \
    || { echo "runners/react-native build: ./gradlew $_task failed" >&2; exit 1; }
  _apk=$(python3 - "$_out/output-metadata.json" <<'PY'
import json, os, sys
try:
    d = json.load(open(sys.argv[1]))
    print(os.path.join(os.path.dirname(sys.argv[1]), d["elements"][0]["outputFile"]))
except Exception as e:
    print(f"cannot read {sys.argv[1]}: {e}", file=sys.stderr)
    sys.exit(1)
PY
  ) || exit 1
  # No mtime check against the start of the build: a build with nothing to do
  # leaves the APK UP-TO-DATE and untouched, and it is still the current one.
  [ -f "$_apk" ] || { echo "runners/react-native build: Gradle named $_apk and it is not there" >&2; exit 1; }
  echo "build       $(( $(date +%s) - _t0 ))s" >&2
  echo "artifact $_apk"
  ;;

version)
  # item 87, 6.2: `version <repo> [--platform <p>]`, the named platform's pair,
  # as `variants` takes it. Not package.json's version, which is the JS
  # package's: Android's is versionName+versionCode in android/app/build.gradle,
  # iOS's is in the Xcode project. Expo's app.json carries them too, but they
  # reach Gradle only on the next `expo prebuild`, so build.gradle is what a
  # build from this checkout produces. A flavour that sets its own is not read:
  # this verb is given no app id to tell which flavour is installed.
  _repo=${1:?version <repo> [--platform <p>]}
  _plat=android; [ "${2:-}" = --platform ] && _plat=${3:-android}
  case "$_plat" in
    android|android-device) python3 "$HERE/project.py" version "$_repo" || exit 2 ;;
    *) echo "runners/react-native version: $_plat is not read yet — see variants." >&2
       exit 2 ;;
  esac
  ;;

residue)
  # The paths a React Native build regenerates and a repo commits. yarn.lock and
  # package-lock.json are the JS half; Podfile.lock and Pods/ are the iOS half
  # and are shared with the Flutter runner, because they are CocoaPods' doing
  # rather than either framework's.
  cat <<'GLOBS'
yarn.lock
*/yarn.lock
package-lock.json
*/package-lock.json
Podfile.lock
*/Podfile.lock
ios/Pods/*
android/local.properties
GLOBS
  exit 0
  ;;

devsession)
  # MEASURED against `expo start` (Expo 58, RN 0.88). Metro is the dev server,
  # and its absence costs much more than Flutter's does: a debug React Native
  # build loads its JS bundle FROM Metro, so with no Metro the app does not
  # merely lose its inspector, it fails to start. That is the opposite of the
  # Flutter case, where driving is unaffected and only the traffic reads are
  # lost — so the wording below must not be copied from there.
  #
  # Metro is asked, not looked for. Under Expo the processes are `npm exec expo
  # start` and `node …/node_modules/.bin/expo start`; neither says `metro` or
  # `cli.js start`, and a pattern for them said "none" beside a running Metro.
  # Its /status answers `packager-status:running`. RCT_METRO_PORT is the port
  # the app's build was told, 8081 unless set. The process match only names it.
  _port=${RCT_METRO_PORT:-8081}
  _s=$(curl -s -m 3 "http://localhost:$_port/status" 2>/dev/null)
  # pgrep -l prints the command line on macOS and only `node` on Linux, so ps
  # prints it.
  _p=$(pgrep -f 'node .*(expo|react-native|cli\.js) start' 2>/dev/null | head -2 | paste -sd, -)
  _f=; [ -n "$_p" ] && _f=$(ps -o pid=,args= -p "$_p" 2>/dev/null)
  if [ "$_s" = packager-status:running ]; then
    echo "Metro is running on :$_port"
    [ -n "$_f" ] && printf '%s\n' "$_f"
    exit 0
  fi
  echo "none — no Metro bundler answers on :$_port. Unlike a Flutter app, a debug"
  echo '       React Native build loads its bundle from Metro, so the app itself'
  echo '       may not start. Check that before reading anything as an app bug.'
  [ -n "$_f" ] && { echo "       A Metro process is running but not on :$_port:"; printf '       %s\n' "$_f"; }
  exit 1
  ;;

inspect)
  # MEASURED against `expo start` (Expo 58, RN 0.88) and emulator-5554. Prints
  # `<webSocketDebuggerUrl> <target id>` for the app's Hermes target in Metro's
  # /json/list, e.g.
  #   ws://127.0.0.1:8081/inspector/debug?device=6795…&page=1 6795…-1
  # A CDP Runtime.evaluate over that URL answered.
  #
  # The port is the one devsession asks: RCT_METRO_PORT, 8081 unless set. It
  # is what the app's build was told, so it is the port the app connects to.
  #
  # 127.0.0.1, NOT localhost. The inspector proxy refuses the upgrade (401)
  # without an Origin, and with Origin http://localhost:8081 it accepts the
  # upgrade and then drops the session (1006) before any message reaches the
  # device. URL and Origin both 127.0.0.1 work. A client must send that Origin.
  #
  # NO CACHE, so the cache argument is unused. The target id and URL stayed the
  # same across a CDP Page.reload and an app force-stop and restart, and kept
  # answering; only the runtime behind them was new (a global set before read
  # back unset). A pair cannot go stale while the app is connected, and after a
  # restart the list is empty until the app reconnects, which is read fresh
  # every call. Metro's POST /reload answered 200 and reloaded nothing.
  _port=${RCT_METRO_PORT:-8081}
  _l=$(curl -s -m 3 "http://127.0.0.1:$_port/json/list" 2>/dev/null) || _l=
  if [ -z "$_l" ]; then
    echo "no Metro answers on :$_port — see devsession." >&2; exit 1
  fi
  printf '%s' "$_l" | APP_ID="${APP_ID:-}" python3 -c '
import json, os, sys
try:
    ts = json.load(sys.stdin)
except ValueError:
    sys.exit("Metro on :%s did not return a target list" % sys.argv[1])
app = os.environ["APP_ID"]
ts = [t for t in ts if t.get("webSocketDebuggerUrl") and (not app or t.get("appId") == app)]
if not ts:
    sys.exit("Metro is running but no app%s is connected to it: the Hermes target "
             "appears once the app has loaded its bundle." % (" " + app if app else ""))
if len(ts) > 1:
    sys.exit("%d targets, and nothing here yet tells which is this device:\n%s" % (len(ts),
             "\n".join("  %s  %s" % (t["id"], t.get("deviceName", "?")) for t in ts)))
t = ts[0]
print(t["webSocketDebuggerUrl"].replace("ws://localhost:", "ws://127.0.0.1:", 1), t["id"])
' "$_port"
  ;;

traffic-arm|traffic-list|traffic-one)
  # THE HONEST ANSWER, and the reason exit 2 exists in this contract.
  #
  # Flutter has this because dart:io routes every HTTP call through one runtime
  # that can be asked to record them. React Native has no such chokepoint: fetch
  # goes to NSURLSession on iOS and OkHttp on Android, and neither reports to the
  # JS runtime. The CDP Network domain is not implemented by Hermes.
  #
  # So a React Native project reads traffic through a proxy the app is pointed
  # at, which is a different shape entirely — it is configured before the app
  # starts, not armed while it runs. Whoever wires that should add a verb for it
  # rather than pretending this one works.
  echo "React Native has no in-runtime HTTP capture: fetch goes to NSURLSession" >&2
  echo "  and OkHttp, neither of which reports to the JS runtime. Read traffic" >&2
  echo "  through a proxy the app is pointed at before it starts." >&2
  exit 2
  ;;

prefs-prefix)
  # AsyncStorage does not write NSUserDefaults at all — it keeps its own store,
  # a file on iOS and SQLite on Android — so there is no prefix, and reading the
  # platform's preferences back will not show an app's own state. Empty output
  # with exit 0 says "no prefix"; it does not say "the store is the platform's".
  exit 0
  ;;

*)
  echo "runners/react-native: unknown verb '${VERB:-(none)}'" >&2
  exit 2
  ;;
esac
