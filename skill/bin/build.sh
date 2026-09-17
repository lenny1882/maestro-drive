#!/bin/bash
# Build this project's app on the Mac and install it on a simulator or a
# physical device.
#
#   ./bin/build.sh --detect            # what it found; builds nothing
#   ./bin/build.sh                     # build and install onto $DEV
#   ./bin/build.sh --all               # ...onto every booted simulator
#   ./bin/build.sh --flavor uat        # override the flavour it worked out
#   ./bin/build.sh --no-install        # build only
#
# When $DEV is a physical device (a non-UUID udid), this builds a PROFILE build
# through the GUI (Aqua) session — codesign, flutter's own signing included,
# fails over SSH — and installs with devicectl, gated on a local provisioning
# profile (it never reaches the Apple account). See physical-device.md and
# BACKLOG.md item 45.
#
# NOTHING HERE RUNS UNPROMPTED. A build replaces whatever is on the simulator,
# which may be the very thing under test, and takes about a minute. Say what is
# missing, say what it costs, and let the user decide — the rule in SKILL.md is
# unchanged by this script existing. `--detect` is the safe half: it reads the
# repo and reports, and is the right thing to run before asking.
#
# The work is done by remote/build.sh on the Mac, in one round trip. Everything
# it discovers — the SDK, the Ruby environment, the flavour — is worked out
# from the repo rather than configured, because the point of the item this came
# from (BACKLOG.md 5) is that the recipe was being re-derived per project and
# then written into one project's memory file, where the next app cannot see it.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)

[ -n "${REPO:-}" ] || { echo "build: REPO is not set — the checkout on the Mac.
  Add it to .maestro-mac.conf, or bin/init.sh --host <alias> --detect." >&2; exit 2; }

detect=0; install_all=0; no_install=0; args=()
while [ $# -gt 0 ]; do
  case $1 in
    --detect)     detect=1; args+=(--detect); shift ;;
    --all)        install_all=1; shift ;;
    --no-install) no_install=1; shift ;;
    --flavor|--target) args+=("$1" "$2"); shift 2 ;;
    --release)    args+=(--release); shift ;;
    -h|--help)    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "build: unknown argument $1" >&2; exit 2 ;;
  esac
done

# The bundle id under test is the evidence for which flavour to build, so it is
# always passed: a project with seven flavours has seven schemes that all build
# cleanly and six of them install a different app.
[ -n "${APP_ID:-}" ] && args+=(--app-id "$APP_ID")

# A conf setting is a weaker claim than a command-line one, so it only applies
# when the command line did not say.
[[ " ${args[*]} " == *" --flavor "* ]] || [ -z "${BUILD_FLAVOR:-}" ] || args+=(--flavor "$BUILD_FLAVOR")
[[ " ${args[*]} " == *" --target "* ]] || [ -z "${BUILD_TARGET:-}" ] || args+=(--target "$BUILD_TARGET")

if [ "$detect" = 0 ] && [ "$no_install" = 0 ]; then
  if [ "$install_all" = 1 ]; then
    while read -r u _; do [ -n "$u" ] && args+=(--install "$u"); done < <(
      _ssh 'xcrun simctl list devices booted' |
        sed -nE 's/^ *(.*) \(([0-9A-F-]{36})\) \(Booted\).*/\2 \1/p')
  elif [ -n "${DEV:-}" ]; then
    # A simulator UDID is a canonical UUID (8-4-4-4-12); anything else — the
    # XS Max's 00008020-0011223344556677 — is a physical device, which takes the
    # profile-build-via-Aqua + devicectl path (item 45), not simctl.
    case "$DEV" in
      ????????-????-????-????-????????????) args+=(--install "$DEV") ;;
      *) args+=(--device "$DEV"); DEVICE_BUILD=1 ;;
    esac
  else
    echo "build: no DEV, so nothing would be installed. Name one with DEV=<udid>,
  pin it in .maestro-mac.conf, or pass --all for every booted simulator.
  --no-install builds without installing." >&2
    exit 2
  fi
fi

_ssh "mkdir -p '$RDIR'" >/dev/null
scp "${SSH_OPTS[@]}" "$HERE/../remote/build.sh" "$MAC_HOST:$RDIR/build.sh" >/dev/null || exit 1

# A full build is minutes, not seconds, and the default timeout is nowhere near
# it. Detection is a handful of file reads, so it keeps the ordinary one. A
# device build is a profile build in the GUI session, polled from here, so it
# wants longer still.
if [ "$detect" = 1 ]; then :
elif [ -n "${DEVICE_BUILD:-}" ]; then export TMO=${TMO:-1500}
else export TMO=${TMO:-900}; fi
_ssh "sh '$RDIR/build.sh' --repo '$REPO' $(printf '%q ' "${args[@]}")"
