#!/bin/bash
# Push the Python helpers to the Mac once, so every later call sends only a
# short command instead of re-uploading the script body.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
HERE="$(cd "$(dirname "$0")/../remote" && pwd)"

_ssh "mkdir -p '$RDIR' '$RDIR/flows'"
for f in hier.py net.py relay.py vmservice.sh; do
  ssh "${SSH_OPTS[@]}" "$MAC_HOST" "cat > '$RDIR/$f'" < "$HERE/$f" || exit 1
done
_ssh "chmod +x '$RDIR'/*.py; ls -la '$RDIR'"
