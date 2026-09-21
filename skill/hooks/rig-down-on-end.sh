#!/bin/bash
# SessionEnd hook — take down the simulators THIS session booted, and nothing
# else.
#
# Why this cannot be prose. `drivers.sh rig down` is in SKILL.md, and a session
# that has run out of context, crashed, or simply been closed cannot be
# instructed to type anything. Every ending that is not a tidy one leaves the
# simulator booted, its driver running and its name on the wall — and because
# nothing clears a label at session end, the next session cannot tell that name
# from one somebody set by hand, so it inherits it (BACKLOG item 67). The maintainer
# opened the wall on 16 Sep 2026 to four simulators named 13 hours earlier, none
# of them working, and a tile reading `named 15h ago` under a live session that
# was not the one named on it.
#
# Scope, deliberately narrow. It takes down only what `rig up` BOOTED, recorded
# per session on the Mac in $RDIR/rig/<session>. A simulator that was already
# booted when the rig found it is left alone, because it belongs to somebody —
# a teardown that takes a peer's device with it is worse than one that leaves
# something behind. Drivers this session started on devices it did not boot are
# also left, for the same reason.
#
# It never fails a session. Everything is best-effort and it always exits 0: a
# hook that makes closing a terminal report an error would be worse than a
# simulator left running.
#
# Install (the operator's step — the skill cannot write settings.json):
#
#   "SessionEnd": [
#     { "hooks": [ { "type": "command",
#         "command": "bash ~/.claude/skills/maestro-remote-mac/hooks/rig-down-on-end.sh" } ] }
#   ]
#
# `bash <path>`, not the path alone: the sandbox refuses chmod +x under
# ~/.claude, so this cannot be relied on to carry its exec bit. Same convention
# as gate-journey-first.sh. reference/setup.md § 5 has the whole block.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
DRIVERS="$HERE/../bin/drivers.sh"
[ -r "$DRIVERS" ] || exit 0

# Detached and not waited on: SessionEnd must not hold the terminal open for an
# SSH round trip, and `rig down` is idempotent if it is cut short.
#
# The bridge helper goes after the rig and not before it, because under
# TRANSPORT=bridge `rig down` travels through that helper — stopping it first
# would leave the very simulators this hook exists to take down (item 96, 2.2).
# It is a process outside the sandbox with a shell channel into this machine, so
# ending the session ends it; a helper that outlives the session that asked for
# it is the thing the item's controls are about.
BRIDGE_MCP="$HERE/../bin/bridge-mcp.py"
(
  bash "$DRIVERS" rig down
  [ -r "$BRIDGE_MCP" ] && command -v python3 >/dev/null 2>&1 &&
    python3 "$BRIDGE_MCP" --stop
) >/dev/null 2>&1 &
exit 0
