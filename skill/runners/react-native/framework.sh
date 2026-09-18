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
  # DOCUMENTED, NOT MEASURED. The shape to aim for is remote/build.sh --detect:
  # one fact per line, labelled, writing nothing.
  #
  # The three that will present as a different problem than they are, which is
  # the bar remote/build.sh sets:
  #   node is pinned by nvm/asdf/volta and is on no PATH a non-interactive SSH
  #     shell has, so a bare `node` says "command not found" — the same failure
  #     fvm produces for Flutter, and the same fix: prefer the pinned one.
  #   CocoaPods under a different Ruby, identically to the Flutter iOS path.
  #   the JS dependencies are not installed, so the build fails somewhere deep
  #     rather than saying `node_modules` is absent.
  _repo=${1:?describe <repo>}
  [ -r "$_repo/package.json" ] || { echo "describe: no package.json in $_repo" >&2; exit 1; }
  _rn=$(python3 -c 'import json,sys; print((json.load(open(sys.argv[1])).get("dependencies") or {}).get("react-native",""))' \
        "$_repo/package.json" 2>/dev/null)
  echo "toolchain  $(command -v node 2>/dev/null || echo 'node not on PATH')"
  echo "           $(node --version 2>/dev/null)"
  echo "react-native ${_rn:-unknown}"
  [ -d "$_repo/node_modules" ] || echo "deps       node_modules is absent — the build will fail obscurely"
  exit 0
  ;;

variants)
  # DOCUMENTED, NOT MEASURED, and it is TWO lists, not one — which is the thing
  # to settle before writing it. A React Native project carries iOS schemes in
  # ios/*.xcodeproj and Android productFlavors in android/app/build.gradle, and
  # they need not have the same names. The contract's `variants <repo>` returns
  # one list, so it probably has to take the platform as a second argument.
  echo "runners/react-native variants: unanswered — iOS schemes and Android" >&2
  echo "  productFlavors are two separate lists, and the contract asks for one." >&2
  exit 2
  ;;

variant-for-appid)
  # On iOS this is exactly the Flutter answer — Xcode names each configuration
  # <Debug|Release>-<flavour> and each carries its own PRODUCT_BUNDLE_IDENTIFIER
  # — because it is Xcode's doing, not Flutter's. On Android the evidence is
  # applicationId/applicationIdSuffix per productFlavor in build.gradle, which is
  # a different file and a different parse.
  echo "runners/react-native variant-for-appid: unanswered — see variants" >&2
  exit 2
  ;;

build)
  # DOCUMENTED, NOT MEASURED. Stops at the artefact and installs nothing, as the
  # contract requires:
  #   ios      npx react-native build-ios --mode Debug, output under
  #            ios/build/Build/Products/<Config>-iphonesimulator/*.app
  #   android  ./gradlew assembleDebug, output under
  #            android/app/build/outputs/apk/<flavour>/<mode>/*.apk
  #
  # Name the exact output path rather than globbing for it: the tree holds stale
  # output from earlier builds, and a wildcard picking one of those over the
  # fresh output is a bug this package has already had once (11 Sep 2026).
  echo "runners/react-native build: not written — see the comment in this file" >&2
  exit 2
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
  # DOCUMENTED, NOT MEASURED. Metro is the dev server, and its absence costs
  # much more than Flutter's does: a debug React Native build loads its JS
  # bundle FROM Metro, so with no Metro the app does not merely lose its
  # inspector, it fails to start. That is the opposite of the Flutter case, where
  # driving is unaffected and only the traffic reads are lost — so the wording
  # below must not be copied from there.
  _f=$(pgrep -fl 'cli.js start\|metro' 2>/dev/null | head -2)
  if [ -n "$_f" ]; then printf '%s\n' "$_f"; exit 0; fi
  echo 'none — no Metro bundler is running. Unlike a Flutter app, a debug React'
  echo '       Native build loads its bundle from Metro, so the app itself may'
  echo '       not start. Check that before reading anything as an app bug.'
  exit 1
  ;;

inspect)
  # PLAUSIBLE, NOT MEASURED. Metro serves a Chrome DevTools Protocol target list
  # at http://localhost:8081/json/list, and each entry carries a
  # webSocketDebuggerUrl for the Hermes runtime. The contract wants
  # `<base-uri> <session-id>`, and the natural mapping is the base URL plus the
  # target's id.
  #
  # Two things to establish before trusting it. Metro's port is 8081 by default
  # and moves when something else has it, so it has to be discovered like the
  # Dart VM Service port is rather than assumed. And a target list survives a
  # reload while the target behind it does not, so the cached pair needs the
  # same re-validation vmservice.sh does — a dead target that still answers is
  # the failure that cost a session an empty traffic list read as a quiet app.
  echo "runners/react-native inspect: not written — Metro's CDP target list at" >&2
  echo "  /json/list is the endpoint; the port must be discovered, not assumed." >&2
  exit 2
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
