#!/bin/bash
# Print the Mac's current LAN address.
#
# Nothing should hardcode it. The Mac's name is mapped to an address on every
# network it uses, and DNS returns all of them regardless of which is
# live, so resolving the hostname is not enough — ask the Mac itself.
#
#   ./bin/macip.sh
#   curl "http://$(./bin/macip.sh):9999/"
#
# In local transport there is no Mac and no LAN address to print: the device is
# on this machine and every URL the skill builds is 127.0.0.1. _macip says so
# and exits 1 rather than printing something (item 94, 4.4).
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
_macip && echo
