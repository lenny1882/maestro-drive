#!/bin/bash
# Read the app's real HTTP traffic out of the Dart VM Service.
#
#   ./net.sh              # list every request: id, method, status, uri
#   ./net.sh <id>         # full headers and request/response bodies
#
# In a debug build this is the source of truth about app state. Reach for it
# BEFORE scraping the UI — it answers "what did the server actually return" in
# one call, where the UI answers it in ten and can still be wrong.
#
# Fast path: if ./publish.sh has a relay running on the Mac, this reads it
# directly through the sandbox proxy — 0.050s. Otherwise it falls back to an
# SSH round trip — 0.368s, plus VM service rediscovery. Run ./publish.sh once
# per app start; the relay survives our calls, so it stays fast.
#
# An empty list is ambiguous — it means either "the app made no calls" or
# "dart:io profiling is off", which is the default and which looks identical.
# So when the list comes back empty this checks the flag and says which it was,
# rather than leaving the reader to conclude the app is quiet.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
ARG="${1:-}"
# Per-device state, matching publish.sh, so concurrent reviews do not read each
# other's relay (item 24). Falls back to the shared name for a single-device
# session, which is unchanged.
_dsuffix() { local dv=${DEV:-}; [ -n "$dv" ] || dv=$(_dev 2>/dev/null) || dv=; printf '%s' "$dv"; }
_sfx=$(_dsuffix)
STATE="$LDIR/published${_sfx:+-$_sfx}.state"
HERE="$(cd "$(dirname "$0")/../remote" && pwd)"

# Nothing captured: say which of the two reasons it was, and fix the one that
# is fixable. Profiling is per-isolate, so a restart silently turns it back off.
_explain_empty() {  # _explain_empty <base> <isolate>
  local r
  r=$(curl -s -x "$grpc_proxy" --max-time 8 "$1/ext.dart.io.httpEnableTimelineLogging?isolateId=$2" 2>/dev/null)
  case "$r" in
    *'"enabled":true'*)
      echo "# no requests recorded, and profiling is on — the app really has made none since it was enabled" >&2 ;;
    *'"enabled":false'*)
      curl -s -x "$grpc_proxy" --max-time 8 \
        "$1/ext.dart.io.httpEnableTimelineLogging?isolateId=$2&enabled=true" >/dev/null 2>&1
      cat >&2 <<'MSG'
# dart:io HTTP profiling was OFF, which is the default — that is why the list is
# empty, not because the app was quiet. It is on now, but nothing before this
# point was recorded. Repeat the action and read again.
MSG
      ;;
    *)
      echo "# no requests recorded, and the profiling flag could not be read — is the isolate still alive? Re-run ./publish.sh" >&2 ;;
  esac
}

if [ -f "$STATE" ] && read -r BASE ISO < "$STATE" \
   && curl -s -x "$grpc_proxy" --max-time 4 "$BASE/getVersion" 2>/dev/null | grep -q '"type"'; then
  if [ -z "$ARG" ]; then
    curl -s -x "$grpc_proxy" "$BASE/ext.dart.io.getHttpProfile?isolateId=$ISO" > "$LDIR/net${_sfx:+-$_sfx}.json"
    out=$(python3 "$HERE/net.py" list "$LDIR/net${_sfx:+-$_sfx}.json")
    if [ -n "$out" ]; then printf '%s\n' "$out"; else _explain_empty "$BASE" "$ISO"; fi
  else
    curl -s -x "$grpc_proxy" "$BASE/ext.dart.io.getHttpProfileRequest?isolateId=$ISO&id=$ARG" > "$LDIR/net1${_sfx:+-$_sfx}.json"
    python3 "$HERE/net.py" one "$LDIR/net1${_sfx:+-$_sfx}.json"
  fi
  exit
fi

echo "# no relay published - falling back to SSH (run ./publish.sh for ~7x)" >&2
d=$(_dev) || exit 1
_ssh "set -e
V=\$(bash '$RDIR/vmservice.sh' '$d' '$RDIR/vmservice-$d' | tail -1)
B=\${V%% *}; I=\${V##* }
if [ -z '$ARG' ]; then
  curl -s \"\$B/ext.dart.io.getHttpProfile?isolateId=\$I\" > '$RDIR/net-$d.json'
  python3 '$RDIR/net.py' list '$RDIR/net-$d.json'
else
  curl -s \"\$B/ext.dart.io.getHttpProfileRequest?isolateId=\$I&id=$ARG\" > '$RDIR/net1-$d.json'
  python3 '$RDIR/net.py' one '$RDIR/net1-$d.json'
fi"
