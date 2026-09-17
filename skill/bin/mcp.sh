#!/bin/bash
# Launch the Maestro MCP server over SSH to the Mac.
#
# Replaces a bare `ssh <alias> maestro mcp` in the Claude config with a
# launcher that picks the right SSH alias from .maestro-mac.conf, so the MCP
# server follows the Mac between networks the same way every bin/ script does.
#
# Claude config entry (settings.json or .claude.json):
#
#   "maestro-mac": {
#     "type": "stdio",
#     "command": "/path/to/bin/mcp.sh"
#   }
#
# The script is its own entry point — it does not take arguments — so the
# config names the script and nothing else.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

_pick_host || exit 1

exec ssh \
  -o BatchMode=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=6 \
  "${SSH_OPTS[@]}" \
  "$MAC_HOST" \
  "$REMOTE_ENV
exec maestro mcp"
