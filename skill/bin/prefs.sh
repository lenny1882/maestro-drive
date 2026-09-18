#!/bin/bash
# Read the app's persisted preferences off the device.
#
#   ./bin/prefs.sh                  # the framework's own keys
#   ./bin/prefs.sh idle_logout      # keys matching a pattern
#   ./bin/prefs.sh --all            # every key
#   ./bin/prefs.sh --raw            # the store as it sits on disk
#
# The app is backgrounded first. Platforms write their preference stores lazily
# — iOS flushes NSUserDefaults when the app goes to the background, Android
# flushes SharedPreferences when the activity stops — so a key set seconds ago
# is simply not on disk yet and reads as absent. That is the platform module's
# `prefs-flush`.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)
d=$(_dev) || exit 1

# The only call site that needs both modules (BACKLOG item 87, call site 6).
# WHERE the store lives and how to read it is the platform's — a data container
# and a plist on iOS, /data/data and shared_prefs XML on Android. WHICH keys are
# the app's own is the framework's: shared_preferences writes every key as
# flutter.<key>, AsyncStorage does not use the platform store at all.
PL=$("$HERE/runner.sh" rpath platform) || exit 1

raw=false; all=false; filter=
case "${1:-}" in
  --raw) raw=true ;;
  --all) all=true ;;
  "")    ;;
  *)     filter=$1 ;;
esac

# No filter given: ask the framework for its prefix. An empty answer means the
# framework writes the platform's keys unprefixed, and then filtering on nothing
# is right — showing every key beats showing none.
if [ -z "$filter" ] && ! $raw && ! $all; then
  filter=$("$HERE/runner.sh" framework prefs-prefix 2>/dev/null) || filter=
fi

_ssh "
RDIR='$RDIR' sh '$PL' prefs-flush '$d' '$APP_ID' >/dev/null 2>&1
RDIR='$RDIR' sh '$PL' prefs-read $($raw && echo --raw) '$d' '$APP_ID'" \
  | { if [ -n "$filter" ] && ! $raw && ! $all; then grep -i -- "$filter"; else cat; fi; }
