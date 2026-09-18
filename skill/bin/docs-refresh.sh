#!/bin/bash
# Re-download the Maestro documentation mirror.
#
# The download runs on the Mac, because there is no route to the internet from
# here. The pages come back as one tarball rather than 154 transfers.
#
#   bin/docs-refresh.sh              # refresh docs/ in place
#   bin/docs-refresh.sh --into DIR   # somewhere else, to compare before replacing
#   bin/docs-refresh.sh --limit 5    # a few pages, to check the plumbing
#
# Page names mirror the URL path with / replaced by __, which is what makes
# `grep -rn something docs/pages/reference__*` work.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)
DEST="$HERE/../docs"; LIMIT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --into)  DEST=$2; shift 2 ;;
    --limit) LIMIT=$2; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

echo "downloading on $(_where) ..."
_ssh "
set -e
rm -rf '$RDIR/mdocs'; mkdir -p '$RDIR/mdocs/pages'; cd '$RDIR/mdocs'
curl -sS https://docs.maestro.dev/llms.txt -o llms.txt
grep -oE 'https://docs\.maestro\.dev/[^)]+\.md' llms.txt | sort -u > urls.txt
[ '$LIMIT' -gt 0 ] && head -'$LIMIT' urls.txt > u2 && mv u2 urls.txt
while read -r u; do
  n=\${u#https://docs.maestro.dev/}; n=\${n//\//__}
  printf '%s\n%s\n' \"\$u\" \"\$n\"
done < urls.txt | xargs -P 8 -n 2 sh -c 'curl -sS \"\$0\" -o \"pages/\$1\"'
v=\$(maestro --version 2>/dev/null | tail -1)
printf 'MAESTRO_VERSION=%s\nMIRRORED=%s\nPAGES=%s\n' \"\$v\" \"\$(date +%F)\" \"\$(ls pages | wc -l | tr -d ' ')\" > VERSION
tar czf docs.tgz pages urls.txt VERSION
ls -1 pages | wc -l
" || { echo "download failed on the Mac" >&2; exit 1; }

mkdir -p "$DEST"
_pull "$RDIR/mdocs/docs.tgz" "$LDIR/docs.tgz" || exit 1
# replace the pages wholesale — a page deleted upstream should disappear here too
rm -rf "$DEST/pages.new" && mkdir -p "$DEST/pages.new"
tar xzf "$LDIR/docs.tgz" -C "$DEST/pages.new" || exit 1
rm -rf "$DEST/pages" && mv "$DEST/pages.new/pages" "$DEST/pages"
mv "$DEST/pages.new/urls.txt" "$DEST/urls.txt"
mv "$DEST/pages.new/VERSION" "$DEST/VERSION"
rmdir "$DEST/pages.new"
echo "refreshed $DEST"
cat "$DEST/VERSION"
