#!/usr/bin/env python3
"""An MCP server that exists to say why the Maestro server is not here.

BACKLOG item 97. `bin/mcp.sh` reaches the Mac over ssh and execs `maestro mcp`
on it. When no alias in the conf answers there is nothing to exec, and the
script used to exit — which Claude Code reports as `CONNECTION_CLOSED`, a
sentence about a transport that names neither the Mac, the conf, nor the
aliases that were tried. It reads as a broken install, and the session loses
every device tool with no way to find out why.

`_pick_host` already writes the useful diagnosis to stderr. A process that has
exited has no channel to Claude, so nobody reads it. This server is that
channel: mcp.sh execs it instead of exiting, it holds the session's stdio open
like a real server, and it answers every call with the reason.

It is deliberately not a retry or a proxy. Answering `tools/list` with the
Maestro tool set would be a lie — those tools cannot run — and connecting
lazily on first use is a stdio proxy for the life of the session, which is a
larger thing than this package has anywhere. Restarting the session after the
Mac is reachable is the fix, and saying so is this server's whole job.

The message comes in on argv so the caller owns the wording: mcp.sh passes what
_pick_host printed, aliases and all.
"""
import json
import sys

WHY = sys.argv[1] if len(sys.argv) > 1 else "the Mac could not be reached."

TOOL = {
    "name": "why_unreachable",
    "description": (
        "Report why the Maestro device tools are not available in this session. "
        "The Mac that runs them could not be reached when the session started."
    ),
    "inputSchema": {"type": "object", "properties": {}},
}


def reply(mid, result):
    sys.stdout.write(json.dumps({"jsonrpc": "2.0", "id": mid, "result": result}) + "\n")
    sys.stdout.flush()


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        method, mid = msg.get("method"), msg.get("id")
        if method == "initialize":
            ver = (msg.get("params") or {}).get("protocolVersion") or "2024-11-05"
            reply(mid, {
                "protocolVersion": ver,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "maestro-mac (unreachable)", "version": "1"},
            })
        elif method == "tools/list":
            reply(mid, {"tools": [TOOL]})
        elif method == "tools/call":
            # Every call, whatever it names. A server that answered only its own
            # tool would leave a caller that guessed a Maestro tool name with a
            # protocol error instead of the reason.
            reply(mid, {"content": [{"type": "text", "text": WHY}], "isError": True})
        elif mid is not None:
            reply(mid, {})


if __name__ == "__main__":
    main()
