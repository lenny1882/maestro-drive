#!/bin/bash
#
# FALLBACK ONLY. Prefer `bin/driver.sh nodes`, which is ~0.4s against ~10.7s
# here and can be pointed at any device with DEV=<udid>.
# Unlike the MCP server this does honour --device, so it is the way to read a
# second simulator when no driver is up for it yet.
#
# It costs that device its driver. Measured 13 Aug 2026: Maestro terminates the
# runner for the device it was given when the command finishes, whether the
# command worked or not, and a bin/drivers.sh layout loses that one entry.
# Every other device is untouched — it is not that port 22087 changes hands.
# The next bin/driver.sh call for that device says so and how to bring it back.
#
# Dump the current view hierarchy — every node, with bounds, ids and state.
#
# This is the default way to decide what to do next. It is text, it is one
# round trip, and it tells you what is actually tappable. Screenshots do not.
#
# CAUTION: Flutter builds list children lazily. Anything scrolled out of a
# ListView or a horizontal chip row is simply absent from this tree. Never
# conclude "the options are X" from a single dump — scroll and re-dump, or
# read the list from the network response that populated it.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
d=$(_dev) || exit 1
_ssh "maestro --device $d hierarchy > '$RDIR/hier.json' 2>/dev/null
      python3 '$RDIR/hier.py' '$RDIR/hier.json'"
