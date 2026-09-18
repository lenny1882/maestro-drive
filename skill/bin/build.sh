#!/bin/bash
# Build this project's app on the Mac and install it on a simulator or a
# physical device.
#
#   ./bin/build.sh --detect            # what it found; builds nothing
#   ./bin/build.sh                     # build and install onto $DEV
#   ./bin/build.sh --all               # ...onto every booted simulator
#   ./bin/build.sh --flavor uat        # override the flavour it worked out
#   ./bin/build.sh --no-install        # build only, and name the artefact
#   ./bin/build.sh --install-only <p>  # install an artefact already built
#
# When $DEV is a physical device, set PLATFORM=ios-device: that builds a PROFILE
# build through the GUI (Aqua) session — codesign, flutter's own signing
# included, fails over SSH — and installs with devicectl, gated on a local
# provisioning profile (it never reaches the Apple account). See
# physical-device.md and BACKLOG.md item 45.
#
# NOTHING HERE RUNS UNPROMPTED. A build replaces whatever is on the simulator,
# which may be the very thing under test, and takes about half a minute. Say
# what is missing, say what it costs, and let the user decide — the rule in
# SKILL.md is unchanged by this script existing. `--detect` is the safe half: it
# reads the repo and reports, and is the right thing to run before asking.
#
# --- two calls, not one (BACKLOG item 87) ------------------------------------
# Building and installing are two different jobs answering to two different
# modules: the framework builds, the platform installs. So this makes two SSH
# calls and carries the artefact path back between them, rather than one call
# that does both on the Mac.
#
# That costs one round trip — 0.35s, against a build measured at 21-34s on
# 18 Sep 2026. What it buys is the artefact path on THIS side, which means a
# second install skips the build entirely: --install-only. A no-op rebuild is
# 21-22s measured, not free, so every install of a build already made saves
# that — a simulator booted after the build, a reinstall after `simctl erase`,
# an uninstall to test first launch. One of them pays for sixty builds' worth
# of the round trip.
#
# Everything the build discovers — the SDK, the Ruby environment, the flavour —
# is still worked out from the repo rather than configured, because the point of
# the item this came from (BACKLOG.md 5) is that the recipe was being re-derived
# per project and then written into one project's memory file, where the next
# app cannot see it.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)

[ -n "${REPO:-}" ] || { echo "build: REPO is not set — the checkout on the Mac.
  Add it to .maestro-mac.conf, or bin/init.sh --host <alias> --detect." >&2; exit 2; }

detect=0; install_all=0; no_install=0; skip_build=0; artifact=; bargs=(); targets=()
while [ $# -gt 0 ]; do
  case $1 in
    --detect)       detect=1; shift ;;
    --all)          install_all=1; shift ;;
    --no-install)   no_install=1; shift ;;
    # The whole point of carrying the path back: install a build already made,
    # onto a device booted since, without paying for the build again.
    --install-only) skip_build=1; artifact=$2; shift 2 ;;
    --flavor)       bargs+=(--variant "$2"); shift 2 ;;
    --target)       bargs+=(--target "$2"); shift 2 ;;
    --release)      bargs+=(--mode release); shift ;;
    -h|--help)      sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "build: unknown argument $1" >&2; exit 2 ;;
  esac
done

# The bundle id under test is the evidence for which flavour to build, so it is
# always passed: a project with seven flavours has seven schemes that all build
# cleanly and six of them install a different app.
[ -n "${APP_ID:-}" ] && bargs+=(--app-id "$APP_ID")

# A conf setting is a weaker claim than a command-line one, so it only applies
# when the command line did not say.
[[ " ${bargs[*]} " == *" --variant "* ]] || [ -z "${BUILD_FLAVOR:-}" ] || bargs+=(--variant "$BUILD_FLAVOR")
[[ " ${bargs[*]} " == *" --target "*  ]] || [ -z "${BUILD_TARGET:-}" ] || bargs+=(--target "$BUILD_TARGET")

# Both modules run ON THE MAC, so these are their paths under $RDIR — where
# bin/install.sh put them — not the ones in this checkout.
FW=$("$HERE/runner.sh" rpath framework) || exit 1
PL=$("$HERE/runner.sh" rpath platform)  || exit 1
bargs+=(--platform "${PLATFORM:-ios}")

# --- where it goes ----------------------------------------------------------
# PLATFORM decides how the build runs AND how the install runs. The UUID-shape
# test that used to decide it here is now `platform.sh claim`, and it is a
# consistency check rather than the decision — a physical device driven under
# PLATFORM=ios would otherwise build for the simulator and install nothing,
# silently.
if [ "$detect" = 0 ] && [ "$no_install" = 0 ]; then
  if [ "$install_all" = 1 ]; then
    while IFS=$'\t' read -r u _rest; do
      [ -n "$u" ] && targets+=("$u")
    done < <(_ssh "sh '$PL' devices --booted")
    [ ${#targets[@]} -gt 0 ] || { echo "build: --all, but no booted device on $MAC_HOST" >&2; exit 2; }
  elif [ -n "${DEV:-}" ]; then
    "$HERE/runner.sh" platform claim "$DEV" || {
      echo "build: DEV=$DEV is not a device PLATFORM=${PLATFORM:-ios} recognises.
  A physical iPhone is PLATFORM=ios-device — it needs a profile build in the
  Mac's GUI session and installs with devicectl, not simctl." >&2; exit 2; }
    targets+=("$DEV")
  else
    echo "build: no DEV, so nothing would be installed. Name one with DEV=<udid>,
  pin it in .maestro-mac.conf, or pass --all for every booted simulator.
  --no-install builds without installing." >&2
    exit 2
  fi
fi

_ssh "mkdir -p '$RDIR'" >/dev/null
scp "${SSH_OPTS[@]}" "$HERE/../remote/build.sh" "$MAC_HOST:$RDIR/build.sh" >/dev/null || exit 1

# --- detect: the framework reports, and nothing is built --------------------
if [ "$detect" = 1 ]; then
  _ssh "RDIR='$RDIR' sh '$FW' describe '$REPO' '${APP_ID:-}'"
  exit $?
fi

# --- the framework's half ---------------------------------------------------
# Four timeouts now, not two, because the two halves are nowhere near each other
# in cost and no longer share a call:
#
#   build, simulator  900s   xcodebuild; 21-34s measured, but a cold one is far
#                            longer and the default TMO is nowhere near either
#   build, device    1500s   a profile build in the GUI session, polled from
#                            here, and remote/build.sh caps its own poll at 1200s
#   install, sim      300s   simctl install is seconds
#   install, device   600s   devicectl goes over the usbmux tunnel
#
# The device build keeps a limit of its own rather than sharing the simulator's:
# they are different mechanisms, and one number would be far too long for one of
# them or too short for the other.
if [ "$skip_build" = 0 ]; then
  case "${PLATFORM:-ios}" in
    ios-device) export TMO=${BUILD_TMO:-1500}; bargs+=(--device "${DEV:-}") ;;
    *)          export TMO=${BUILD_TMO:-900} ;;
  esac
  out=$(_ssh "RDIR='$RDIR' sh '$FW' build '$REPO' $(printf '%q ' "${bargs[@]}")") || exit 1
  printf '%s\n' "$out"
  artifact=$(printf '%s\n' "$out" | sed -n 's/^artifact  *//p' | tail -1)
  [ -n "$artifact" ] || { echo "build: the build reported no artifact path, so there is
  nothing to install. That is a bug in the framework runner, not a build failure —
  the build itself returned 0." >&2; exit 1; }
fi

[ ${#targets[@]} -eq 0 ] && exit 0

# --- the platform's half ----------------------------------------------------
# ONE round trip for every device, not one each: the loop runs on the Mac. A
# failed install does not stop the others and the exit status is the OR of them,
# which is the standard remote/build.sh already held — a build that installed
# nothing must not pass as success (item 40).
case "${PLATFORM:-ios}" in
  ios-device) export TMO=${INSTALL_TMO:-600} ;;
  *)          export TMO=${INSTALL_TMO:-300} ;;
esac
_ssh "rc=0
for u in $(printf '%q ' "${targets[@]}"); do
  sh '$PL' install \"\$u\" '$artifact' '${APP_ID:-}' || rc=1
done
exit \$rc"
