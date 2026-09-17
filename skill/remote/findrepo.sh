#!/bin/sh
# Runs ON THE MAC. Every git checkout under the home directory, with its origin,
# one per line: "<path>\t<origin url or ->".
#
# Session B on 11 Aug 2026 spent three SSH calls hunting for the checkout by
# hand — `ls -d ~/src/* ~/Development/* ~/Projects/*`, then a find. Guessing at
# roots is the slow way round; the fast way is one bounded find that prunes the
# caches, because those are where the thousands of directories are. On a real
# Mac: 3.3 s and twelve checkouts, against 4.3 s and a screenful of .pub-cache
# clones without the prune.
set -u
D=${1:-5}
find "$HOME" -maxdepth "$D" \
  \( -name Library -o -name .pub-cache -o -name .gradle -o -name node_modules \
     -o -name Pods -o -name .fvm -o -name .Trash -o -name .cache \
     -o -name .cocoapods -o -name DerivedData \) -prune -o \
  -type d -name .git -print 2>/dev/null |
while read -r g; do
  r=${g%/.git}
  o=$(git -C "$r" remote get-url origin 2>/dev/null)
  printf '%s\t%s\n' "$r" "${o:--}"
done
