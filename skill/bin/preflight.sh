#!/bin/bash
# What the MCP server cannot tell you, in one round trip.
#
# Simulators and their drivers are NOT listed here — `bin/drivers.sh` does that,
# and it reports which device is on which port. This covers the rest: repo
# state, whether the app is built and installed, whether a debug session is
# live, and where the VM service is.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
d=$(_dev) || exit 1

# ../remote/appcheck.sh is sent as part of the command rather than scp'd, so
# this is still one round trip. base64 because it would otherwise be expanded
# by the local shell along with everything else in the string below — and
# without -w0, which macOS's base64 does not have.
AC=$(base64 < "$(dirname "$0")/../remote/appcheck.sh" | tr -d '\n')
GS=$(base64 < "$(dirname "$0")/../remote/gitstate.sh" | tr -d '\n')

# "Is a dev session live, and what is lost when it is not" is the framework's
# question, not this script's: React Native looks for Metro, a plain Xcode app
# has no such thing at all and loses nothing by it. Same for which tracked paths
# a build regenerates — a React Native checkout rewrites yarn.lock, a Gradle one
# rewrites neither of the files gitstate.sh knows about.
#
# The residue list now comes from the framework runner, on the Mac, inside the
# same SSH call (BACKLOG item 87, runners/README.md call site 1). The dev-session
# probe is call site 2 and is still defaulted below.
FW=$("$(dirname "$0")/runner.sh" rpath framework) || exit 1

: "${DEVSESSION_HEADING:=flutter run active?}"
: "${DEVSESSION_PGREP:=flutter_tools}"
: "${DEVSESSION_NONE:=none — nothing started the app with flutter run, so there is no VM
       service: bin/net.sh and bin/publish.sh will come back empty.
       Driving still works. Ask the user before starting one.}"

_ssh "
# The framework's residue list, if it has one. Only an exit 0 overrides
# gitstate.sh's own default: a module that exits 2 has no opinion, and taking
# its empty output as 'nothing is residue' would quietly reclassify every lock
# file as somebody's work — which is the flat list this check exists to undo.
if _RG=\$(RDIR='$RDIR' sh '$FW' residue 2>/dev/null); then
  RESIDUE_GLOBS=\$_RG; export RESIDUE_GLOBS
fi
echo '== branch / working tree =='
printf '%s' '$GS' | base64 -d > '$RDIR/gitstate.sh' 2>/dev/null
# Run with sh, do NOT source: this shell is zsh, which neither word-splits an
# unquoted expansion nor globs an unquoted case pattern, and gitstate.sh needs
# both to tell a lock file from somebody's work. gitstate.sh says so at length.
sh '$RDIR/gitstate.sh' --run '$REPO'
echo; echo '== app installed on $d? =='
C=\$(xcrun simctl get_app_container '$d' '$APP_ID' 2>/dev/null)
if [ -n \"\$C\" ]; then echo \"\$C\"
else xcrun simctl get_app_container '$d' '$APP_ID' 2>&1 | tail -1
fi
echo; echo '== is that the code under test? =='
printf '%s' '$AC' | base64 -d > '$RDIR/appcheck.sh' 2>/dev/null
. '$RDIR/appcheck.sh' && appcheck \"\$C\" '$REPO' '${BUILD_MARKER:-}'
echo; echo '== supported orientations =='
if [ -n \"\$C\" ]; then
  _plist=\"\$C/Info.plist\"
  if [ -f \"\$_plist\" ]; then
    _ipad=\$(defaults read \"\$_plist\" 'UISupportedInterfaceOrientations~ipad' 2>/dev/null | grep -v '[()]' | sed 's/^[[:space:]]*//' | tr -d '\",' | paste -sd ' ' -)
    _iphone=\$(defaults read \"\$_plist\" 'UISupportedInterfaceOrientations' 2>/dev/null | grep -v '[()]' | sed 's/^[[:space:]]*//' | tr -d '\",' | paste -sd ' ' -)
    [ -n \"\$_ipad\" ] && echo \"iPad:   \$_ipad\" || echo 'iPad:   not specified'
    [ -n \"\$_iphone\" ] && echo \"iPhone: \$_iphone\" || echo 'iPhone: not specified'
  else
    echo 'Info.plist not found in app container'
  fi
else
  echo 'app not installed — cannot read'
fi
echo; echo '== $DEVSESSION_HEADING =='
# pgrep's status is lost through the pipe, so test the output rather than \$?.
f=\$(pgrep -fl '$DEVSESSION_PGREP' 2>/dev/null | head -2)
if [ -n \"\$f\" ]; then printf '%s\\n' \"\$f\"
else cat <<'DEVSESSION_NONE_EOF'
$DEVSESSION_NONE
DEVSESSION_NONE_EOF
fi
echo; echo '== vm service =='
bash '$RDIR/vmservice.sh' '$d' '$RDIR/vmservice' 2>&1 | tail -1
"
# The project's executable prior work, counted locally — journeys and flows live
# here, not on the Mac. Put in front of the one call everybody makes so a covered
# screen is replayed, not rediscovered (item 49).
_md=$(dirname "$JOURNEY_DIR")
_nj=$(ls -1 "$JOURNEY_DIR"/*.journey 2>/dev/null | wc -l | tr -d ' ')
_nf=$(ls -1 "$_md"/flows/*.yaml "$_md"/flows/*.yml 2>/dev/null | wc -l | tr -d ' ')
if [ -f "$_md/COVERAGE.md" ]; then _cov='COVERAGE.md present'; else _cov='no COVERAGE.md'; fi
echo; echo '== journeys / flows =='
echo "journeys $_nj files · flows $_nf files · $_cov"
if [ "$_nj" != 0 ] || [ "$_nf" != 0 ]; then
  echo '  a screen covered here is replayed, not rediscovered — the journey file is'
  echo "  the unit of work, not a driver call. ls $JOURNEY_DIR"
fi

# The app notes are read at the start of every session, so their SIZE is a fact
# about every session, not about the file. SKILL.md says they must stay short and
# nothing measured that until 17 Sep 2026, by which point one project's had
# reached 1,302 lines / 169 KB — loaded cold into every session that most needed
# it. Printed here rather than enforced: only a person can say which entries have
# been superseded.
_notes=${APP_NOTES:-}
if [ -n "$_notes" ] && [ -r "$_notes" ]; then
  _nl=$(wc -l < "$_notes" | tr -d ' ')
  _nk=$(( $(wc -c < "$_notes" | tr -d ' ') / 1024 ))
  echo; echo '== app notes =='
  printf 'app-notes.md  %s lines · %s KB\n' "$_nl" "$_nk"
  if [ "$_nl" -gt "${NOTES_WARN_LINES:-400}" ]; then
    echo "  past ${NOTES_WARN_LINES:-400} lines, and this is read at the start of every session."
    echo "  Move superseded and corrected-in-place entries out:  bin/notes.sh archive"
  fi
fi

# Never blocks: a stale docs mirror is worth saying out loud, not stopping for.
echo; "$(dirname "$0")/docs-check.sh"
