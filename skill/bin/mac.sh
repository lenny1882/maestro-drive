#!/bin/bash
# Run an arbitrary command on the Mac with Java and Maestro on PATH.
#
#   ./bin/mac.sh 'git status --short'
#   ./bin/mac.sh --send script.py --store 42
#
# --send copies a local file to $RDIR on the Mac, runs it with the conf's
# APP_* values exported into the environment (so a PIN stays out of the
# command line), streams stdout back, and cleans up. Arguments after the
# filename are passed to the script. The scratch directory is under $RDIR
# (which is under $HOME on the Mac), never /tmp — /tmp is cleaned mid-session
# on this Mac.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

if [ "${1:-}" = "--send" ]; then
  shift
  file=${1:?usage: mac.sh --send <file> [args...]}
  [ -r "$file" ] || { echo "mac.sh: cannot read $file" >&2; exit 1; }
  shift
  base=$(basename "$file")
  rscript="$RDIR/send/$base"

  _ssh "mkdir -p '$RDIR/send'"
  _push "$file" "$rscript" || exit 1

  # Export APP_* values into the remote environment so the script can read
  # them without interpolation on this side.
  exports=""
  while read -r name; do
    [ -n "$name" ] && exports="${exports}export ${name}='${!name}'; "
  done < <(_app_vars 2>/dev/null)

  _ssh "${exports}chmod +x '$rscript' 2>/dev/null; '$rscript' $*; rm -f '$rscript'"
else
  _ssh "$*"
fi
