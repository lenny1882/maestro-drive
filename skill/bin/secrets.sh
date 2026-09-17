#!/bin/bash
# Has a project value escaped into a file that would be committed?
#
#   bin/secrets.sh check [dir]     # default: the project the conf belongs to
#   bin/secrets.sh list            # which values are defined, without printing them
#
# A project value is anything named APP_* in `.maestro-mac.conf` other than the
# reserved APP_ID and APP_NOTES (bin/config.sh explains the convention). The
# conf is the one file kept out of version control, so a login PIN belongs there
# and is referred to as ${APP_PIN} everywhere else. This looks for the literal
# value having been written into a file anyway.
#
# Matching is whole-word (grep -Fw). Without that a short numeric value is a
# substring of half the hashes in a lock file — a five-digit PIN matched a
# sha256 in pubspec.lock on the first real run, which is the kind of noise that
# gets a check ignored. The cost is that a value glued to other characters with
# no separator, `PIN12345`, is not reported. A value written the way a person
# writes it always is.
#
# In a git working tree it searches exactly what git tracks — which is the
# question worth answering, "is this about to be committed" — and falls back to
# every file under the directory when there is no repo. The conf itself is
# always skipped: that is where the values are supposed to be.
#
# Exit status: 0 nothing found, 1 something found, 2 nothing to check.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/config.sh" || exit 1

_values() {  # NAME<TAB>VALUE for each project value
  local n
  while read -r n; do
    [ -n "$n" ] && printf '%s\t%s\n' "$n" "${!n}"
  done < <(_app_vars)
}

case "${1:-check}" in
  list)
    n=0
    while IFS=$'\t' read -r name val; do
      n=$((n + 1))
      printf '  %-16s %s chars\n' "$name" "${#val}"
    done < <(_values)
    [ "$n" -eq 0 ] && echo "  no project values set in ${MAESTRO_MAC_CONF_FOUND:-(no conf found)}"
    echo
    echo "conf: ${MAESTRO_MAC_CONF_FOUND:-(none)}"
    ;;

  check)
    DIR=${2:-$PROJECT_DIR}
    [ -d "$DIR" ] || { echo "secrets.sh: not a directory: $DIR" >&2; exit 2; }

    mapfile -t VARS < <(_app_vars)
    [ "${#VARS[@]}" -gt 0 ] || {
      cat >&2 <<MSG
secrets.sh: no project values are set, so there is nothing to look for.

A project value is any APP_* in the conf except APP_ID and APP_NOTES. To move a
credential out of the committed files and into the conf:

  ${MAESTRO_MAC_CONF_FOUND:-.maestro-mac.conf}:   : "\${APP_PIN:=<the value>}"
  the journey:                    type "^Passcode\$" \${APP_PIN}
MSG
      exit 2; }

    # What git would commit, when there is a git tree to ask.
    if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
      # --cached --others --exclude-standard is "everything `git add -A` would
      # take": tracked files plus untracked ones that are not gitignored. Plain
      # ls-files would miss a brand new file holding the value, which is the
      # most likely way one gets committed in the first place.
      _files() { git -C "$DIR" ls-files -z --cached --others --exclude-standard; }
      _prefix="$DIR/"
      SCOPE="git would commit"
    else
      _files() { ( cd "$DIR" && find . -type f -not -path './.git/*' -print0 ); }
      _prefix="$DIR/"
      SCOPE="found under $DIR (no git repo here)"
    fi

    CONF_REAL=$(readlink -f "${MAESTRO_MAC_CONF_FOUND:-/nonexistent}" 2>/dev/null)
    found=0
    for name in "${VARS[@]}"; do
      val=${!name}
      # A one- or two-character value matches everything; say so rather than
      # printing a page of noise or, worse, quietly passing.
      if [ "${#val}" -lt 3 ]; then
        echo "  $name is only ${#val} characters — too short to search for reliably. Skipped." >&2
        continue
      fi
      while IFS= read -r hit; do
        file=${hit%%:*}
        [ "$(readlink -f "$_prefix$file" 2>/dev/null)" = "$CONF_REAL" ] && continue
        printf '%s: %s\n' "$name" "${_prefix}${hit}"
        found=$((found + 1))
      done < <(_files | xargs -0 -r grep -nIFw -- "$val" 2>/dev/null |
               sed "s|^$DIR/||")
    done

    # The conf holds the credentials; check it is gitignored.
    if [ -n "${MAESTRO_MAC_CONF_FOUND:-}" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
      if ! git -C "$DIR" check-ignore -q "$MAESTRO_MAC_CONF_FOUND" 2>/dev/null; then
        echo "WARNING: $MAESTRO_MAC_CONF_FOUND is NOT gitignored." >&2
        echo "  Add this line to .gitignore:  .maestro-mac.conf" >&2
        found=$((found + 1))
      fi
    fi

    echo
    if [ "$found" -eq 0 ]; then
      echo "clean — no project value appears in any file $SCOPE."
    else
      echo "$found place(s) hold a value that is supposed to live only in the conf."
      echo "Replace each with \${NAME} — journeys and flows substitute it; prose in"
      echo "the app notes should name the variable rather than the value."
      exit 1
    fi
    ;;

  *) echo "usage: $0 [check [dir]|list]" >&2; exit 2 ;;
esac
