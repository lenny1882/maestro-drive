#!/bin/sh
# Platform runner TEMPLATE — copy this directory, rename it, fill it in.
#
# A platform runner answers "where does this app run, and how do I get at it".
# It knows nothing about what built the app; that is framework.sh next door.
# runners/README.md is the contract.
#
# Everything here runs ON THE MAC except `claim`, which is a string test and
# runs wherever it is asked.
#
# POSIX sh, for the same reason as framework.sh.
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift

case "$VERB" in

# --- claim <device-id> -------------------------------------------------------
# Is this device id mine? Shape alone, no round trip — this is asked before
# anything is reachable. A simulator UDID is a canonical UUID; a phone's is not;
# an Android serial is a host:port or a hardware string.
claim)
  _id=${1:?claim <device-id>}
  : "$_id"
  exit 1
  ;;

# --- devices [--booted] ------------------------------------------------------
# One per line, TAB separated: <id> <state> <name>. --booted lists only the
# running ones. State is free text from the platform; the caller matches on it
# only to say what it found.
#
# Booting is what costs the machine, not having booted. Measured 17 Sep 2026:
# seven simulators up sat at load 6; booting one more took load to 122 within
# 36 seconds and it fell back as soon as that boot settled. So `devices` must be
# cheap enough to call freely, and `boot` must serialise.
devices)
  exit 2
  ;;

# --- boot <id> / shutdown <id> -----------------------------------------------
# Boot or shut down, and WAIT for it to settle before returning. Returning early
# is what makes the next caller start a driver during a boot storm, and a driver
# begun then is the one that dies.
boot|shutdown)
  exit 2
  ;;

# --- install <id> <artifact> [app-id] ----------------------------------------
# Install, then confirm the app id is actually resident afterwards, and exit
# non-zero when it is not.
#
# "Install returned 0" and "the app is there" are not the same claim, and a
# build that installed nothing exiting 0 is how a session drives a stale build
# for an hour. Where the install tool reports which id it put on the device,
# compare it: a grep for the wanted id passes even when THIS install put a
# different bundle there and a previous one left the wanted id behind.
install)
  exit 2
  ;;

# --- container <id> <app-id> -------------------------------------------------
# The installed bundle's path on the device or host, printed on stdout. This is
# what remote/appcheck.sh reads to answer "is the app on the device the code
# under test" — it needs the executable's timestamp and the bundle metadata.
container)
  exit 2
  ;;

# --- data-container <id> <app-id> --------------------------------------------
# Where the app's own writable data lives, for prefs-read.
data-container)
  exit 2
  ;;

# --- prefs-read [--raw] <id> <app-id> ----------------------------------------
# The app's persisted preferences on stdout, one `key = value` per line. --raw
# gives the store as it sits on disk instead, for when the readable form has
# mangled something.
prefs-read)
  exit 2
  ;;

# --- prefs-flush <id> <app-id> -----------------------------------------------
# Background the app so its preferences reach disk. Platforms write them lazily,
# so a key set seconds ago is simply not in the store yet and reads as absent.
prefs-flush)
  exit 2
  ;;

# --- orientations <container> ------------------------------------------------
# Which orientations the installed build supports, as the bundle declares them.
# Free text, one line per form factor.
orientations)
  exit 2
  ;;

# --- screenshot <id> <path> --------------------------------------------------
# Write a screenshot ON THE MAC at <path>. The caller base64s it back; do not
# encode here.
screenshot)
  exit 2
  ;;

# --- driver-up <id> <port> ---------------------------------------------------
# Start a Maestro driver for that device, on THAT port, and do not return until
# it answers. Poll rather than sleeping a fixed time: a cold start is 20-30s on
# a simulator and varies.
#
# If one is already serving on that port, leave it alone and say so —
# relaunching costs the whole cold start and drops whatever the caller is
# part-way through.
#
# The port must be the one asked for, not one the tool picks. A device that
# loses its driver and gets a different port next time is how a session sends
# taps to somebody else's device, which is the failure this whole toolkit
# exists to prevent.
driver-up)
  exit 2
  ;;

# --- driver-down <id> --------------------------------------------------------
driver-down)
  exit 2
  ;;

# --- driver-scan -------------------------------------------------------------
# The live map, one per line: <device-id> <port> <pid>. Read from the running
# processes, not from a file this toolkit wrote — the two differ, and the
# difference is worth saying out loud.
driver-scan)
  exit 2
  ;;

# --- last-used ---------------------------------------------------------------
# "<id>|<yyyymmdd>|<human>|<today-yyyymmdd>" for every booted device, one per
# line, in ONE call. `drivers.sh rig reap` needs it to tell a leftover from
# somebody's live work: a device touched today is never reaped, whoever booted
# it. Today's date comes from the device's own host, not from the caller, so a
# clock skew between the two cannot reap a live device.
#
# An empty date field means "cannot tell", and the caller must treat that as
# recent rather than stale.
last-used)
  exit 2
  ;;

# --- capture-cmd <id> --------------------------------------------------------
# The command line the wall should run for a live view of that device, printed
# as one line. The wall spawns it, reads its frames and restarts it when it goes
# quiet; it must stream and must not need a client attached.
capture-cmd)
  exit 2
  ;;

*)
  echo "platform runner: unknown verb '${VERB:-(none)}'" >&2
  echo "  claim devices boot shutdown install container data-container" >&2
  echo "  prefs-read prefs-flush orientations screenshot" >&2
  echo "  driver-up driver-down driver-scan capture-cmd" >&2
  exit 2
  ;;
esac
