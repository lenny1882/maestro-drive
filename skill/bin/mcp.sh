#!/bin/bash
# Launch the Maestro MCP server over SSH to the Mac.
#
# Replaces a bare `ssh <alias> maestro mcp` in the Claude config with a
# launcher that picks the right SSH alias from .maestro-drive.conf, so the MCP
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
if _fs_shared; then
  exec sh -c "$LOCAL_ENV
exec maestro mcp"
fi

# When no alias answers there is nothing to exec, and exiting here is what made
# this failure unreadable: Claude Code reports CONNECTION_CLOSED, which names
# the transport and not the Mac, the conf or the aliases tried. _pick_host
# already writes the diagnosis; a process that has exited has no channel to
# carry it. So the diagnosis becomes the server (BACKLOG item 97).
#
# stderr goes to a file rather than a $( ) capture because _pick_host sets
# MAC_HOST in this shell, and a subshell would lose the alias it picked on the
# path that works.
_why=$(mktemp "${TMPDIR:-/tmp}/maestro-mcp-why.XXXXXX")
if ! _pick_host 2>"$_why"; then
  _msg="The Maestro device tools are not available: no ssh alias in this project's
conf reached the Mac when the session started.

$(cat "$_why")
conf: ${MAESTRO_DRIVE_CONF_FOUND:-none found from $PWD}

Fix the network or the conf's MAC_HOST list, then restart the session — this
server cannot pick the connection up once the session is running."
  rm -f "$_why"
  exec python3 "$(dirname "$0")/unreachable-mcp.py" "$_msg"
fi
rm -f "$_why"

exec ssh \
  -o BatchMode=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=6 \
  "${SSH_OPTS[@]}" \
  "$MAC_HOST" \
  "$REMOTE_ENV
exec maestro mcp"
