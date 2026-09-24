#!/bin/bash
# Build Maestro's iOS driver for a phone from source, with the bind-address
# patch beside this file. Runs ON THE MAC. Unsigned: sign.sh does that, from
# Terminal on the Mac, because codesign cannot reach a locked keychain over ssh.
#
#   build.sh [maestro-version] [workdir]
#
# Why from source (BACKLOG item 99, Part 2). The prebuilt driver in
# maestro-ios-driver.jar listens on the phone's 127.0.0.1 only, so the Mac can
# reach it through a usbmux forwarder over USB but not at all over wifi, where
# usbmuxd lists nothing. The patch lets TEST_RUNNER_BIND name another address:
# the phone's CoreDevice tunnel address, from `devicectl device info details`.
# Unset, the driver behaves exactly as before.
#
# The source, not the jar: maestro-cli.jar ships the driver project without its
# MaestroDriverLib target, so it cannot be built (physical-device.md §3). The
# git tag has all of it. The build also drops item 50's face-up crash, which is
# in the older source the prebuilt driver was compiled from.
#
# Xcode 27 refuses the project's deployment target of 14.0, so it is raised to
# 15.0 for the build. Measured 24 Sep 2026: 22 s, Maestro cli-2.8.0, Xcode 27.0.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
VER=${1:-$(ls "$HOME/.maestro/lib" 2>/dev/null | sed -n 's/^maestro-cli-\(.*\)\.jar$/\1/p' | head -1)}
WORK=${2:-$HOME/maestro-drive-driver}
[ -n "$VER" ] || { echo "build: no Maestro version given and none found in ~/.maestro/lib" >&2; exit 2; }
SRC="$WORK/src-$VER"; OUT="$WORK/build-$VER"

if [ ! -d "$SRC" ]; then
  git -c advice.detachedHead=false clone -q --depth 1 --branch "cli-$VER" https://github.com/mobile-dev-inc/Maestro.git "$SRC" ||
    { echo "build: could not clone Maestro tag cli-$VER" >&2; exit 1; }
fi
cd "$SRC" || exit 1
if git apply --check "$HERE/bind-address.patch" 2>/dev/null; then
  git apply "$HERE/bind-address.patch"
elif git apply --reverse --check "$HERE/bind-address.patch" 2>/dev/null; then
  :   # already applied
else
  echo "build: bind-address.patch does not apply to cli-$VER — the server line moved" >&2
  grep -rn 'HTTPServer(address' maestro-ios-xctest-runner --include=*.swift >&2
  exit 1
fi

rm -rf "$OUT"
xcodebuild build-for-testing \
  -project maestro-ios-xctest-runner/maestro-driver-ios.xcodeproj -scheme maestro-driver-ios \
  -destination generic/platform=iOS -derivedDataPath "$OUT" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 \
  > "$WORK/build-$VER.log" 2>&1 ||
  { echo "build: xcodebuild failed; $WORK/build-$VER.log ends:" >&2; grep 'error:' "$WORK/build-$VER.log" | sort -u | head -5 >&2; exit 1; }
XCTR=$(ls "$OUT"/Build/Products/*.xctestrun | head -1)
echo "built, unsigned: $XCTR"
echo "next, from Terminal on this Mac:  $HERE/sign.sh '<identity>' <profile> $OUT"
