#!/usr/bin/env bash
# What maestro-drive knows about its own install, and whether a release is newer.
#
# It never fetches, never touches the install directory, and never installs
# anything — upgrading is always an explicit `./update.sh`.
#
# It has no network and writes nothing but the install record, because it runs
# inside the Bash sandbox, which allows neither GitHub nor ~/.local/state. The
# latest version comes from skill/bin/update-notice.sh, which asks the machine with
# the device. A daily check of the GitHub API used to live here, and nothing ever
# called it (BACKLOG items 114 and 128).
#
#   notice-for <version>   one line if <version> is newer than the install, else nothing
#   status                 installed version and repo
#   record-install <version> <repo-dir>    called by install.sh

set -uo pipefail

PROJECT="maestro-drive"

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/$PROJECT"
INSTALLED="$STATE/installed"
REPO_F="$STATE/repo-dir"

read_file() { cat "$1" 2>/dev/null | head -1 | tr -d '[:space:]'; }

# True when $2 is a strictly higher version than $1. sort -V orders 1.9.0
# below 1.10.0, which a string comparison would get backwards.
newer_than() {
  [ -n "$2" ] || return 1
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$2" ]
}

case "${1:-status}" in
  notice-for)
    want=$(printf '%s' "${2:-}" | sed 's/^v//')
    have=$(read_file "$INSTALLED")
    if [ -n "$have" ] && newer_than "$have" "$want"; then
      printf '%s: v%s installed, v%s available. Update: cd %s && ./update.sh\n' \
        "$PROJECT" "$have" "$want" "$(read_file "$REPO_F")"
    fi
    ;;

  status)
    printf '%s\n' "$PROJECT"
    printf '  installed:    %s\n' "$(read_file "$INSTALLED")"
    printf '  repo:         %s\n' "$(read_file "$REPO_F" | grep . || echo '(not recorded)')"
    ;;

  record-install)
    mkdir -p "$STATE"
    printf '%s\n' "${2:?version required}"  > "$INSTALLED"
    printf '%s\n' "${3:?repo dir required}" > "$REPO_F"
    ;;

  *)
    printf 'usage: %s {notice-for <version>|status|record-install <version> <repo-dir>}\n' \
      "$(basename "$0")" >&2
    exit 1
    ;;
esac
exit 0
