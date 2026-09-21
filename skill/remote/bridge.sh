#!/bin/sh
# The bridge helper. Runs ON THE MACHINE WITH THE DEVICE (BACKLOG item 96).
#
#   sh bridge.sh <directory>
#
# Why this exists. Item 94 made the package drive a device on the machine it
# runs on, and inside a Claude session that machine is on the other side of a
# sandbox: no /dev/kvm, its own PID and network namespaces, writes confined to
# the working directory and $TMPDIR. An x86 emulator cannot start in there, and
# a device booted outside it cannot be seen from inside. What the two sides DO
# share is a real directory — the session scratch — so that is the channel.
#
# What it carries is what `_ssh` carries and nothing more: one shell script in,
# stdin attached, stdout and stderr streamed back, the real exit status. That is
# the whole point of the shape — the 84 call sites, the runner modules and every
# value they use stay exactly as they are, and the transport is a setting.
#
# It is arbitrary shell on this machine, which is the same capability the ssh
# transport has against the Mac, pointed at the machine the sandbox protects.
# So: it is started deliberately rather than running in every session, it
# appends every script it runs to <directory>/log, and it stops when the session
# does. Read the log if you want to know what was run.
#
# The protocol, one file per request so that concurrent calls do not collide:
#
#   control      FIFO. The client writes one line: a request id.
#   <id>.cmd     the script to run              written by the client
#   <id>.in      stdin, possibly empty          written by the client
#   <id>.tmo     seconds, optional              written by the client
#   <id>.out     FIFO, stdout                   made by the client, read by it
#   <id>.err     FIFO, stderr                   made by the client, read by it
#   <id>.rc      the exit status                written here, last
#
# Opening the out and err FIFOs blocks until the client is reading them, which
# is what makes the streaming real rather than a file read at the end. A client
# that dies mid-request leaves this side blocked on that request alone; the
# control loop keeps serving.
set -u

DIR=${1:-}
[ -n "$DIR" ] || { echo "usage: bridge.sh <directory>" >&2; exit 2; }
[ -d "$DIR" ] || { echo "bridge: $DIR does not exist" >&2; exit 2; }

# The directory is the capability: anything that can write in it can run
# anything here. Refuse one that is not ours rather than serve a door somebody
# else propped open.
owner=$(ls -ld "$DIR" | awk '{print $3}')
me=$(id -un)
[ "$owner" = "$me" ] || { echo "bridge: $DIR is owned by $owner, not $me" >&2; exit 2; }

CONTROL="$DIR/control"
LOG="$DIR/log"
[ -p "$CONTROL" ] || { rm -f "$CONTROL"; mkfifo "$CONTROL" || exit 1; }
: > "$LOG" 2>/dev/null || true

_log() {
  printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG" 2>/dev/null || true
}

_serve() {  # _serve <id>
  id=$1
  cmd="$DIR/$id.cmd"; in="$DIR/$id.in"
  out="$DIR/$id.out"; err="$DIR/$id.err"; rc="$DIR/$id.rc"

  if [ ! -f "$cmd" ]; then
    _log "$id  REFUSED: no $id.cmd"
    echo 2 > "$rc.tmp" 2>/dev/null && mv "$rc.tmp" "$rc" 2>/dev/null
    return
  fi

  _log "$id  ---"
  sed 's/^/    /' "$cmd" >> "$LOG" 2>/dev/null || true

  [ -f "$in" ] || : > "$in"
  tmo=$(cat "$DIR/$id.tmo" 2>/dev/null)
  case "$tmo" in ''|*[!0-9]*) tmo=180 ;; esac

  # The FIFOs are the client's to make. If it did not, there is nobody reading
  # and opening them would block for ever.
  if [ ! -p "$out" ] || [ ! -p "$err" ]; then
    _log "$id  REFUSED: $id.out or $id.err is not a fifo"
    echo 2 > "$rc.tmp" 2>/dev/null && mv "$rc.tmp" "$rc" 2>/dev/null
    return
  fi

  timeout "$tmo" sh "$cmd" < "$in" > "$out" 2> "$err"
  status=$?
  echo "$status" > "$rc.tmp" && mv "$rc.tmp" "$rc"
  _log "$id  exit $status"
}

_log "bridge up in $DIR (pid $$)"
printf '%s\n' "$$" > "$DIR/pid"

# A doorbell rather than a stream: each read opens the FIFO, takes one id and
# closes it, so a client that never writes cannot wedge the loop and several
# clients can ring in turn. Requests are served in the background, so a long
# flow does not hold up the screenshot behind it.
while :; do
  id=$(cat "$CONTROL") || break
  [ -n "$id" ] || continue
  case "$id" in
    stop) _log "stop requested"; break ;;
    *[!A-Za-z0-9._-]*) _log "REFUSED id with unexpected characters" ; continue ;;
  esac
  _serve "$id" &
done

_log "bridge down"
rm -f "$DIR/pid"
