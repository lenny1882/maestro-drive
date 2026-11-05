#!/bin/bash
# Says when Maestro or this toolkit has a newer release. SKILL.md runs this each
# time the skill loads (items 128 and 114):
#
#   bin/update-notice.sh <session-id>
#
# It acts on the first load in a session and does nothing on the rest, so a
# session that never calls the skill costs nothing and one that calls it ten
# times costs one SSH round trip. Maestro only ever looks and never installs, and
# nothing else here would say that a fixed version is out.
#
# It tells, it never upgrades: installing Maestro replaces the driver jar under
# any session that is driving.
#
# It ALWAYS exits 0 and is bounded. A failed command in SKILL.md aborts the whole
# skill invocation, so a Mac on another network or a project with no conf must
# not be able to stop the skill loading. Failing to find out says nothing.
#
# The latest versions come from the machine with the device, because the Bash
# sandbox has no route to GitHub from here. The stamp goes under $TMPDIR because
# the sandbox allows writes there and not in ~/.local/state.
#
# Output is a line per update, for Claude to read in the loaded skill. Nothing
# else reaches stdout, because config.sh and lib.sh have things of their own to
# say and those are not for here.

if [ "${1:-}" != --inner ]; then
  id=${1:-${CLAUDE_CODE_SESSION_ID:-}}
  # No session id means no way to stay quiet on the next load, so ask nothing.
  [ -n "$id" ] || exit 0

  stamps=${TMPDIR:-/tmp}/maestro-drive-notices
  mkdir -p "$stamps" 2>/dev/null || exit 0
  [ -e "$stamps/$id" ] && exit 0
  # Before the check, so a Mac that cannot be reached costs one try per session.
  : > "$stamps/$id" 2>/dev/null || exit 0
  find "$stamps" -type f -mtime +7 -delete 2>/dev/null

  bound=
  command -v timeout >/dev/null 2>&1 && bound="timeout ${UPDATE_NOTICE_LIMIT:-12}"
  $bound bash "$0" --inner 2>/dev/null | sed -n 's/^notice|//p'
  exit 0
fi

set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh" || exit 0

# `sort -V` puts 2.9.0 below 2.10.0, which a string comparison gets backwards.
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$2" ]; }

# GitHub's redirect rather than its API: /releases/latest answers with a 302 to
# the tag and spends none of the API's hourly allowance. It skips drafts and
# pre-releases, as the API does. The jar's name rather than `maestro --version`,
# which starts a JVM.
TMO=8 answer=$(_ssh '
  p=$(command -v maestro 2>/dev/null)
  [ -n "$p" ] && ls "$(dirname "$p")/../lib" 2>/dev/null | sed -n "s/^maestro-cli-\(.*\)\.jar$/installed \1/p" | head -1
  for r in mobile-dev-inc/maestro lenny1882/maestro-drive; do
    u=$(curl -sS -m 3 -o /dev/null -w "%{redirect_url}" "https://github.com/$r/releases/latest" 2>/dev/null)
    echo "latest $r ${u##*/}"
  done') || exit 0

have=$(printf '%s\n' "$answer" | sed -n 's/^installed //p')
want=$(printf '%s\n' "$answer" | sed -n 's|^latest mobile-dev-inc/maestro cli-||p')
if [ -n "$have" ] && [ -n "$want" ] && newer "$have" "$want"; then
  echo "notice|maestro: $have installed, $want available."
elif [ -n "$have" ] && [ -z "$want" ]; then
  # A device on this machine has no route to GitHub from inside the sandbox, and
  # silence there reads as up to date (item 138).
  echo "notice|maestro: $have installed. GitHub could not be reached, so whether a newer one is out is unknown."
fi

# The install's record lives with update-check.sh, which compares and words it.
tag=$(printf '%s\n' "$answer" | sed -n 's|^latest lenny1882/maestro-drive ||p')
check=$HOME/.local/share/maestro-drive/update-check.sh
if [ -n "$tag" ] && [ -r "$check" ]; then
  bash "$check" notice-for "$tag" | sed 's/^/notice|/'
fi
exit 0
