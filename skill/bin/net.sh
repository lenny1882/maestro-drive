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
HERE="$(cd "$(dirname "$0")" && pwd)"

# Reading traffic is the framework's job — dart:io profiling for Flutter, a
# proxy for React Native, nothing at all for a plain Xcode app (BACKLOG item 87,
# call site 5). The same verb serves both sides: it curls through $grpc_proxy
# when there is one, direct when there is not.
FW_LOCAL=$("$HERE/runner.sh" path framework) || exit 1
FW_REMOTE=$("$HERE/runner.sh" rpath framework) || exit 1

# Nothing captured: say which of the two reasons it was, and fix the one that
# is fixable. An empty list means either "the app made no calls" or "capture was
# never armed", and those look identical. traffic-arm answers it in one call
# because it reports the state it FOUND as well as the state it left — and
# arming it as a side effect is the right thing, since capture is bound to the
# session and anything that replaces the session silently turns it back off.
_explain_empty() {  # _explain_empty <base> <isolate>
  local was now
  read -r was now <<< "$(sh "$FW_LOCAL" traffic-arm "$1" "$2" 2>/dev/null)"
  case "${was:-unknown}" in
    on)
      echo "# no requests recorded, and capture is on — the app really has made none since it was enabled" >&2 ;;
    off)
      cat >&2 <<'MSG'
# HTTP capture was OFF, which is the default — that is why the list is empty,
# not because the app was quiet. It is on now, but nothing before this point was
# recorded. Repeat the action and read again.
MSG
      [ "${now:-}" = on ] || echo "# (and it could not be turned on — is the session still alive? Re-run ./publish.sh)" >&2 ;;
    *)
      echo "# no requests recorded, and the capture flag could not be read — is the session still alive? Re-run ./publish.sh" >&2 ;;
  esac
}

if [ -f "$STATE" ] && read -r BASE ISO < "$STATE" \
   && curl -s -x "$grpc_proxy" --max-time 4 "$BASE/getVersion" 2>/dev/null | grep -q '"type"'; then
  if [ -z "$ARG" ]; then
    out=$(sh "$FW_LOCAL" traffic-list "$BASE" "$ISO"); rc=$?
    [ "$rc" = 2 ] && exit 2
    if [ -n "$out" ]; then printf '%s\n' "$out"; else _explain_empty "$BASE" "$ISO"; fi
  else
    sh "$FW_LOCAL" traffic-one "$BASE" "$ISO" "$ARG"; rc=$?
    [ "$rc" = 2 ] && exit 2
  fi
  exit
fi

echo "# no relay published - falling back to SSH (run ./publish.sh for ~7x)" >&2
d=$(_dev) || exit 1
# The same three verbs, run on the machine WITH the device, against its own
# loopback. The module curls direct there in both transports and the base URI is
# the only difference between this and the fast path above: ssh does not forward
# $grpc_proxy to the Mac, and locally lib.sh empties it (item 94, 4.2).
_ssh "set -e
V=\$(RDIR='$RDIR' sh '$FW_REMOTE' inspect '$d' '$RDIR/vmservice-$d')
V=\$(printf '%s\\n' \"\$V\" | tail -1)
B=\${V%% *}; I=\${V##* }
if [ -z '$ARG' ]; then
  RDIR='$RDIR' sh '$FW_REMOTE' traffic-list \"\$B\" \"\$I\"
else
  RDIR='$RDIR' sh '$FW_REMOTE' traffic-one \"\$B\" \"\$I\" '$ARG'
fi"
