#!/bin/bash
# Find the Dart VM Service base URI and the main isolate id, and cache them.
# Runs ON THE MAC.  Usage: vmservice.sh <device-udid> <cache-file>
#
# Never hardcode these. The port and the isolate id both change on every
# `flutter run`, app install or relaunch — the original session baked a stale
# port into its network script and lost a full cycle rediscovering it.
DEV="$1"; CACHE="${2:-/tmp/hbtest/vmservice}"

valid() {
  [ -n "$1" ] && [ -n "$2" ] || return 1
  curl -s --max-time 4 "$1/getVersion" 2>/dev/null | grep -q '"type"' || return 1
  curl -s --max-time 4 "$1/getIsolate?isolateId=$2" 2>/dev/null | grep -q '"type"'
}

if [ -f "$CACHE" ]; then
  read -r B I < "$CACHE"
  if valid "$B" "$I"; then echo "$B $I"; exit 0; fi
fi

# Rediscover from the simulator's system log.
B=$(xcrun simctl spawn "$DEV" log show --last 5m --style compact 2>/dev/null \
      | grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=+/-]+' | tail -1)
[ -n "$B" ] || { echo "no VM service found - is the app running in debug?" >&2; exit 1; }
B="${B%/}"

I=$(curl -s --max-time 6 "$B/getVM" | python3 -c '
import json,sys
d=json.load(sys.stdin)["result"]
iso=d.get("isolates") or []
print(iso[0]["id"] if iso else "")
' 2>/dev/null)
[ -n "$I" ] || { echo "VM service at $B has no isolates" >&2; exit 1; }

printf '%s %s\n' "$B" "$I" | tee "$CACHE"
