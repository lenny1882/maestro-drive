#!/bin/bash
# Edit a journey file, loudly.
#
# Until 17 Sep 2026 the only way to change a journey was `s.replace(old, new)`
# typed into a heredoc, and **a replace whose `old` does not match rewrites the
# file byte-identical and reports success**. A failed edit is then
# indistinguishable from an edit that did not help — and the next thing anybody
# does is re-run the journey and read the result as a fact about the app.
#
# Measured 16 Sep 2026 (`f13f0e13`): five inline python edits to two journeys in
# eleven minutes, including a revert, every one of them silent on a miss. Item
# 49's "repair the journey in place" is the right rule; this is the mechanism it
# was missing (BACKLOG item 83).
#
#   journey.sh edit <file> --replace-once <old> <new> [--dry]
#   journey.sh edit <file> --replace-once --old-file <f> --new-file <f> [--dry]
#   journey.sh show <file>
#
# A bare name resolves in the project's journey directory, the same as
# `driver.sh script`.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/config.sh" || exit 1

_resolve_file() {  # a bare name means the project's journey directory
  local f=$1
  [ -r "$f" ] && { echo "$f"; return 0; }
  [ -r "$JOURNEY_DIR/$f" ] && { echo "$JOURNEY_DIR/$f"; return 0; }
  echo "journey: no such journey — $f" >&2
  echo "  looked in .  and  $JOURNEY_DIR" >&2
  return 1
}

_edit() {
  local file="" old="" new="" dry=0 oldf="" newf=""
  file=$(_resolve_file "${1:?usage: $0 edit <file> --replace-once <old> <new>}") || return 1
  shift
  [ "${1:-}" = "--replace-once" ] || {
    echo "journey: edit takes --replace-once (the only mode there is, deliberately)" >&2
    return 2; }
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --old-file) oldf=$2; shift 2 ;;
      --new-file) newf=$2; shift 2 ;;
      --dry)      dry=1; shift ;;
      *) if [ -z "$old" ] && [ -z "$oldf" ]; then old=$1
         elif [ -z "$new" ] && [ -z "$newf" ]; then new=$1
         else echo "journey: unexpected argument '$1'" >&2; return 2
         fi; shift ;;
    esac
  done
  [ -n "$oldf" ] && { old=$(cat "$oldf") || return 1; }
  [ -n "$newf" ] && { new=$(cat "$newf") || return 1; }
  [ -n "$old" ] || { echo "journey: nothing to replace" >&2; return 2; }

  FILE="$file" OLD="$old" NEW="$new" DRY="$dry" python3 - <<'PY'
import difflib, os, sys

path, old, new = os.environ["FILE"], os.environ["OLD"], os.environ["NEW"]
dry = os.environ["DRY"] == "1"
src = open(path).read()
n = src.count(old)

# The whole point of this script. Exit 3 on absent, 4 on ambiguous — never 0
# with the file untouched, which is what the heredoc idiom did.
if n == 0:
    print("journey: that text is not in %s" % path, file=sys.stderr)
    print("  Nothing was written. The edit did NOT happen.", file=sys.stderr)
    # Name the nearest thing in the file, because the usual cause is whitespace
    # or a line that has already been changed by an earlier edit.
    want = old.splitlines()
    if want:
        best = difflib.get_close_matches(want[0], src.splitlines(), n=1, cutoff=0.5)
        if best:
            # Delimited and unstripped: the usual cause of a miss is trailing
            # whitespace or an indent, and printing both sides stripped hides
            # exactly the difference being diagnosed.
            print("  The closest line in the file is:", file=sys.stderr)
            print("    wanted: [%s]" % want[0], file=sys.stderr)
            print("    found:  [%s]" % best[0], file=sys.stderr)
            if want[0].strip() == best[0].strip():
                print("    They differ only in whitespace.", file=sys.stderr)
    sys.exit(3)
if n > 1:
    print("journey: that text appears %d times in %s" % (n, path), file=sys.stderr)
    print("  Nothing was written. Include enough surrounding lines to be unique.",
          file=sys.stderr)
    sys.exit(4)

out = src.replace(old, new, 1)
diff = difflib.unified_diff(src.splitlines(True), out.splitlines(True),
                            "a/" + os.path.basename(path), "b/" + os.path.basename(path))
sys.stdout.writelines(diff)
if dry:
    print("\n(--dry: nothing written)")
    sys.exit(0)
open(path, "w").write(out)
print("\nwrote %s" % path)
PY
}

case "${1:-}" in
  edit) shift; _edit "$@" ;;
  show) f=$(_resolve_file "${2:?usage: $0 show <file>}") || exit 1; grep -vE '^\s*(#|$)' "$f" ;;
  *) echo "usage: $0 edit <file> --replace-once <old> <new> [--dry]" >&2
     echo "       $0 edit <file> --replace-once --old-file <f> --new-file <f> [--dry]" >&2
     echo "       $0 show <file>" >&2
     echo "  A replace that does not match exits non-zero and writes nothing —" >&2
     echo "  which is the whole reason this exists (BACKLOG item 83)." >&2
     exit 2 ;;
esac
