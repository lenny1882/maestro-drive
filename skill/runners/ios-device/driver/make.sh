#!/bin/bash
# Build the phone driver from source and sign it, in one step. Runs ON THE MAC,
# over ssh: bin/device.sh driver calls it (BACKLOG item 163).
#
#   make.sh [maestro-version] [udid]
#
# build.sh does the build, which needs no keychain, so it runs here. sign.sh
# cannot: every codesign over ssh fails with errSecInternalComponent, because
# the login keychain is locked in an ssh session. So the signing is handed to
# the Mac's GUI Terminal with `osascript … do script`, the way
# runners/flutter/build.sh hands over a device app build, and this side waits on
# the log for a marker. No password is asked for: the GUI session's keychain is
# already unlocked.
#
# The identity and the profile are found, not asked for (pick.py beside this
# file): an identity from the login keychain, named explicitly because
# find-identity without it has omitted one that was there (physical-device.md
# §1), and a development profile from either profile folder whose app id covers
# both driver bundle ids and whose certificate is that identity. With a udid,
# the profile must list that phone too. When either is missing this refuses and
# says which, and builds nothing.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
VER=${1:-$(ls "$HOME/.maestro/lib" 2>/dev/null | sed -n 's/^maestro-cli-\(.*\)\.jar$/\1/p' | head -1)}
UDID=${2:-}
WORK=${DRIVER_WORK:-$HOME/maestro-drive-driver}
[ -n "$VER" ] || { echo "make: no Maestro version given and none found in ~/.maestro/lib" >&2; exit 2; }
OUT="$WORK/build-$VER"
mkdir -p "$WORK"
T=$(mktemp -d "${TMPDIR:-/tmp}/mddrv.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT

# The lookup first, so a Mac that cannot sign is told so before 30 s of build.
# The driver's two bundle ids are fixed by Maestro's project; they are read back
# from the build below and checked against what was picked.
BIDS="dev.mobile.maestro-driver-ios dev.mobile.maestro-driver-iosUITests.xctrunner"
_pick() {
  security find-identity -v -p codesigning "$HOME/Library/Keychains/login.keychain-db" > "$T/ids" 2>/dev/null
  set --
  n=0
  for d in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" \
           "$HOME/Library/MobileDevice/Provisioning Profiles"; do
    [ -d "$d" ] || continue
    for p in "$d"/*.mobileprovision; do
      [ -r "$p" ] || continue
      n=$((n + 1))
      security cms -D -i "$p" -o "$T/p$n.plist" >/dev/null 2>&1 || continue
      set -- "$@" "$p=$T/p$n.plist"
    done
  done
  args=()
  for b in $BIDS; do args+=(--bundle-id "$b"); done
  [ -n "$UDID" ] && args+=(--udid "$UDID")
  python3 "$HERE/pick.py" --identities "$T/ids" "${args[@]}" "$@"
}
PICK=$(_pick) || exit 1
IFS=$'\t' read -r SHA PROF PNAME INAME <<< "$PICK"
echo "identity: $INAME ($SHA)"
echo "profile:  $PNAME ($PROF)"

sh "$HERE/build.sh" "$VER" "$WORK" > "$T/build.out" 2>&1 ||
  { cat "$T/build.out" >&2; exit 1; }
grep '^built' "$T/build.out"

for APP in maestro-driver-ios.app maestro-driver-iosUITests-Runner.app; do
  b=$(plutil -extract CFBundleIdentifier raw "$OUT/Build/Products/Debug-iphoneos/$APP/Info.plist" 2>/dev/null)
  case " $BIDS " in *" $b "*) ;; *)
    echo "make: $APP has bundle id '${b:-none}', not one of $BIDS — Maestro changed it; update make.sh" >&2
    exit 1 ;;
  esac
done

# The GUI-session signing. The script and its log live in $WORK, not $T: the
# Terminal window may still be writing after this side gives up.
LOG="$WORK/sign-$VER.log"; SS="$WORK/sign-$VER.sh"
{
  echo "#!/bin/sh"
  printf "sh '%s' '%s' '%s' '%s'\n" "$HERE/sign.sh" "$SHA" "$PROF" "$OUT"
  echo 'echo "MMDONE rc=$?"'
} > "$SS"
: > "$LOG"
osascript -e "tell application \"Terminal\" to do script \"sh '$SS' > '$LOG' 2>&1; exit\"" >/dev/null 2>&1 || {
  echo "make: could not start the signing in the Mac's GUI Terminal (osascript)." >&2
  echo "  Terminal's Automation permission may be needed once, from the Mac's screen." >&2
  echo "  Or run it there by hand:  sh '$SS'" >&2
  exit 1; }
echo "signing in the Mac's GUI Terminal; log $LOG"
waited=0; limit=${SIGN_TIMEOUT:-300}
while [ "$waited" -lt "$limit" ]; do
  grep -q '^MMDONE rc=' "$LOG" 2>/dev/null && break
  sleep 2; waited=$((waited + 2))
done
rc=$(sed -n 's/^MMDONE rc=\([0-9][0-9]*\).*/\1/p' "$LOG" | tail -1)
[ -n "$rc" ] || { echo "make: the signing did not finish within ${limit}s; $LOG so far:" >&2; cat "$LOG" >&2; exit 1; }
[ "$rc" = 0 ] || { echo "make: signing failed (rc=$rc); $LOG:" >&2; cat "$LOG" >&2; exit "$rc"; }

# Checked again from here, the way deviceup.sh will check it before using it.
codesign --verify --deep --strict "$OUT/Build/Products/Debug-iphoneos/maestro-driver-iosUITests-Runner.app" 2>/dev/null ||
  { echo "make: the Terminal reported success but the runner does not verify" >&2; exit 1; }
echo "ready: $(ls "$OUT"/Build/Products/*.xctestrun | head -1)"
[ "$WORK" = "$HOME/maestro-drive-driver" ] &&
  echo "deviceup.sh uses it from the next bin/device.sh up" ||
  echo "deviceup.sh looks only in ~/maestro-drive-driver; this one runs with DRIVER_XCTESTRUN set to it"
