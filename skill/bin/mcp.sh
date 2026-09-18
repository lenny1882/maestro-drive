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

# Local transport execs the server here. NOT through _ssh, and the reason is
# structural rather than stylistic: _ssh wraps its command in `timeout $TMO` and
# returns, while an MCP server has to hold stdio open for the life of the Claude
# session. Three minutes in, the default $TMO would kill it and the session
# would lose every device tool with no error a reader could act on. `exec`
# replaces this process, which is what the config entry already expects — so the
# registered entry needs no change to follow the conf between transports.
if [ "$TRANSPORT" = local ]; then
  exec sh -c "$LOCAL_ENV
exec maestro mcp"
fi

_pick_host || exit 1

exec ssh \
  -o BatchMode=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=6 \
  "${SSH_OPTS[@]}" \
  "$MAC_HOST" \
  "$REMOTE_ENV
exec maestro mcp"
