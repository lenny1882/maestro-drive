#!/bin/bash
#
# Crop, rotate and shrink a PNG. Pixels in, pixels out — nothing here knows
# about points, screens or devices; `driver.sh shot` does that conversion and
# calls this.
#
#   ./img.sh <file> [--out FILE] [--rotate DEG] [--crop X,Y,W,H] [--scale PCT]
#   ./img.sh --size <file>          # "width height" in pixels, no decoding
#
# Operations apply in a fixed order — **rotate, then crop, then scale** — so a
# crop rectangle is always read against the upright picture. Degrees are
# clockwise and must be 90, 180 or 270. Without --out the file is rewritten in
# place.
#
# Why this exists: session B on 11 Aug 2026 ran `sips -r 270` and
# `sips -c … --cropOffset …` by hand on the Mac about eight times, and session D
# on 12 Aug spent calls hunting for a local image tool — `python3 -c "import
# PIL"`, then `which convert magick pngquant` — before hand-writing crops
# against a 1206x2622 screenshot.
#
# There is no dependency to install. Whichever of these the machine has is
# used, in this order:
#
#   magick / convert   ImageMagick, if it is on this machine (0.15s for a crop
#                      of a 6MP image, 0.8s for a rotate — measured 13 Aug)
#   sips               when the skill is being run from a Mac itself
#   sips on the Mac    otherwise: the file goes up, sips runs there, it comes
#                      back. Always available, because there is always a Mac —
#                      that is the whole premise of this skill — at the cost of
#                      one scp each way.
#
# IMG_BACKEND=auto|magick|sips|mac pins the choice, so the Mac path can be
# exercised from a machine that has ImageMagick.
set -uo pipefail
# lib.sh is NOT sourced here. It refuses to load without a project conf, and
# three of the four backends never touch the Mac — requiring a configured
# project to crop a PNG would be wrong, and would stop the tests running.
HERE=$(cd "$(dirname "$0")" && pwd)

_png_size() {  # prints "width height" in pixels, without decoding the image
  python3 -c '
import struct, sys
d = open(sys.argv[1], "rb").read(24)
if d[:8] != b"\x89PNG\r\n\x1a\n":
    sys.exit(1)
print(*struct.unpack(">II", d[16:24]))' "$1"
}

if [ "${1:-}" = "--size" ]; then
  [ -r "${2:-}" ] || { echo "img: cannot read ${2:-<no file>}" >&2; exit 1; }
  _png_size "$2" || { echo "img: $2 is not a PNG" >&2; exit 1; }
  exit 0
fi

FILE=""; OUT=""; ROT=0; CROP=""; SCALE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out)    OUT=$2; shift 2 ;;
    --rotate) ROT=$2; shift 2 ;;
    --crop)   CROP=$2; shift 2 ;;
    --scale)  SCALE=$2; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)       echo "img: unknown option $1" >&2; exit 2 ;;
    *)        FILE=$1; shift ;;
  esac
done
[ -n "$FILE" ] || { echo "usage: $0 <file> [--out f] [--rotate deg] [--crop x,y,w,h] [--scale pct]" >&2; exit 2; }
[ -r "$FILE" ] || { echo "img: cannot read $FILE" >&2; exit 1; }
OUT=${OUT:-$FILE}

case "$ROT" in 0|90|180|270) ;; *) echo "img: --rotate must be 90, 180 or 270 (got '$ROT')" >&2; exit 2 ;; esac
if [ -n "$CROP" ]; then
  case "$CROP" in
    *,*,*,*) IFS=, read -r CX CY CW CH <<<"$CROP" ;;
    *) echo "img: --crop wants X,Y,W,H in pixels (got '$CROP')" >&2; exit 2 ;;
  esac
  # Rounded, not truncated: a crop rectangle comes from points times a scale
  # factor and lands on halves as often as not.
  read -r CX CY CW CH <<<"$(python3 -c 'import sys;print(" ".join(str(int(round(float(v)))) for v in sys.argv[1:]))' "$CX" "$CY" "$CW" "$CH")"
  [ "$CW" -gt 0 ] && [ "$CH" -gt 0 ] || { echo "img: --crop width and height must be positive" >&2; exit 2; }
fi
[ -z "$SCALE" ] || case "$SCALE" in
  ''|*[!0-9]*) echo "img: --scale wants a whole percentage (got '$SCALE')" >&2; exit 2 ;;
esac
# Clamped against the picture it will actually be cut from — after the rotation,
# so the axes are the ones the caller measured against. Both backends accept a
# rectangle that runs off the edge and disagree about it: ImageMagick narrows
# the crop, sips slides it. Measured 13 Aug on a rectangle two pixels too wide —
# 1748x180 against 1750x180, and 360 pixels of difference. Neither is wrong, so
# the rectangle is made to fit here instead.
if [ -n "$CROP" ]; then
  read -r IW IH <<<"$(_png_size "$FILE")" || { echo "img: $FILE is not a PNG" >&2; exit 1; }
  case "$ROT" in 90|270) read -r IW IH <<<"$IH $IW" ;; esac
  [ "$CX" -lt "$IW" ] && [ "$CY" -lt "$IH" ] \
    || { echo "img: --crop starts at $CX,$CY, outside a ${IW}x${IH} picture" >&2; exit 2; }
  [ $((CX + CW)) -le "$IW" ] || CW=$((IW - CX))
  [ $((CY + CH)) -le "$IH" ] || CH=$((IH - CY))
fi

if [ "$ROT" = 0 ] && [ -z "$CROP" ] && [ -z "$SCALE" ]; then
  [ "$OUT" = "$FILE" ] || cp -f "$FILE" "$OUT"
  echo "$OUT"; exit 0
fi

# --- backends ---------------------------------------------------------------

_with_magick() {  # _with_magick <bin>
  local a=("$1" "$FILE")
  [ "$ROT" = 0 ] || a+=(-rotate "$ROT")
  [ -z "$CROP" ] || a+=(-crop "${CW}x${CH}+${CX}+${CY}" +repage)
  [ -z "$SCALE" ] || a+=(-resize "${SCALE}%")
  a+=("$OUT")
  "${a[@]}"
}

# sips takes height before width, everywhere, and -c crops about the centre
# until --cropOffset moves it — so the argument order below is not a typo.
# It also has no percentage resize, hence the pixelWidth read.
_sips_script() {  # the shell to run wherever sips lives; $1 in, $2 out
  cat <<SIPS
set -e
cp -f "$1" "$2"
$([ "$ROT" = 0 ] || echo "sips -r $ROT \"$2\" --out \"$2\" >/dev/null")
$([ -z "$CROP" ] || echo "sips -c $CH $CW --cropOffset $CY $CX \"$2\" --out \"$2\" >/dev/null")
$([ -z "$SCALE" ] || cat <<INNER
w=\$(sips -g pixelWidth "$2" | awk '/pixelWidth/{print \$2}')
sips --resampleWidth \$(( w * $SCALE / 100 )) "$2" --out "$2" >/dev/null
INNER
)
SIPS
}

_with_local_sips() {
  local t; t=$(mktemp "${TMPDIR:-/tmp}/img.XXXXXX.png") || return 1
  _sips_script "$FILE" "$t" | bash && mv -f "$t" "$OUT" || { rm -f "$t"; return 1; }
}

_with_mac_sips() {
  local base r_in r_out
  # shellcheck disable=SC1091
  . "$HERE/lib.sh" || return 1
  # This backend means "send it to the machine that has sips". Locally that
  # machine is this one, and it has not got sips or it would have been chosen
  # two branches up. Say so rather than failing inside a sips that is not there.
  if _fs_shared; then
    echo "img: no image tool on this machine — install ImageMagick (magick or convert)." >&2
    return 1
  fi
  base=$(basename "$FILE")
  r_in="$RDIR/img-in-$$-$base"; r_out="$RDIR/img-out-$$-$base"
  _ssh "mkdir -p '$RDIR'" >/dev/null || return 1
  _pick_host || return 1
  _push "$FILE" "$r_in" || return 1
  _ssh "$(_sips_script "$r_in" "$r_out")
base64 < '$r_out'
rm -f '$r_in' '$r_out'" | base64 -d > "$OUT.tmp" || { rm -f "$OUT.tmp"; return 1; }
  [ -s "$OUT.tmp" ] || { rm -f "$OUT.tmp"; echo "img: the Mac returned an empty image" >&2; return 1; }
  mv -f "$OUT.tmp" "$OUT"
}

# IMG_BACKEND pins the choice. It exists so the Mac path can be exercised on a
# machine that has ImageMagick — otherwise the fallback nobody's machine takes
# is the one nobody ever tests. Values: auto (default), magick, sips, mac.
case "${IMG_BACKEND:-auto}" in
  magick) command -v magick >/dev/null 2>&1 && _with_magick magick || _with_magick convert ;;
  sips)   _with_local_sips ;;
  mac)    _with_mac_sips ;;
  auto)
    if command -v magick >/dev/null 2>&1;    then _with_magick magick
    elif command -v convert >/dev/null 2>&1; then _with_magick convert
    elif command -v sips >/dev/null 2>&1;    then _with_local_sips
    else                                          _with_mac_sips
    fi ;;
  *) echo "img: IMG_BACKEND must be auto, magick, sips or mac (got '$IMG_BACKEND')" >&2; exit 2 ;;
esac || { echo "img: could not process $FILE" >&2; exit 1; }

echo "$OUT"
