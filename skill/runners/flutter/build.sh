#!/bin/sh
# Runs ON THE MAC. Discovers how this Flutter project is built, and optionally
# builds it for the simulator and installs it.
#
# This is the flutter framework runner's own file — framework.sh beside it is
# the only thing that should call it. It lived in remote/ until 18 Sep, which is
# where it was before the seam existed (BACKLOG item 87, 5.4).
#
#   build.sh --repo <dir> --detect
#   build.sh --repo <dir> [--app-id <id>] [--flavor <f>] [--target <file>]
#            [--install <udid>] [--release] [--build-only]
#
# Building and installing are two different jobs and this does both. Which one
# it is doing is now said out loud: a successful build prints
#
#   artifact <path>
#
# as a line of its own, whether or not an install follows, and `--build-only`
# stops there. That line is the framework runner's `build` verb (BACKLOG item
# 87, runners/README.md) — installing an artefact is the PLATFORM's job, and
# `xcrun simctl install` sitting at the bottom of a Flutter build script is why
# Flutter-on-Android cannot work today. Nothing about the existing calls
# changes: without --build-only this builds and installs exactly as it did.
#
# Nothing here is specific to one app. Three things cost session B about four
# and a half minutes on 11 Aug 2026, and each of them presents as a different
# problem than it is:
#
#   flutter is on no PATH at all, because the repo pins its SDK with fvm — a
#   bare `flutter` says "command not found", which reads as a broken install
#   CocoaPods lives under a different Ruby — the build says "CocoaPods is
#   installed but broken", which reads as a broken CocoaPods
#   the build is flavoured — a plain `flutter build ios` says 'Target file
#   "lib/main.dart" not found', which reads as a missing file
#
# POSIX sh: /bin/sh on macOS is bash 3.2 in sh mode, and this also has to be
# testable from Linux without a Mac.
set -u

REPO=; DETECT=0; FLAVOR=; TARGET=; APPID=; INSTALL=; MODE=debug; DEVICE=; BUILDONLY=0; LIST=
while [ $# -gt 0 ]; do
  case $1 in
    --repo)    REPO=$2; shift 2 ;;
    --detect)  DETECT=1; shift ;;
    # Report-only modes, so framework.sh's `variants` and `variant-for-appid`
    # ask this file rather than reproducing the rule. Two copies of "what counts
    # as a flavour" is one copy too many: the pair test below is subtle, and a
    # second implementation drifting from it would refuse the right build or
    # accept the wrong one.
    --list-variants)  LIST=variants; shift ;;
    --variant-for)    LIST=forappid; shift ;;
    --build-only) BUILDONLY=1; shift ;;
    --flavor)  FLAVOR=$2; shift 2 ;;
    --target)  TARGET=$2; shift 2 ;;
    --app-id)  APPID=$2; shift 2 ;;
    --install) INSTALL="$INSTALL $2"; shift 2 ;;
    --device)  DEVICE=$2; shift 2 ;;   # a physical device: profile build + devicectl, via Aqua
    --release) MODE=release; shift ;;
    *) echo "build: unknown argument $1" >&2; exit 2 ;;
  esac
done
[ -n "$REPO" ] || { echo "build: --repo is required" >&2; exit 2; }
[ -d "$REPO" ] || { echo "build: no such directory: $REPO" >&2; exit 2; }

# --- the SDK ----------------------------------------------------------------
# In preference order, most project-specific first: a pinned SDK is the version
# the project expects, and a different one on PATH is a worse answer, not a
# fallback.
_flutter() {
  _v=
  [ -r "$REPO/.fvm/flutter.version" ] && _v=$(cat "$REPO/.fvm/flutter.version")
  for c in \
    "$REPO/.fvm/flutter/bin/flutter" \
    "$REPO/.fvm/flutter_sdk/bin/flutter" \
    "${_v:+$HOME/fvm/versions/$_v/bin/flutter}" \
    "$HOME/fvm/default/bin/flutter" \
    "$(command -v flutter 2>/dev/null)" \
    "$HOME/development/flutter/bin/flutter" \
    /opt/homebrew/bin/flutter \
    /usr/local/bin/flutter
  do
    [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}

# --- CocoaPods --------------------------------------------------------------
# Only reported when `pod` is missing from the PATH the build will actually
# have, because setting GEM_HOME when it is not needed can break a working
# install just as easily.
_gem_home() {
  command -v pod >/dev/null 2>&1 && return 1
  for g in "$HOME/.gem" "$HOME/.local/share/gem"; do
    [ -x "$g/bin/pod" ] && { echo "$g"; return 0; }
  done
  for p in "$HOME"/.gem/ruby/*/bin/pod; do
    [ -x "$p" ] && { echo "${p%/bin/pod}"; return 0; }
  done
  return 1
}

# --- flavours ---------------------------------------------------------------
# A flavour is only real if BOTH halves exist: an Xcode scheme of that name for
# `--flavor` to select, and a `lib/main_<flavour>.dart` for `-t` to point at.
# Requiring both is what discards `lib/main_env.tpl.dart` and the analytics
# extension's own scheme without needing to know about either.
_flavours() {
  for s in "$REPO"/ios/*.xcodeproj/xcshareddata/xcschemes/*.xcscheme; do
    [ -r "$s" ] || continue
    f=$(basename "$s" .xcscheme)
    case $f in Runner|*\ *) continue ;; esac
    [ -r "$REPO/lib/main_$f.dart" ] && echo "$f"
  done
}

# The bundle id is the evidence. Xcode names a build configuration
# <Debug|Release|Profile>-<flavour> and each carries its own
# PRODUCT_BUNDLE_IDENTIFIER, so the app being driven can be traced back to the
# flavour that produces it rather than guessed at from a name that happens to
# match. Confirmed against a seven-flavour project on 13 Aug 2026.
_flavour_for_appid() {
  [ -n "$APPID" ] || return 1
  for p in "$REPO"/ios/*.xcodeproj/project.pbxproj; do
    [ -r "$p" ] || continue
    awk -v want="$APPID" '
      /PRODUCT_BUNDLE_IDENTIFIER = /  { b=$3; sub(/;$/,"",b) }
      /^[ \t]*name = /                { n=$3; gsub(/[";]/,"",n)
                                        if (b == want && n ~ /-/) print n
                                        b="" }
    ' "$p"
  done | sed 's/^[^-]*-//' | sort -u
}

_built_app() {
  for a in "$REPO"/build/ios/iphonesimulator/*.app; do
    [ -d "$a" ] && { echo "$a"; return 0; }
  done
  return 1
}

# Is there a local provisioning profile that covers this bundle id? Search both
# dirs — Xcode 16 moved them and the old one still has files, so it looks like a
# complete answer and is not (physical-device.md §1). Match the profile's
# application-identifier (TEAMID.bundle.id, or a TEAMID.* wildcard) against the
# app. This never reaches the Apple account; a missing profile is refused with
# instructions rather than created (item 45).
_has_profile() {
  _want=$1
  for d in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" \
           "$HOME/Library/MobileDevice/Provisioning Profiles"; do
    [ -d "$d" ] || continue
    for p in "$d"/*.mobileprovision "$d"/*.provisionprofile; do
      [ -r "$p" ] || continue
      _ai=$(security cms -D -i "$p" 2>/dev/null \
        | grep -A1 application-identifier | grep '<string>' \
        | sed -E 's/.*<string>(.*)<\/string>.*/\1/' | head -1)
      [ -n "$_ai" ] || continue
      _bid=${_ai#*.}                       # drop the team-id prefix
      [ "$_bid" = "*" ] && return 0        # a pure wildcard covers anything
      # shellcheck disable=SC2254
      case "$_want" in $_bid) return 0 ;; esac   # exact, or a com.x.* glob
    done
  done
  return 1
}

# --- report-only modes, before anything that needs an SDK --------------------
# These read the repo and print. No flutter, no cocoapods, no build.
case "$LIST" in
  variants) _flavours; exit 0 ;;
  forappid) _flavour_for_appid; exit 0 ;;
esac

# --- report -----------------------------------------------------------------
FL=$(_flutter) || { echo "build: no Flutter SDK found." >&2
  echo "  looked for a pinned SDK first ($REPO/.fvm/flutter), then PATH, then the" >&2
  echo "  usual install locations. A repo that pins with fvm needs 'fvm install'" >&2
  echo "  on the Mac before anything here can build it." >&2; exit 1; }
echo "flutter    $FL"
echo "           $("$FL" --version 2>/dev/null | head -1)"

GEM=$(_gem_home) && echo "cocoapods  not on PATH; using GEM_HOME=$GEM" \
                 || echo "cocoapods  $(command -v pod 2>/dev/null || echo 'not found, and no gem dir either')"

CANDIDATES=$(_flavours)
if [ -n "$FLAVOR" ]; then
  echo "flavour    $FLAVOR — given, not worked out"
  echo "$CANDIDATES" | grep -qx "$FLAVOR" || \
    echo "           warning: no scheme and entrypoint pair of that name in this repo" >&2
elif [ -z "$FLAVOR" ]; then
  if [ -r "$REPO/lib/main.dart" ] && [ -z "$CANDIDATES" ]; then
    echo "flavour    none — lib/main.dart, no flavoured schemes"
  else
    MATCH=$(_flavour_for_appid)
    NM=$(echo "$MATCH" | grep -c .)
    if [ -n "$MATCH" ] && [ "$NM" -eq 1 ]; then
      FLAVOR=$MATCH
      echo "flavour    $FLAVOR — the only one whose bundle id is $APPID"
    else
      echo "flavour    NOT DECIDED. Candidates, each with a scheme and an entrypoint:" >&2
      for f in $CANDIDATES; do echo "             $f  (-t lib/main_$f.dart)" >&2; done
      [ -n "$MATCH" ] && { echo "           $NM of them build $APPID:" >&2
                           for f in $MATCH; do echo "             $f" >&2; done; }
      echo "           pass --flavor, or set BUILD_FLAVOR in .maestro-mac.conf." >&2
      echo "           Building the wrong one installs a different bundle id and" >&2
      echo "           leaves the app under test untouched, which is silent." >&2
      [ "$DETECT" = 1 ] || exit 1
    fi
  fi
fi
[ -n "$FLAVOR" ] && [ -z "$TARGET" ] && TARGET="lib/main_$FLAVOR.dart"
[ -n "$TARGET" ] && echo "target     $TARGET"
APP=$(_built_app) && echo "last build $APP ($(date -r "$APP" '+%Y-%m-%d %H:%M' 2>/dev/null))"

[ "$DETECT" = 1 ] && exit 0

[ -z "$TARGET" ] || [ -r "$REPO/$TARGET" ] || {
  echo "build: $TARGET does not exist in $REPO" >&2; exit 1; }

# --- build for a physical device --------------------------------------------
# Two things the simulator path does not face (physical-device.md §1, §2):
#   1. codesign fails in an SSH (Background) session — flutter's own signing
#      included — so the build has to run in the GUI (Aqua) session. Apple Events
#      reach the GUI from SSH, so hand Terminal a script and poll its log.
#   2. A debug Flutter build cannot launch standalone on the device and a
#      debugger suppresses suspension, so this builds PROFILE mode and installs
#      with devicectl, not simctl.
if [ -n "$DEVICE" ]; then
  # Never reach for the Apple account: a profile for the app must already be
  # local. If not, say how to get one rather than creating records with
  # -allowProvisioningUpdates (item 45).
  if [ -n "$APPID" ] && ! _has_profile "$APPID"; then
    echo "build: no local provisioning profile covers $APPID." >&2
    echo "  searched ~/Library/Developer/Xcode/UserData/Provisioning Profiles and" >&2
    echo "  ~/Library/MobileDevice/Provisioning Profiles. Open the project in Xcode" >&2
    echo "  once to create or download one, or install the .mobileprovision by hand." >&2
    echo "  This deliberately never touches the Apple account." >&2
    exit 1
  fi

  work=$(mktemp -d "${TMPDIR:-/tmp}/mmdevbuild.XXXXXX") || exit 1
  log=$work/build.log; bs=$work/build.sh
  {
    echo "#!/bin/sh"
    echo "cd '$REPO' || exit 1"
    [ -n "${GEM:-}" ] && echo "export GEM_HOME='$GEM' PATH='$GEM/bin':\$PATH"
    printf "'%s' build ios --profile" "$FL"
    [ -n "$FLAVOR" ] && printf " --flavor '%s'" "$FLAVOR"
    [ -n "$TARGET" ] && printf " -t '%s'" "$TARGET"
    echo
    echo 'rc=$?'
    echo 'if [ $rc -eq 0 ]; then'
    # The exact path flutter build ios writes to, whatever the flavour. NOT a
    # glob: the tree also holds stale Debug-*/Profile-*-iphoneos dirs from earlier
    # builds, and a wildcard + head picked one of those (a debug .dev app) over
    # the fresh output — caught live 11 Sep.
    echo "  app='$REPO/build/ios/iphoneos/Runner.app'"
    echo '  if [ -d "$app" ]; then'
    # Announced before the install, so --build-only and the full run report the
    # artefact the same way and this side never has to guess the path back.
    echo '    echo "MMARTIFACT $app"'
    if [ "$BUILDONLY" = 0 ]; then
      echo "    xcrun devicectl device install app --device '$DEVICE' \"\$app\"; rc=\$?"
    fi
    echo '  else echo "flutter reported success but $app is missing" >&2; rc=1; fi'
    echo 'fi'
    echo 'echo "MMDONE rc=$rc"'
  } > "$bs"
  : > "$log"

  # `do script` runs the text in a Terminal window (Aqua) and returns at once;
  # the redirect and the MMDONE marker are how this side waits for it.
  osascript -e "tell application \"Terminal\" to do script \"sh '$bs' > '$log' 2>&1\"" >/dev/null 2>&1 || {
    echo "build: could not start the GUI-session build (osascript/Terminal)." >&2
    echo "  Terminal Automation permission may be needed once, from the Mac's screen." >&2
    exit 1; }

  if [ "$BUILDONLY" = 1 ]; then
    echo "building $APPID for device $DEVICE in the GUI session (profile mode), install left to the caller"
  else
    echo "building $APPID for device $DEVICE in the GUI session (profile mode)"
  fi
  waited=0; limit=${DEVICE_BUILD_TIMEOUT:-1200}
  while [ "$waited" -lt "$limit" ]; do
    grep -q '^MMDONE rc=' "$log" 2>/dev/null && break
    sleep 3; waited=$((waited + 3))
  done
  echo "----- build log -----"; cat "$log"; echo "---------------------"
  drc=$(sed -n 's/^MMDONE rc=\([0-9][0-9]*\).*/\1/p' "$log" | tail -1)
  [ -n "$drc" ] || { echo "build: the GUI-session build did not finish within ${limit}s" >&2; exit 1; }
  [ "$drc" = 0 ] || { echo "build: device build/install failed (rc=$drc)" >&2; exit "$drc"; }

  DART=$(sed -n 's/^MMARTIFACT //p' "$log" | tail -1)
  [ -n "$DART" ] && echo "artifact   $DART"

  # --build-only stops here: there is no install to confirm, and claiming one
  # would be worse than saying nothing. The bundle-id check below is a statement
  # about what devicectl put on the phone, not about what was built.
  [ "$BUILDONLY" = 1 ] && exit 0

  # Same standard as the simulator path, but check the id that was actually
  # installed, not just that APPID is present somewhere — a grep of the installed
  # list passes even when this build put a DIFFERENT bundle on the device (a
  # prior install of APPID is still there). devicectl prints the installed
  # bundle id; compare it. This is what would have caught the wrong-.app bug.
  if [ -n "$APPID" ]; then
    got=$(sed -n 's/.*bundleID: *\([A-Za-z0-9._-][A-Za-z0-9._-]*\).*/\1/p' "$log" | tail -1)
    if [ "$got" = "$APPID" ]; then
      echo "installed  $DEVICE ($APPID)"
    else
      echo "install put '${got:-nothing}' on $DEVICE, not $APPID — the wrong build was installed" >&2
      exit 1
    fi
  else
    echo "installed  $DEVICE"
  fi
  exit 0
fi

# --- build for a simulator --------------------------------------------------
cd "$REPO" || exit 1
[ -n "${GEM:-}" ] && { GEM_HOME=$GEM; PATH=$GEM/bin:$PATH; export GEM_HOME PATH; }

# Xcode 27's lipo -verify_arch fails when given multiple architectures at once,
# even when the binary contains all of them. Flutter's debug_unpack_ios passes
# kIosArchs (from $ARCHS) to lipo -verify_arch in one call, so a simulator
# build requesting "arm64 x86_64" breaks. Restricting to arm64 sidesteps it —
# x86_64 simulator is only needed on Intel Macs.
if [ "$(uname -m)" = arm64 ]; then
  FLUTTER_XCODE_ARCHS=arm64; export FLUTTER_XCODE_ARCHS
fi

set -- build ios --simulator "--$MODE"
[ -n "$FLAVOR" ] && set -- "$@" --flavor "$FLAVOR"
[ -n "$TARGET" ] && set -- "$@" -t "$TARGET"
echo
echo "== $FL $*"
"$FL" "$@" || exit 1

APP=$(_built_app) || { echo "build: nothing under build/ios/iphonesimulator" >&2; exit 1; }
echo "built      $APP"
echo "artifact   $APP"

# Everything above this line is the framework's work; everything below it is the
# platform's, and `_install_sim` is where the seam runs. runners/ios/platform.sh
# `install` is the same five lines against the same two commands — it is written
# out there rather than called from here because nothing is wired yet (BACKLOG
# item 87, runners/README.md call site 3).
[ "$BUILDONLY" = 1 ] && exit 0

# A failed install must not pass as success. The old loop ended each iteration on
# an `|| echo …`, so the echo was the last command and a build that installed
# nothing still exited 0 — exactly the STALE-immediately-after-a-build case (item
# 40). Track failures and exit non-zero, and confirm the bundle is actually
# resident afterwards, because "install returned 0" and "the app is there" are not
# the same claim.
_install_sim() {  # _install_sim <udid> <app> [app-id]
  if ! xcrun simctl install "$1" "$2"; then
    echo "install failed: $1" >&2; return 1
  fi
  if [ -n "${3:-}" ] && ! xcrun simctl get_app_container "$1" "$3" >/dev/null 2>&1; then
    echo "install reported success but $3 is not on $1 afterwards" >&2; return 1
  fi
  echo "installed  $1"
}

rc=0
for u in $INSTALL; do
  _install_sim "$u" "$APP" "$APPID" || rc=1
done
exit $rc
