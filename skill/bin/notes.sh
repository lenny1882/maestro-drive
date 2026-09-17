#!/bin/bash
# The project's app notes — create, locate, or append to them.
#
#   bin/notes.sh path     # where they are (or would be)
#   bin/notes.sh init     # create from the template if missing
#   bin/notes.sh add "<section>" "<what you found>" --measured|--once|--inferred
#
# The last argument is required and says how well the finding is known:
#
#   --measured   read off the device, with the reading that produced it
#   --once       seen once and not re-checked — a lead, not a fact
#   --inferred   worked out from source or documentation, not observed
#
# It is required because defaulting it would make every note claim the same
# confidence, which is the state this fixes. Five notes have turned out to be
# wrong and every one was written from a single sighting stated as fact
# (BACKLOG.md item 16). A note with no marker at all predates the convention and
# should be read as `once`.
#
# `add` refuses text containing a project value from the conf — a credential
# must not be written into a file the project commits. bin/secrets.sh checks.
#
# `add` appends a dated bullet under the matching `## ` heading, creating the
# file from the template and the heading if either is missing. It exists so
# recording a finding costs one line at the moment it is found, rather than an
# edit later that does not happen. The section is matched by case-insensitive
# substring, so `add bounds "..."` finds "Does this app report bounds correctly?".
#
# The notes live with the project because they describe one app. The template
# says what belongs in them; read it before adding.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/config.sh" || exit 1
HERE=$(cd "$(dirname "$0")" && pwd)

case "${1:-path}" in
  path) echo "$APP_NOTES" ;;
  init)
    if [ -e "$APP_NOTES" ]; then echo "exists: $APP_NOTES"; exit 0; fi
    mkdir -p "$(dirname "$APP_NOTES")" "$JOURNEY_DIR"
    sed "s|<bundle id>|$APP_ID|" "$HERE/../reference/app-notes-template.md" > "$APP_NOTES"
    echo "created: $APP_NOTES"
    echo "journeys: $JOURNEY_DIR"
    ;;
  add)
    sec=${2:?usage: $0 add "<section>" "<text>" --measured|--once|--inferred}
    txt=${3:?usage: $0 add "<section>" "<text>" --measured|--once|--inferred}
    case "${4:-}" in
      --measured) conf="measured" ;;
      --once)     conf="seen once" ;;
      --inferred) conf="inferred" ;;
      "") cat >&2 <<'MSG'
notes.sh: say how well this is known. One of:

  --measured   read off the device, with the reading that produced it
  --once       seen once and not re-checked — a lead, not a fact
  --inferred   worked out from source or documentation, not observed

Nothing was written. Five notes have turned out to be wrong, and every one was
written from a single sighting stated as fact; this is the question that would
have caught them.
MSG
        exit 2 ;;
      *) echo "notes.sh: unknown confidence '${4}' — use --measured, --once or --inferred" >&2; exit 2 ;;
    esac
    # The notes are committed; the conf is not. A finding that quotes a
    # credential puts it back in the repo, and it is far easier to refuse here
    # than to find it again later. bin/secrets.sh checks the whole project.
    while read -r _v; do
      [ -n "$_v" ] || continue
      [ "${#_v}" -ge 3 ] 2>/dev/null || continue
      case "$txt" in
        *"${!_v}"*)
          cat >&2 <<MSG
notes.sh: that text contains the value of \$$_v.

It lives in $MAESTRO_MAC_CONF_FOUND, which is kept out of
version control. The app notes are committed, so writing the value here undoes
that. Refer to it by name instead:

  ... the field takes \${$_v} ...

Nothing was written.
MSG
          exit 3 ;;
      esac
    done < <(_app_vars)

    [ -e "$APP_NOTES" ] || "$0" init >/dev/null
    APP_NOTES="$APP_NOTES" SEC="$sec" TXT="$txt" TODAY="$(date +%F)" CONF="$conf" \
      python3 "$HERE/notes_add.py"
    ;;
  archive)
    # Nothing is decided here: it opens a dated archive beside the notes and
    # tells you what to move. A script cannot tell a superseded measurement from
    # a current one, and guessing wrong loses the thing the file exists for.
    _arch="$(dirname "$APP_NOTES")/app-notes-archive.md"
    [ -r "$APP_NOTES" ] || { echo "no notes at $APP_NOTES" >&2; exit 1; }
    if [ ! -e "$_arch" ]; then
      {
        echo "# App notes — archive"
        echo
        echo "Entries moved out of app-notes.md because they are superseded,"
        echo "corrected in place, or about a screen this app no longer has."
        echo "Kept because a wrong note that was acted on is worth being able to"
        echo "find again — see the corrections rule in the template."
        echo
      } > "$_arch"
      echo "created: $_arch"
    fi
    echo "notes:   $APP_NOTES  ($(wc -l < "$APP_NOTES" | tr -d " ") lines)"
    echo "archive: $_arch  ($(wc -l < "$_arch" | tr -d " ") lines)"
    echo
    echo "Candidates — entries already marked wrong, superseded or corrected:"
    grep -n -i "wrong\|superseded\|corrected\|no longer\|stale\|withdrawn" "$APP_NOTES" \
      | head -40 | sed "s/^/  /" || echo "  none found by keyword"
    echo
    echo "Move what is genuinely dead into the archive, with its date and why."
    echo "Leave anything still true, and anything a reader may have acted on."
    ;;
  check)
    [ -r "$APP_NOTES" ] || { echo "notes.sh: no app notes at $APP_NOTES" >&2; exit 1; }
    python3 "$HERE/notes_check.py" < "$APP_NOTES"
    ;;
  promote)
    src="${PROJECT_DIR}/maestro/tooling-findings.md"
    [ -r "$src" ] || { echo "notes.sh: no tooling-findings.md in $PROJECT_DIR/maestro/" >&2; exit 1; }
    dest="$HERE/../reference/staging"
    mkdir -p "$dest"
    proj=$(basename "$PROJECT_DIR")
    target="$dest/${proj}-tooling-findings.md"
    cp "$src" "$target"
    echo "staged: $target"
    echo "  a person folds this into reference/ and commits it."
    echo "  staging lives under the installed skill: safe across installs only"
    echo "  if this was installed with ./install.sh --link. Check with"
    echo "  readlink -f ~/.claude/skills/maestro-remote-mac"
    ;;
  *) echo "usage: $0 [path|init|add <section> <text> --measured|--once|--inferred|check|promote]" >&2; exit 2 ;;
esac
