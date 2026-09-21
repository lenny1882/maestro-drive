#!/bin/bash
#
# Screenshot of a chosen device, straight from the platform. Prefer
# `bin/driver.sh shot`, which comes from that device's own driver and so is
# never the wrong simulator. The MCP `take_screenshot` tool can only see the
# device on port 22087, whichever device_id it is given — and running it costs
# that device its driver, measured 13 Aug 2026.
#
# Fetch a screenshot.
#
#   ./shot.sh <name> [settle-seconds] [--rotate DEG] [--crop X,Y,W,H] [--scale PCT]
#
# The three options are handed straight to bin/img.sh and are in **pixels**, not
# points. Turning a sideways iPad picture upright by itself, and cropping to a
# named element, need the view hierarchy to know which way round the screen is —
# only the driver has that, so those live on `bin/driver.sh shot` instead.
#
# Use this only for questions that are genuinely about appearance — colour,
# contrast, overflow, status bar styling. For "what is on screen and what can
# I tap", hier.sh is cheaper and more accurate. A screenshot costs this round
# trip plus a separate image read, roughly 30s, to tell you less.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
d=$(_dev) || exit 1
N="shot"; S=1; IMG=(); _pos=0
while [ $# -gt 0 ]; do
  case "$1" in
    --rotate|--crop|--scale) IMG+=("$1" "$2"); shift 2 ;;
    -*) echo "shot: unknown option $1" >&2; exit 2 ;;
    *)  _pos=$((_pos + 1)); [ "$_pos" = 1 ] && N=$1 || S=$1; shift ;;
  esac
done

# The platform writes the file on the Mac; base64 back is this side's business,
# and the module must not do it — an encoder in the verb would make every caller
# that wants the file on the Mac decode it again.
# Across ssh the fetch is folded into the same call, because the alternative is
# a second connection for a file that is already in hand. Locally that encode
# and decode is pure cost — and worse than cost: $RDIR and $LDIR are two real
# directories here too, so the pair would be doing by arithmetic what `cp` does
# by name. The branch is the point of the unit, not a wart in it.
if _fs_shared; then
  _ssh "sleep $S; sh '$PLATFORM_SH' screenshot '$d' '$RDIR/$N.png'" || exit 1
  _pull "$RDIR/$N.png" "$LDIR/$N.png" || exit 1
else
  _ssh "sleep $S; sh '$PLATFORM_SH' screenshot '$d' '$RDIR/$N.png' && base64 < '$RDIR/$N.png'" \
    | base64 -d > "$LDIR/$N.png"
fi
[ -s "$LDIR/$N.png" ] || { echo "shot: no image came back for $d" >&2; exit 1; }
[ ${#IMG[@]} -eq 0 ] || "$(dirname "$0")/img.sh" "$LDIR/$N.png" "${IMG[@]}" >/dev/null || exit 1
ls -la "$LDIR/$N.png"
