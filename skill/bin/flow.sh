#!/bin/bash
#
# For real Maestro flows on a chosen device. The MCP `run` tool is ~2.2s for a
# two-action flow against ~17.6s here, but it can only address the device on
# port 22087, whereas --device here works.
#
# Either way it costs that device its driver. Measured 13 Aug 2026: Maestro
# terminates the runner for the device it was given when the command finishes,
# whether the command worked or not, so a bin/drivers.sh layout loses that one
# entry — and only that one; other devices keep their ports. The next
# bin/driver.sh call for that device says so. For driving, prefer bin/driver.sh.
#
# Run a Maestro flow and read the resulting state in ONE round trip.
#
#   ./flow.sh <<'YAML'          # flow on stdin
#   - tapOn: "SEARCH.*"
#   - inputText: "5012345678900"
#   YAML
#
#   ./flow.sh -f signin.yaml -e STORE="42 - ..." -e PIN=1234
#   ./flow.sh -q <<<'- tapOn: "Back"'      # flow output only, no hierarchy
#   ./flow.sh -s shot1 <<'YAML' ... YAML   # also fetch a screenshot
#
# Batch aggressively. Maestro pays its full startup (JVM ~2.5s, plus iOS driver
# connect — 15-30s all in) on EVERY invocation, whether the flow has one step
# or thirty. One journey per call, not one tap per call.
#
# Assert inside the flow. Maestro reports COMPLETED for a tap that landed on
# nothing, so follow every screen change with assertVisible / assertNotVisible
# / extendedWaitUntil. A wrong assumption then fails inside the batch instead
# of three round trips later.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

FILE=""; QUIET=0; SHOT=""; SETTLE=1; ENVS=()
while getopts "f:qs:d:e:" o; do
  case "$o" in
    f) FILE="$OPTARG" ;;
    q) QUIET=1 ;;
    s) SHOT="$OPTARG" ;;
    d) SETTLE="$OPTARG" ;;
    e) ENVS+=(-e "$OPTARG") ;;
    *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

# Project values from the conf reach a flow as -e, the same way they reach a
# journey through the environment — so a flow can say ${APP_PIN} rather than
# carry the value. Anything given with -e on the command line is appended after
# these, so an explicit one still wins.
_conf_envs=()
while read -r _v; do
  [ -n "$_v" ] && _conf_envs+=(-e "$_v=${!_v}")
done < <(_app_vars)
[ "${#_conf_envs[@]}" -gt 0 ] && ENVS=("${_conf_envs[@]}" ${ENVS[@]+"${ENVS[@]}"})

d=$(_dev) || exit 1

# Flow body: from -f, else from stdin. appId header is prepended for stdin
# flows so ad-hoc snippets stay to the point.
if [ -n "$FILE" ]; then
  BODY=$(cat "$FILE")
else
  BODY="appId: $APP_ID
---
$(cat)"
fi

POST=""
[ "$QUIET" -eq 0 ] && POST="
sleep $SETTLE
echo '--- hierarchy ---'
maestro --device $d hierarchy > '$RDIR/hier.json' 2>/dev/null
python3 '$RDIR/hier.py' '$RDIR/hier.json'"

[ -n "$SHOT" ] && POST="$POST
echo '--- screenshot ---'
xcrun simctl io $d screenshot '$RDIR/$SHOT.png' >/dev/null 2>&1 && echo '$RDIR/$SHOT.png'"

# Body goes over stdin, so quotes and \$ in the YAML survive intact.
printf '%s\n' "$BODY" | _ssh "cat > '$RDIR/flows/_adhoc.yaml'
maestro --device $d test ${ENVS[*]+\"${ENVS[*]}\"} '$RDIR/flows/_adhoc.yaml' 2>&1 \
  | grep -vE '^\s*\$|Maestro Cloud|maestro cloud|Debug tests faster|^[│╭╰]' | tail -15
$POST"

if [ -n "$SHOT" ]; then
  ssh "${SSH_OPTS[@]}" "$MAC_HOST" "base64 < '$RDIR/$SHOT.png'" | base64 -d > "$LDIR/$SHOT.png"
  echo "local: $LDIR/$SHOT.png"
fi
