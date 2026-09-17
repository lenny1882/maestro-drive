#!/bin/bash
# Print the Mac's current LAN address.
#
# Nothing should hardcode it. The Mac's name is mapped to an address on every
# network it uses, and DNS returns all of them regardless of which is
# live, so resolving the hostname is not enough — ask the Mac itself.
#
#   ./bin/macip.sh
#   curl "http://$(./bin/macip.sh):9999/"
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
_macip && echo
