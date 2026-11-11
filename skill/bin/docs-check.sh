#!/bin/bash
# Is the bundled documentation mirror still the right version?
#
# The mirror in docs/pages/ is a snapshot. Maestro moves, and the docs are
# already behind the binary in places, so a stale mirror is quietly misleading
# rather than obviously broken. This compares the version it was taken from with
# the version installed on the Mac.
#
#   bin/docs-check.sh            # always prints a verdict
#   bin/docs-check.sh --quiet    # prints only when they differ
#
# This never fails a run. A version mismatch is worth telling the user about so
# they can decide to refresh; it is not a reason to stop testing.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)
QUIET=0; [ "${1:-}" = "--quiet" ] && QUIET=1

VERSION_FILE="$HERE/../docs/VERSION"
[ -r "$VERSION_FILE" ] || { echo "docs: no VERSION file — mirror provenance unknown" >&2; exit 0; }
# shellcheck disable=SC1090
. "$VERSION_FILE"

# Claims in the pinned mirror that are known to be WRONG for the version it was
# taken from (item 55). A mirror that says "no" when the answer is "yes" is worse
# than an absent one — it ends investigations that would otherwise succeed, and
# it was believed twice. Maintained by hand and gated on the version, so a
# refresh to a new mirror drops corrections that may no longer apply; the CLI's
# own `maestro <cmd> --help` on the Mac is the authority. Printed whenever this
# runs (including --quiet), because being surfaced is the whole point.
#
# Checked against 2.12.1 on 5 Nov 2026 (item 129). Both claims are still in the
# refreshed pages. `hidden=true` on --apple-team-id in TestCommand,
# PrintHierarchyCommand and RecordCommand was read from the jar. device.sh drove
# an iPhone XS Max on a driver built from 2.12.1's source.
KNOWN_WRONG_FOR="2.12.1"
if [ "${MAESTRO_VERSION:-}" = "$KNOWN_WRONG_FOR" ]; then
  cat >&2 <<'MSG'
docs: KNOWN-WRONG claims in this mirror (Maestro 2.12.1) — do NOT trust these:
  - "Executing tests on physical iOS devices is not supported yet"
    (get-started__supported-platform__ios__uikit.md) is FALSE for this skill —
    bin/device.sh drives a physical iPhone (physical-device.md, item 45).
  - --apple-team-id is documented only under `record`, and is a hidden option on
    `hierarchy` and `test` as well, so `--help` does not list it. On 2.12.1 it no
    longer gets a phone through the CLI, which refuses one as not connected
    (physical-device.md section 3).
MSG
else
  # A refresh turns the list above off, and it used to do that without a word
  # while the claims stayed in the new pages (item 129).
  cat >&2 <<MSG
docs: the known-wrong list was last checked against Maestro $KNOWN_WRONG_FOR, this mirror is ${MAESTRO_VERSION:-unknown}.
  Re-check its two claims, then update KNOWN_WRONG_FOR in bin/docs-check.sh.
MSG
fi

installed=$(_ssh 'maestro --version 2>/dev/null | tail -1' | tr -d '[:space:]')
if [ -z "$installed" ]; then
  [ "$QUIET" = 1 ] || echo "docs: could not read Maestro's version from the Mac"
  exit 0
fi

if [ "$installed" = "$MAESTRO_VERSION" ]; then
  [ "$QUIET" = 1 ] || echo "docs: mirror matches Maestro $installed (${PAGES:-?} pages, taken $MIRRORED)"
  exit 0
fi

cat <<MSG
docs: MIRROR IS STALE — taken from Maestro $MAESTRO_VERSION on $MIRRORED, the Mac now runs $installed.

  Nothing is blocked; the pages are still mostly right. But check anything
  version-sensitive against \`maestro <cmd> --help\` on the Mac before relying
  on it, and mention this to the user — refreshing is one command:

    bin/docs-refresh.sh

  Re-check the driver API too (reference/driver-api.md): it is undocumented and
  an upgrade may change it. bin/bench.sh re-derives the timing numbers.
MSG
exit 0
