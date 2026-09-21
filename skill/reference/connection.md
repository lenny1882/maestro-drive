# Reaching the Mac, and what survives between calls

Everything here was measured from inside a Claude Code session on 11 Aug 2026.
It is about this sandbox and a Mac on the same network; none of it is about
Maestro, and all of it applies whatever you are driving.

## 2. Connection hygiene

Measured 11 Aug 2026 from inside a Claude Code session.

**SSH itself works and is cheap.** 0.30–0.44 s to connect and run a command.
That is not where the time goes — see `reference/connection.md` and the batching section below.

**`~/.ssh/known_hosts` now persists.** Earlier in this work the sandbox blocked
the write, so every call printed `Failed to add the host to the list of known
hosts` and the helper scripts carried `StrictHostKeyChecking=accept-new` plus a
`grep -v` to hide it. After a settings change the Mac's key is written normally,
so none of that boilerplate is needed any more.

**Do not bother with `ControlMaster`.** It fails with `muxclient socket():
Operation not permitted`, and reference/connection.md explains why fixing that would not help.

**Use the name for HTTP, the SSH alias for SSH.** `<mac>.local` works for HTTP
because the sandbox proxy resolves it, but SSH takes a different route and needs
an alias with a `Host` block. The measurements are below.

**Build the helper scripts up front.** In the original session `mac.sh`,
`flow.sh`, `shot.sh`, `hier.sh` and `net.sh` appeared over three hours, and
`hier.sh` was rewritten three times (12:15, 12:16, 12:20), each rewrite costing
a round trip. Take them from `bin/` instead.

## 3. Nothing on this side persists — put residency on the Mac

All of this was measured on 11 Aug 2026, not inferred.

### Every Bash call is a fresh container

```
$$ = 2, and PID 1 exists          -> own PID namespace
ip -brief addr  ->  lo  127.0.0.1/8 ::1/128, and no routes at all
```

Own PID namespace and own network namespace, per call. The consequences are all
the same consequence:

- `ControlMaster` fails with `muxclient socket(): Operation not permitted`, and
  would be pointless anyway — the socket could not outlive the call.
- `ssh -f -N -L` forks and returns 0, then dies with the call.
- The harness's background mechanism does not keep it alive either.
- A tunnel opened in a call **does** work inside that call: listener binds,
  traffic reaches the Mac, 0.36 s to set up and ~76 ms a round trip. It is gone
  by the next call.

So do not design around anything resident on this side. There is nothing to
hold open.

### What to use instead, when something genuinely has to outlive the call

The rule above says what dies. It did not, until 17 Sep 2026, say what does not
— so every session that needed a watcher found out by having one die. Three
facts, measured 15-17 Sep 2026 (BACKLOG item 71):

**`nohup … &` does not survive.** Re-tested 17 Sep: a `nohup bash -c 'for i in
1..8; do echo tick; sleep 4; done' &` wrote exactly one tick and the process was
gone by the next call. Twenty-one `nohup` attempts were made across 15-16 Sep
regardless. The failure is silent and it looks like success — the call prints
`started pid 5` and returns 0.

**The harness's `run_in_background: true` does survive.** It is the mechanism,
and it was used 88 times across those two days *after* two sessions stumbled
onto it. It returns a task id and a file the output is written to, which can be
read with `Read` while the thing is still running. Use it for a watcher, a
sampler, a poll, a long seed — anything that has to still be there on the next
call.

**`sleep N; <read the log>` is refused.** Six times across those two days:
*"Blocked: sleep 75 followed by … To wait for a condition, use Monitor with an
until-loop."* So the obvious way to wait on a background job costs a rejected
call. Use `Monitor` with an until-loop for a condition, and read the task's
output file for progress; do not chain shorter sleeps to get around it.

**And whatever you start detached cannot find the project conf.** `config.sh`
walks up from `$PWD`, and a process started from `$TMPDIR` is nowhere near the
project — it stops with "not configured for this project", which reads as a
broken install. Since 17 Sep `config.sh` remembers the conf this session last
found and falls back to it, so this usually resolves itself; pass
`MAESTRO_DRIVE_CONF=<project>/.maestro-drive.conf` explicitly when it does not.

**A pid is namespace-local, so a pid file cannot be a lock across calls.** The
same fresh-container rule that kills `nohup` makes pids meaningless between
calls: a process started by one call has a pid in that call's namespace, so a
later call's `kill -0 <pid>` fails on a process that is running perfectly well,
and its `kill <pid>` reaches nothing. Measured 17 Sep 2026 while building
`driver.sh watch` — a pid-file lock reported "NOT watching" over a live watcher
and then let a second one start, which is the exact collision the lock existed
to prevent.

What works instead is the filesystem, which every call shares:

| want | do |
| --- | --- |
| is it alive? | a claim file, plus the mtime of the file it writes to |
| stop it | touch a stop file it polls for; it exits and clears its own claim |

`bin/driver.sh watch` is the worked example of both.

### The Mac's own scratch is under /tmp, and a reboot takes it

`$RDIR` defaults to `/tmp/maestro-mac`, which macOS clears on boot. Everything
this toolkit keeps there goes with it: the XCUITest runner build, the relay and
helper scripts `driver.sh` copies over, the wall labels, the per-device port map
(item 73) and the rig's claim files (item 76).

That is mostly correct — a reboot takes every driver with it too, so the state
and the things it describes disappear together. What it costs is about 30 s per
device rebuilding the runner, and it presents as a first run rather than as a
reboot. Measured 15 Sep 2026: a session found `/tmp/maestro-mac/` gone after the
Mac came back up, and with it a `relay.py` a previous session had patched by
hand — which is how the IPv4/IPv6 relay bug (item 62) reappeared for an
afternoon. **Nothing worth keeping across a reboot belongs in `$RDIR`.**

The Mac has none of these limits — that is what the next section is about, and
where anything long-running is better placed if it does not need to read this
side's filesystem.

### The Mac is directly addressable — no SSH, no tunnel

Egress goes through the sandbox proxy (`$grpc_proxy`, listening in-namespace on
:3128); there is no route otherwise. What that proxy will reach, probed:

| target | result |
| --- | --- |
| `<mac>.local` over **HTTP** | **connects** — the proxy resolves the name |
| the Mac's LAN address, any port | connects |
| this Linux box's own LAN address | blocked, hangs |
| another machine on the same LAN | blocked, hangs |
| `<mac>.local` over **SSH**, with no `Host` block | fails, "Network is unreachable" |

**Use the name for HTTP and the alias for SSH.** The two take different routes
and behave differently, which is easy to conflate — an earlier version of this
file said flatly "use the IP, never the `.local` name", and that was wrong.

- **HTTP goes through the sandbox proxy.** `curl` reports `remote_ip
  127.0.0.1`: it connects to the proxy, and the *proxy* resolves the name and
  opens the outbound connection. The Mac's name is on its allowlist, so URLs
  should use the name. Measured 0.08–0.23 s, and it follows the Mac
  between networks with no lookup needed on this side.
- **SSH reaches the proxy a different way, and only for the aliases.** `ssh
  <mac>.local` fails outright with "Network is unreachable", because a bare name
  matches no `Host` block and so gets no `ProxyCommand` — and without one there
  is no route at all. The alias blocks in `~/.ssh/config` each carry a
  `ProxyCommand` that tunnels the connection through the same sandbox proxy with
  `socat`, using the numeric address rather than the name. So SSH does go through the proxy; it just cannot find it on
  its own. `reference/setup.md` §3 has the entry and what each part of it does.

So nothing needs to hardcode an address. `MAC_FQDN` in `bin/config.sh` holds the
name for URLs; `MAC_HOST` holds the alias for SSH.

**The two halves do not survive a move equally.** `MAC_FQDN` follows the Mac
between networks because the proxy resolves it. `MAC_HOST` does not: an alias is
a fixed address in `~/.ssh/config`, so a Mac that moves needs a different one.
On 13 Aug 2026 that cost a session — every call failed with `Connection timed
out during banner exchange`, which reads as the machine being asleep rather than
as the wrong route, and was reported as exactly that.

`MAC_HOST` therefore accepts a space-separated list:

```sh
: "${MAC_HOST:=mac-a mac-b}"
```

`_pick_host` in `bin/lib.sh` tries each in order, uses the first that answers,
and caches it in `$LDIR/mac-host` the way `drivers.map` is cached. A single
value is never probed, so nothing changes for a Mac that stays put. Measured:
0.3s for one alias, 9s the first time a list has to step over a dead one, 0.4s
warm. If the cached alias later stops answering, `_ssh` re-picks once rather
than reporting an absence — and only on ssh's own 255 or a timeout, never on a
remote command's own non-zero status, because retrying a tap is worse than
failing one.

Selection has to be a real SSH attempt. A TCP probe would be cheaper but does
not work here: from inside the sandbox `/dev/tcp` fails against *both*
addresses, including the live one. Note too that a new location needs adding to
the sandbox's own network allowlist, or no amount of fallback will reach it. `bin/macip.sh` remains for
the rare case where a numeric address is actually wanted — it asks the Mac
(`ipconfig getifaddr en0`) rather than trusting DNS, which returns *every*
address the name is mapped to regardless of which one is live.

Note also the corollary to your own host being blocked: **a tunnel you open in
your own shell outside Claude is not reachable**, on loopback (different
namespace) or on the LAN address (not on the allowlist).

Verified end to end against a real listener on the Mac:

| | measured |
| --- | --- |
| read via proxy-curl to the Mac's LAN port | **0.050 s** |
| same read over a fresh SSH connection | **0.368 s** |
| first response through the proxy | HTTP 200 in 30 ms |

About 7x per read, with no setup and no teardown.

### Mac-side processes survive our calls

A `nohup`'d listener started in one Bash call answered from the next one —
tested, not assumed. It is the Mac's process, on the far side of the proxy, so
our per-call teardown does not touch it.

That is the whole strategy. Anything that needs to be resident — a Maestro
Studio session, `idb_companion`, a relay — runs detached on the Mac and gets
published on an interface we can already reach.

```sh
curl -s -x "$grpc_proxy" "http://<mac>.local:9100/..."
```

### Publishing a loopback-bound service

The Dart VM Service binds to the Mac's `127.0.0.1`, so it needs republishing on
`0.0.0.0`. Two ways: start the service bound to all interfaces if it supports
it, or relay.

**`socat` is NOT installed on the Mac** — checked. `nc` and `python3` are. Use
`remote/relay.py` (a threaded TCP forwarder), or install socat via brew if you
would rather.

The Mac's firewall is off, which is why binding to all interfaces is reachable
at all. With it on, this needs an exception.

Publishing the VM service on the LAN lets anyone on that network execute code
in the app. Fine for a dev build on a network you control; worth knowing before
it becomes habit.

### What this made possible

Both candidates for a resident driver were tested on 11 Aug 2026:

- **`maestro studio` is gone** — unbundled from the CLI in 2.8.0, desktop app
  only. Not drivable remotely.
- **`idb` / `idb_companion` are not installed** on that Mac.
- **`maestro mcp` is the answer.** An MCP server over stdio, registered as
  `maestro-mac` with `ssh` as its command, so the harness holds one session open
  for the whole conversation. See reference/driving.md for the measurements.

Note the shape: the MCP server sidesteps per-call teardown not by persisting
anything on this side, but because the *harness* owns the process rather than a
Bash call. That is the only kind of residency available here.

## 4. `vmservice.sh` when the simulator log has scrolled past the URI

Measured 20 Aug 2026. `bin/publish.sh` reported
`no VM service found - is the app running in debug?` with a live `flutter run`
attached and the Dart VM Service printed in its own log. The cause: `vmservice.sh`
rediscovered the base URI only from a five-minute window on the simulator system
log, so an app started longer ago than that — every app whose build you sat
through — had scrolled out of it, and the message wrongly blamed the build mode.

**Fixed 11 Sep (item 39).** `vmservice.sh` now looks in the `flutter run` log
first — a file keeps the URI however long ago the app started — and falls back to
the simulator system log only for an app started without a redirected log. It
reads `$FLUTTER_RUN_LOG` (default `/tmp/flutter-run.log`, this skill's own recipe)
and `$FRUN_LOG` (default `/tmp/frun.log`, the hot-reload skill's), tries the most
recent candidate first, and takes the first that answers with a live isolate. The
failure message now distinguishes two things it used to conflate:

- **no URI found in any log** — the app is almost certainly not under `flutter
  run` at all (a `launchApp` or a plain install has no VM service); this is *not*
  a statement about debug vs release.
- **a URI was found but has no live isolate** — the app stopped or restarted since
  it was logged; relaunch it.

`flutter run` prints the URI like this, which is what the log fallback greps:

```
A Dart VM Service on iPhone 16 Pro is available at: http://127.0.0.1:55407/R-KhdenhVwM=/
```

If it still cannot find it, seed the cache by hand on the Mac, then run
`publish.sh` as normal:

```sh
B="http://127.0.0.1:<port>/<token>="        # from the flutter run log, no trailing /
I=$(curl -s "$B/getVM" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["isolates"][0]["id"])')
mkdir -p /tmp/maestro-mac
printf '%s %s\n' "$B" "$I" > /tmp/maestro-mac/vmservice
```

`publish.sh` also used to build the published URI with no host —
`http://:9100/...` — when `MAC_HOST` named more than one alias, because `ssh -G`
was handed the whole list. It now picks the answering alias first (item 39,
item 18).

`publish.sh` then still writes a base URI with no host (`http://:9100/…`), so
substitute the Mac's name into `published.state` before reading the profile.
