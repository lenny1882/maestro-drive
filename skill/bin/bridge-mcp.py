#!/usr/bin/env python3
"""An MCP server whose only job is to start and stop the bridge helper.

  "maestro-bridge": {"type": "stdio", "command": "python3",
                     "args": ["~/.claude/skills/maestro-drive/bin/bridge-mcp.py"]}

Why a server at all (BACKLOG item 96). Inside a Claude session the Bash tool is
sandboxed: no /dev/kvm, its own PID and network namespaces, writes confined to
two directories. An emulator cannot start in there and a device started outside
cannot be seen from inside. An MCP server is not in that sandbox — Claude Code
spawns it itself — so it can start the helper that does.

Why only start and stop. Booting a device is `platform.sh boot`, which already
exists for both platforms and already runs on the machine with the device, so it
travels over the bridge like every other verb. Putting a `boot` tool here would
mean an Android answer and an iOS answer living in a server instead of in the
runner modules, which is the seam this package is built on. The verb list is
deliberately three words long, it takes no paths, and it runs nothing but
remote/bridge.sh.

What it does grant, said plainly: the helper it starts carries arbitrary shell
to this machine. That is the same capability the ssh transport has against the
Mac, pointed at the machine the sandbox protects. So the helper is started when
asked and not before, everything it runs is logged in its own directory, and
`stop` ends it.
"""
import json
import os
import random
import string
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BRIDGE = os.path.join(os.path.dirname(HERE), "remote", "bridge.sh")

# The sandbox's scratch is a real directory on this machine, which is what makes
# it the channel: /tmp/claude-<uid>. Both sides see it, and it is per-session
# rather than a well-known path anything else writes to.
BASE = "/tmp/claude-%d" % os.getuid()
STATE_DIR = BASE if os.path.isdir(BASE) else "/tmp"

# One record per Claude session, keyed by the pid of the Claude process that
# owns it (BACKLOG item 175). Until 2.2.0 this was one file for every session of
# the user, so any session's SessionEnd hook stopped whichever helper was started
# last, by anyone, and a second session's start overwrote the first's record.
#
# The server finds its owner as CLAUDE_PID, which Claude Code sets in the
# environment of what it spawns, or else as its own parent: Claude Code spawns
# stdio servers directly. A hook or command line, which is not the server, finds
# it the same way, or else by walking up its own parents to the first one that
# has a record — the Claude process is an ancestor of both.
def _state(owner):
    return os.path.join(STATE_DIR, ".maestro-bridge.%s" % owner)


def _env_owner():
    v = os.environ.get("CLAUDE_PID", "").strip()
    return v if v.isdigit() else None


def _parent(pid):
    try:
        with open("/proc/%d/stat" % pid) as fh:
            # The command name is in parentheses and may hold spaces; the ppid
            # is the second field after it.
            return int(fh.read().rsplit(")", 1)[1].split()[1])
    except (OSError, IndexError, ValueError):
        pass
    try:
        out = subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)],
                             capture_output=True, text=True, timeout=5)
        return int(out.stdout.strip())
    except Exception:
        return 0


def server_owner():
    return _env_owner() or str(os.getppid())


def find_owner():
    """The owner whose record this process sits under, for the hook's --stop."""
    env = _env_owner()
    if env:
        return env
    pid = os.getppid()
    for _ in range(64):
        if pid <= 1:
            break
        if os.path.exists(_state(pid)):
            return str(pid)
        pid = _parent(pid)
    return None


def _run(cmd):
    try:
        out = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return (out.stdout + out.stderr).strip()
    except Exception as exc:
        return "%s: %s" % (type(exc).__name__, exc)


def _host():
    """The address this machine is reachable at from inside the sandbox.

    Not 127.0.0.1: the sandbox has its own loopback. This is what BRIDGE_HOST in
    the conf must be, and what every URL the sandbox builds will name.
    """
    out = _run("hostname -I 2>/dev/null")
    return out.split()[0] if out.split() else ""


def _current(owner):
    """The directory of the helper this owner started, if it is still alive."""
    if not owner:
        return None
    try:
        with open(_state(owner)) as fh:
            d = fh.read().strip()
    except OSError:
        return None
    if not d or not os.path.isdir(d):
        return None
    # The helper's own record of who started it. A record whose helper names
    # somebody else is not this owner's, whatever the file name says.
    try:
        with open(os.path.join(d, "owner")) as fh:
            if fh.read().strip() != str(owner):
                return None
    except OSError:
        return None
    try:
        with open(os.path.join(d, "pid")) as fh:
            pid = int(fh.read().strip())
        os.kill(pid, 0)
    except (OSError, ValueError):
        return None
    return d


def start(owner):
    d = _current(owner)
    if d:
        return "already serving %s\n\n%s" % (d, _conf(d))
    tag = "".join(random.choice(string.ascii_lowercase + string.digits) for _ in range(8))
    d = os.path.join(BASE if os.path.isdir(BASE) else "/tmp", "maestro-bridge-" + tag)
    os.makedirs(d, mode=0o700, exist_ok=True)
    with open(os.path.join(d, "owner"), "w") as fh:
        fh.write("%s\n" % owner)
    try:
        subprocess.Popen(
            ["sh", BRIDGE, d],
            stdout=open(os.path.join(d, "serve.log"), "w"),
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
    except Exception as exc:
        return "could not start the helper: %s: %s" % (type(exc).__name__, exc)
    for _ in range(100):
        if os.path.exists(os.path.join(d, "control")):
            break
        subprocess.run(["sleep", "0.05"])
    if not os.path.exists(os.path.join(d, "control")):
        return "the helper did not come up. Its own log:\n%s" % _tail(os.path.join(d, "serve.log"))
    try:
        with open(_state(owner), "w") as fh:
            fh.write(d)
    except OSError:
        pass
    return "serving %s\nowner %s\n\n%s" % (d, owner, _conf(d))


def _conf(d):
    host = _host()
    # Empty means this server is itself somewhere without a network interface —
    # which is what a sandbox looks like, and a sign it is not where it should
    # be. Say so rather than write an empty setting into a conf.
    host_line = (
        '  : "${BRIDGE_HOST:=%s}"\n' % host if host else
        '  : "${BRIDGE_HOST:=}"   <- EMPTY. This server saw no network interface,\n'
        "                             which means it is not running where it should be.\n"
        "                             `hostname -I` on the machine with the device gives it.\n"
    )
    return (
        "Put these in the project's .maestro-drive.conf:\n"
        '  : "${TRANSPORT:=bridge}"\n'
        '  : "${BRIDGE_DIR:=%s}"\n'
        "%s"
        "\nEverything it runs is logged in %s/log."
    ) % (d, host_line, d)


def _tail(path, n=10):
    try:
        with open(path) as fh:
            return "".join(fh.readlines()[-n:])
    except OSError:
        return "(no log)"


def stop(owner):
    d = _current(owner)
    if not d:
        return "no helper of mine is running (owner %s)." % (owner or "unknown")
    try:
        # The helper's own control loop understands this, so it stops between
        # requests rather than in the middle of one.
        with open(os.path.join(d, "control"), "w") as fh:
            fh.write("stop\n")
    except OSError as exc:
        return "could not reach the helper's control fifo: %s" % exc
    try:
        os.unlink(_state(owner))
    except OSError:
        pass
    return "told the helper in %s to stop. Its log stays for reading." % d


def status(owner):
    d = _current(owner)
    if not d:
        return "no helper of mine is running (owner %s). The device host address would be %s." % (
            owner or "unknown", _host() or "unknown")
    ran = 0
    try:
        with open(os.path.join(d, "log")) as fh:
            ran = sum(1 for line in fh if line.rstrip().endswith("  ---"))
    except OSError:
        pass
    return "serving %s\nowner %s\n%d scripts run so far\n\n%s" % (d, owner, ran, _conf(d))


TOOL = {
    "name": "bridge",
    "description": (
        "Start, stop or report the maestro-drive bridge helper — the process "
        "outside the Bash sandbox that runs this package's scripts on the machine "
        "with the device. It takes no paths and runs nothing else."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "action": {"type": "string", "enum": ["start", "stop", "status"]},
        },
        "required": ["action"],
    },
}

ACTIONS = {"start": start, "stop": stop, "status": status}


def reply(mid, result):
    sys.stdout.write(json.dumps({"jsonrpc": "2.0", "id": mid, "result": result}) + "\n")
    sys.stdout.flush()


def main():
    owner = server_owner()
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
                "serverInfo": {"name": "maestro-bridge", "version": "1"},
            })
        elif method == "tools/list":
            reply(mid, {"tools": [TOOL]})
        elif method == "tools/call":
            params = msg.get("params") or {}
            action = (params.get("arguments") or {}).get("action", "status")
            fn = ACTIONS.get(action)
            text = fn(owner) if fn else "unknown action %r — use start, stop or status." % action
            reply(mid, {"content": [{"type": "text", "text": text}]})
        elif mid is not None:
            reply(mid, {})


if __name__ == "__main__":
    # Two entry points, one implementation. The SessionEnd hook cannot call an
    # MCP tool — hooks are not a Claude session — so it runs this with --stop.
    #
    # The hook names its owner with --owner, found before it detaches: a
    # detached process is reparented and can no longer walk up to Claude.
    # `--owner` on its own prints the owner this process would act for.
    args = sys.argv[1:]
    if args and args[0] in ("--stop", "--status", "--start", "--owner"):
        owner = None
        if "--owner" in args[1:]:
            i = args.index("--owner", 1)
            owner = args[i + 1] if i + 1 < len(args) and args[i + 1].isdigit() else None
        elif args[0] == "--start":
            owner = server_owner()
        else:
            owner = find_owner()
        if args[0] == "--owner":
            if owner:
                print(owner)
            raise SystemExit(0 if owner else 1)
        print(ACTIONS[args[0][2:]](owner))
        raise SystemExit(0)
    main()
