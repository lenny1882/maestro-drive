#!/bin/bash
# Find the Dart VM Service base URI and the main isolate id, and cache them.
# Runs ON THE MAC.  Usage: vmservice.sh <device-udid> <cache-file>
#
# Never hardcode these. The port and the isolate id both change on every
# `flutter run`, app install or relaunch — the original session baked a stale
# port into its network script and lost a full cycle rediscovering it.
DEV="$1"; CACHE="${2:-/tmp/hbtest/vmservice}"

# Where `flutter run` was told to write its log. This skill's own recipe
# redirects to /tmp/flutter-run.log (SKILL.md); the hot-reload skill uses
# /tmp/frun.log. A log FILE keeps the URI however long ago the app started —
# unlike the simulator's system log, which only holds the last few minutes, so
# an app whose build you sat through has already scrolled out of it (item 39).
: "${FLUTTER_RUN_LOG:=/tmp/flutter-run.log}"
: "${FRUN_LOG:=/tmp/frun.log}"
: "${VM_LOG_WINDOW:=5m}"

# A collected isolate does not return an error — it returns
# {"type":"Sentinel","kind":"Collected"}, which contains "type" like any other
# reply. Matching on that alone accepted a dead isolate after every hot restart
# and handed it back as good: net.sh then read an isolate that no longer exists
# and came back empty, which reads as "the app made no calls". Require the
# object to actually be an Isolate.
valid() {
  [ -n "$1" ] && [ -n "$2" ] || return 1
  curl -s --max-time 4 "$1/getVersion" 2>/dev/null | grep -q '"type"' || return 1
  curl -s --max-time 4 "$1/getIsolate?isolateId=$2" 2>/dev/null | grep -q '"type":"Isolate"'
}

if [ -f "$CACHE" ]; then
  read -r B I < "$CACHE"
  if valid "$B" "$I"; then echo "$B $I"; exit 0; fi
fi

# Candidate base URIs, in the order each source records them. The flutter run
# log(s) come first because a file survives however long the build took; the
# simulator system log is the fallback for an app started without a redirected
# log, and only covers the last VM_LOG_WINDOW.
candidates() {
  local f
  for f in "$FLUTTER_RUN_LOG" "$FRUN_LOG"; do
    [ -f "$f" ] && grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=+/-]+' "$f"
  done
  xcrun simctl spawn "$DEV" log show --last "$VM_LOG_WINDOW" --style compact 2>/dev/null \
    | grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=+/-]+'
}

# Dedupe preserving order, then reverse so the most recent is tried first — a
# stale URI from an earlier run is still listed, and only the live one answers
# with an isolate. (awk, because `tac` is Linux-only and `tail -r` macOS-only.)
cands=$(candidates | awk 'NF && !seen[$0]++ {a[++n]=$0} END{for(i=n;i>=1;i--) print a[i]}')

B= ; I=
if [ -n "$cands" ]; then
  while read -r u; do
    [ -n "$u" ] || continue
    u="${u%/}"
    iso=$(curl -s --max-time 6 "$u/getVM" 2>/dev/null | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)["result"]; iso = d.get("isolates") or []
    print(iso[0]["id"] if iso else "")
except Exception:
    print("")' 2>/dev/null)
    if [ -n "$iso" ]; then B="$u"; I="$iso"; break; fi
  done <<EOF
$cands
EOF
fi

if [ -z "$B" ]; then
  # Two different failures the old single message conflated. Only one of them is
  # a statement about the app's build mode.
  if [ -n "$cands" ]; then
    echo "found a Dart VM Service URI but it has no live isolate — the app has stopped or restarted since it was logged; relaunch it under 'flutter run' and retry" >&2
  else
    echo "no Dart VM Service URI in $FLUTTER_RUN_LOG, $FRUN_LOG, or the last $VM_LOG_WINDOW of the simulator log" >&2
    echo "  the app is almost certainly not running under 'flutter run' — a launchApp or a plain install has no VM service at all. This is NOT the same as 'the app is not in debug'." >&2
  fi
  exit 1
fi

printf '%s %s\n' "$B" "$I" | tee "$CACHE"
