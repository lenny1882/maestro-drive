#!/bin/bash
# Push the Python helpers to the Mac once, so every later call sends only a
# short command instead of re-uploading the script body.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
HERE="$(cd "$(dirname "$0")/../remote" && pwd)"

_ssh "mkdir -p '$RDIR' '$RDIR/flows' '$RHELP' '$RMODS'"
# vmservice.sh and net.py left this list on 18 Sep: both are the flutter
# framework runner's own files now and go with the modules below (item 87, 5.4).
# hier.py and relay.py stay — a Maestro hierarchy and a port forwarder are the
# same whatever built the app.
for f in hier.py relay.py; do
  ssh "${SSH_OPTS[@]}" "$MAC_HOST" "cat > '$RHELP/$f'" < "$HERE/$f" || exit 1
done

# The runner modules go too, keeping their directory layout, so a Mac-side verb
# finds its siblings the same way it would in the checkout (BACKLOG item 87,
# runners/README.md). Nothing calls them yet; they are pushed so that
# `bin/runner.sh detect` can ask every framework to claim $REPO.
RUNNERS=$(cd "$(dirname "$0")/../runners" && pwd)
for d in "$RUNNERS"/*/; do
  n=$(basename "$d")
  _ssh "mkdir -p '$RMODS/$n'" >/dev/null
  # .sh AND .py. A module's helpers are not all shell — runners/flutter carries
  # net.py and runners/ios-device carries iproxy.py, and a module missing one of
  # them fails on the Mac with "No such file or directory" from a path that
  # looks right. Found 18 Sep when the device forwarder would not bind.
  for f in "$d"*.sh "$d"*.py; do
    [ -r "$f" ] || continue
    ssh "${SSH_OPTS[@]}" "$MAC_HOST" "cat > '$RMODS/$n/$(basename "$f")'" < "$f" || exit 1
  done
done

_ssh "chmod +x '$RHELP'/*.py '$RMODS'/*/*.sh 2>/dev/null; ls -la '$RHELP'"
