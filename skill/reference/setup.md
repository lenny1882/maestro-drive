# Setting this up on a new machine

This page is about the Mac across a network, which is one of the two shapes this
package drives. If the simulator or emulator is on the machine you are sitting
at, read **A device on this machine** below and skip most of what follows.

Everything the skill does happens on the Mac, so a new Linux box needs four
things wired up before any of it runs: a way to reach the Mac over SSH, a way
to reach it over HTTP, an `maestro-mac` MCP server registered with Claude Code,
and the skill itself on disk. `bin/init.sh` covers only the last step —
per-project settings — and assumes all of this already works.

## A device on this machine

`TRANSPORT=local` in `.maestro-drive.conf` means the device is here and nothing
goes over ssh. Six of the ten steps below are then about a machine that is not
in the picture:

| step | locally |
| --- | --- |
| 1. On the Mac | the same checks, on **this** machine: Maestro, Java, python3, and the platform's own toolchain — Xcode for iOS, the Android SDK for an emulator. Remote Login and the firewall exception are not needed |
| 2. The SSH key | **skip.** Nothing connects to anything |
| 3. `~/.ssh/config` | **skip** |
| 4. `/etc/hosts` | **skip.** Every URL the skill builds is `127.0.0.1` |
| 5. Claude Code global settings | the `ssh`/`scp` permission entries are not used; the hooks are |
| 6. Project settings | the same |
| 7. Register the MCP server | the same entry. `bin/mcp.sh` reads the conf and execs `maestro mcp` here instead of over ssh |
| 8. Install the skill | the same |
| 9. Per project | `bin/init.sh --local --detect`, then `--local --app <id> --write`. `bin/install.sh` has nothing to copy and says so |
| 10. Prove it | `bin/preflight.sh`, `bin/wall.sh`, `bin/drivers.sh up` — the ssh and `$grpc_proxy` lines do not apply |

Nobody is sent through `ssh-copy-id` to drive a device that is already here.

**Run end to end once, 21 Sep 2026.** `platform.sh boot`, `devices --booted`,
`install.sh`, `shot.sh`, `prefs.sh`, `net.sh` and `flow.sh` all ran against an
Android emulator on this machine (BACKLOG item 94, 5.2). That run was from
inside a Claude session, so it went through item 96's bridge server rather than
local transport alone. `drivers.sh rig up` was not run, no local iOS simulator
has been driven, and everything outside that list is covered by the test suite
and nothing else. Expect to find things, and write down what you find.

Placeholders below, used consistently — substitute your own and nothing else
needs changing:

| placeholder | is |
| --- | --- |
| `<alias>` | an SSH alias you invent, one per network the Mac lives on |
| `<mac>.local` | the Mac's own name — `scutil --get LocalHostName` on it, plus `.local` |
| `<mac-ip>` | the Mac's address on that network — `ipconfig getifaddr en0` on it |
| `<mac-user>` | the login account on the Mac |
| `<key>` | the SSH key file this uses — `mac_rc` unless you chose another |
| `<java-home>` | wherever step 1 found a JDK — `bin/init.sh` records it as `RJAVA` |
| `<bundle-id>` | the app under test |

## 1. On the Mac

Check each of these before touching the Linux side. Ordinary Terminal on the
Mac:

| what | check | if missing |
| --- | --- | --- |
| Maestro | `~/.maestro/bin/maestro --version` | `brew install mobile-dev-inc/tap/maestro`, or the install script from `docs/pages/maestro-cli__how-to-install-maestro-cli.md` |
| Java | `/usr/libexec/java_home`, or `echo $JAVA_HOME` in the Mac's own shell | any JDK, installed however you like. `java_home` finds one macOS knows about and misses one a version manager keeps to itself — either is fine, because step 9 asks the Mac's login shell and records the answer as `RJAVA` |
| Xcode + simulators | `xcrun simctl list devices booted` | install Xcode, open one simulator |
| python3 | `python3 -V` | ships with the Command Line Tools |
| Remote Login | System Settings -> General -> Sharing -> Remote Login **on** | nothing else works without it |
| firewall | System Settings -> Network -> Firewall | the relays bind to all interfaces; with the firewall on they need an exception |

Two things worth knowing rather than checking:

- **`maestro studio` is gone** as of 2.8.0 — desktop app only, not drivable
  remotely. `maestro mcp` is what replaced it for this purpose.
- **A non-interactive SSH shell has neither Java nor Maestro on `PATH`.** Your
  `.zshrc` is not read. Every remote command has to set both itself, which is
  what `REMOTE_ENV` in `bin/lib.sh` does and why the MCP registration below
  looks the way it does.

## 2. The SSH key

Generate one for this purpose rather than reusing a personal key, and install
it on the Mac:

```sh
ssh-keygen -t ed25519 -N '' -f ~/.ssh/mac_rc -C "maestro-drive"
ssh-copy-id -i ~/.ssh/mac_rc.pub <mac-user>@<mac-ip>
```

`ed25519` because there is no key size to choose and so none to get wrong. An
existing RSA key is fine and does not need replacing — 3072 is strong enough and
the Mac already trusts it.

`-N ''` gives the key an empty passphrase. **Two different things fail
identically here.** Password authentication — the Mac's login password — is not
an option, because every script passes `BatchMode=yes` and a password prompt is
then not a prompt but an immediate failure with no explanation. A *key
passphrase* fails the same way, and `ssh-keygen` asks for one by default, so
without `-N ''` the key is unusable by anything in this package unless
`ssh-agent` is holding it.

No `chmod` needed: `ssh-keygen` creates the private key `0600` already.

`mac_rc` is only a name; use another if you prefer. Nothing stores the path —
the `IdentityFile` line in the `Host` block below is the record.

`ssh-copy-id` authenticates with the Mac's **login password**, prompted at your
terminal; `-i` only names the key to copy. It will not work from inside a Claude
session — run it in your own terminal, where the network is unrestricted. Once
per machine, not per network: `authorized_keys` is one file on the Mac whatever
address reaches it.

## 3. `~/.ssh/config`

This is the part that carries the routing, and it is not obvious. Inside the
sandbox every Bash call gets its own network namespace with no routes at all —
the only way out is the sandbox's HTTP proxy, on `localhost:3128`, with
credentials in `$grpc_proxy`. SSH has no idea about any of that, so the config
tunnels it through the proxy with `socat`:

```
Host <alias>
	Hostname <mac-ip>
	User <mac-user>
	IdentityFile ~/.ssh/<key>
	ConnectTimeout 15
	ServerAliveInterval 30
	ProxyCommand sh -c 'if [ -n "$grpc_proxy" ]; then A=$(printf "%%s" "$grpc_proxy" | sed -e "s|^http://||" -e "s|@.*||"); exec socat - PROXY:localhost:%h:%p,proxyport=3128,proxyauth=$A; else exec nc %h %p; fi'
```

One block per network, identical but for the `Hostname`, and named for the
place rather than the machine — the alias is what you type, and which one works
depends on where the Mac is, not what it is.

Reading that `ProxyCommand`:

- `$grpc_proxy` is set inside the sandbox and unset outside it, so the same
  entry works in both places: tunnel when sandboxed, plain `nc` when not. Do
  not split it into two aliases.
- The `sed` strips `http://` and everything from `@` onwards, leaving
  `user:password` for `socat`'s `proxyauth`.
- **`%%s` is deliberate.** `ssh_config` expands `%` tokens itself, so a literal
  percent must be doubled. `%h` and `%p` are ssh's own host and port
  substitutions and stay single. Retyping this by hand usually gets that wrong;
  copy it.
- `socat` and `nc` must be installed on the Linux box — on Debian/Ubuntu,
  `apt install socat netcat-openbsd`.

**The `Hostname` is a numeric address, and there is no single name that works
for SSH.** `ssh <mac>.local` matches no `Host` block, so it gets no
`ProxyCommand`, tries to connect directly, and fails with "Network is
unreachable". That is why `MAC_HOST` in a project conf must be an alias and
never a hostname.

Verify, from a Claude session as well as your own terminal — they take
different routes and only the first one proves the sandbox path:

```sh
ssh -o BatchMode=yes <alias> 'scutil --get LocalHostName; sw_vers -productVersion'
```

Expect a name and a version in well under a second. `~/.ssh/known_hosts` is
writable from inside the sandbox, so the first connection records the key
normally and nothing needs `StrictHostKeyChecking` beyond the `accept-new` the
scripts already pass.

## 4. `/etc/hosts`

HTTP takes the other route: `curl` connects to the sandbox proxy, and the
**proxy** resolves the name and opens the outbound connection. The proxy runs
outside the sandbox, so it uses the host's `/etc/hosts`. Without these lines
the name does not resolve and every HTTP call fails, even though SSH is fine:

```
# mac for ios simulator work
<mac-ip-on-network-1> <mac>.local
<mac-ip-on-network-2> <mac>.local
```

Both, deliberately. The resolver returns both addresses and the client tries
them in turn, so the same name follows the Mac between networks with nothing to
change. It also means a lookup always "succeeds" with one dead address in the
list — a slow first connection that then works is this, not a fault.

**File order is try order.** Every address ahead of the live one costs a full
connect timeout before anything happens, so put the network you are on most
often first. With three networks listed, being on the third is two timeouts on
every first connection.

Nothing in the skill hardcodes an address. `MAC_FQDN` holds this name for URLs;
`bin/macip.sh` asks the Mac directly (`ipconfig getifaddr en0`) on the rare
occasion a number is actually wanted.

## 5. Claude Code global settings

`~/.claude/settings.json`. The network entry is the one that matters — without
it the proxy refuses the connection and the Mac looks like it is switched off:

```json
{
  "sandbox": {
    "enabled": true,
    "network": {
      "allowedDomains": ["<mac>.local", "<mac-ip-on-network-1>", "<mac-ip-on-network-2>"]
    }
  }
}
```

List the name **and** both addresses. The name covers `curl` through the proxy;
the addresses cover the SSH tunnel, which asks the proxy for a numeric host
because that is what the `Host` block's `Hostname` says.

Add a new address when the Mac joins a new network, in three places at once:
here, `/etc/hosts`, and a new `Host` block in `~/.ssh/config`. All three or none
— two out of three produces a failure that looks like something else.

**The journeys-first hook.** The skill ships a `PreToolUse` hook that blocks a
raw `driver.sh tap`/`swipe` on literal coordinates **once per session** and
names the journeys to run instead — the one habit the user has policed by hand
across five-plus sessions. It is a nudge, not a ban: re-run the same command and
it passes.

`install.sh` registers it (§ 8), so there is nothing to paste. What it writes is
a **second** `Bash` matcher under `hooks.PreToolUse`. If the machine already
has one — this hook was developed beside an unrelated `gate-unsandboxed-bash.sh`
— both fire. They are deliberately not merged into one entry: merging makes them
ordered and couples two packages that know nothing about each other.

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash ~/.claude/skills/maestro-drive/hooks/gate-journey-first.sh"
    }
  ]
}
```

`bash <path>` rather than the path alone is deliberate and matches the
neighbouring entry: the sandbox refuses `chmod +x` under `~/.claude`, so the
script cannot be relied on to carry its exec bit. The path is absolute and
resolved at install time, and it points into the installed skill, so the hook
follows the skill and dies with it — it only ever fires on a command containing
`driver.sh`, this skill's own binary. To skip the gate, delete the entry after
installing, or run `./uninstall.sh` and install nothing; a missing or
unreferenced script does nothing.

### `rig-down-on-end.sh` — SessionEnd

Takes down the simulators **this session booted** when the session ends, and
nothing else. Without it, every ending that is not a tidy one leaves a simulator
booted, its driver running and its name on the wall — and since nothing else
clears a label, the next session cannot tell that name from one somebody set by
hand and inherits it (BACKLOG item 67).

```json
"SessionEnd": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/skills/maestro-drive/hooks/rig-down-on-end.sh"
      }
    ]
  }
]
```

`SessionEnd` takes no matcher. The hook detaches its work and exits 0
immediately, so closing a terminal never waits on an SSH round trip and never
reports an error. In a project that has never driven anything it costs nothing:
with no `.maestro-drive.conf` and no claim file there is nothing to take down.

**Both hooks ship with the skill and both are registered for you.** They live in
the repo's `skill/hooks/`, and `install.sh` puts the whole `skill/` directory at
`~/.claude/skills/maestro-drive`, then writes the two blocks above into
`settings.json` with the resolved path.

That reverses an earlier decision to register neither, on the grounds that both
change what happens in *every* session and so belonged to the machine rather
than the skill. The argument was sound and the result was that
`rig-down-on-end.sh` sat unregistered from 17 Sep, which is exactly the
situation it exists to prevent. A skill whose hooks need a hand-edit of
`settings.json` is not one step to install.

Both blocks are shown above so you can recognise them. `./install.sh --dry-run`
prints the diff before writing, `settings.json` is copied to
`settings.json.bak-maestro-drive` first, and `./uninstall.sh` removes both
entries — it finds them by the `maestro-drive` in their path, so an entry
you have since edited by hand is still removed as long as the path survives.

## 6. Project settings

`.claude/settings.local.json` in whatever project you drive from. Without these
every single call waits for a permission prompt, which makes a 34-step journey
unusable:

```json
{
  "permissions": {
    "allow": [
      "Bash(ssh <alias-prefix>-*:*)",
      "Bash(scp <alias-prefix>-*:*)"
    ]
  }
}
```

Give the aliases a common prefix and one wildcard covers them all and nothing
else. Add `Bash(curl -s -x * http://<mac>.local:*)` if you also want the HTTP
calls silent; `bin/driver.sh` makes one per action.

## 7. Register the MCP server

`bin/driver.sh` is the fast path, but the XCUITest driver it talks to only
exists while something holds a Maestro session open — in practice, this server.

`install.sh` registers it (§ 8). It lands in `~/.claude.json` as:

```json
"maestro-mac": {
  "type": "stdio",
  "command": "bash",
  "args": ["/home/<you>/.claude/skills/maestro-drive/bin/mcp.sh"]
}
```

The path is absolute and resolved at install time. **Claude Code does not expand
a leading `~` in an `mcpServers` command or argument** — it reaches `exec`
unexpanded and the server fails to start at every session, reported only as a
server that would not connect. `${HOME}` is expanded, but a resolved path is
true either way. `bash` with the script as an argument, rather than the script
as the command, for the same exec-bit reason as the hooks.

`~/.claude.json` is not `settings.json`: it also holds your project records and
login state. The installer writes a temp file beside it and renames it rather
than rewriting it in place, and keeps `~/.claude.json.bak-maestro-drive`.
Claude Code writes that file itself while it is running and concurrent writes
are a known way to corrupt it, so install from a terminal with no session
running where you can.

To register it by hand instead:

```sh
claude mcp add --scope user maestro-mac -- bash ~/.claude/skills/maestro-drive/bin/mcp.sh
```

`bin/mcp.sh` sources `lib.sh`, picks the right SSH alias from
`.maestro-drive.conf` (trying each in turn, the same way every other script
does), and execs the SSH connection to `maestro mcp`. The MCP config names the
script and nothing else — a new network only has to be added to
`.maestro-drive.conf`, not to the MCP entry separately.

The old form — a bare `ssh <alias> ...` in the args — hardcoded one alias and
broke whenever the Mac moved to a different network. If you have that, running
`install.sh` replaces it: the entry is keyed on the name `maestro-mac`, so the
old value is overwritten rather than sitting alongside.

Three things the launcher handles that the old form had to get right:

- **`ssh` is the transport.** Maestro is not installed on this machine. The
  server runs on the Mac and speaks stdio down the SSH connection.
- **`PATH` and `JAVA_HOME` are set** from `lib.sh`'s `REMOTE_ENV`, because the
  shell SSH gives you has neither — it reads no `.zshrc`, so whatever a version
  manager sets there is invisible. `JAVA_HOME` is the conf's `RJAVA`, which
  `bin/init.sh` got by asking the Mac's own login shell. Without these the
  server exits immediately and the tools appear as "failed to connect" with no
  further detail.
- **The keepalives matter.** Without `ServerAliveInterval` the connection dies
  silently during a long think and the next tool call fails.

Restart Claude Code after installing — a settings reload picks up the hooks,
but the MCP server is only read at start — then confirm `list_devices` returns
your simulator.

## 8. Install the skill

From the newest release, with no clone:

```sh
curl -fsSL https://github.com/lenny1882/maestro-drive/releases/latest/download/maestro-drive.tar.gz | tar -xz
cd maestro-drive && ./install.sh
```

Or from a checkout, if you intend to work on the toolkit itself:

```sh
git clone https://github.com/lenny1882/maestro-drive && cd maestro-drive
./install.sh --link
```

`--link` symlinks `skill/` in place of copying it, so edits to the checkout are
live and nothing you write under `~/.claude/skills/maestro-drive` is lost
to the next install. Claude Code follows the symlink. Either way the installer
ends by resolving an element out of a captured hierarchy, so an install that
landed but cannot run says so rather than reporting success.

`~/.claude/skills` is **not writable from inside a Claude session** when the
sandbox is on, so run the installer in your own terminal. New sessions pick the
skill up; the current one does not.

Re-running `./install.sh` is how you upgrade, and `./update.sh` fetches the
newest release and re-runs it for you.

## 9. Per project

Only now does `bin/init.sh` apply. For a device on this machine it is
`--local` instead, and the two flags that name a Mac are refused rather than
ignored:

```sh
cd <the project you drive from>
~/.claude/skills/maestro-drive/bin/init.sh --local --detect
~/.claude/skills/maestro-drive/bin/init.sh --local --app <bundle-id or applicationId> \
    --repo <checkout here> --write
```

Across a network:

```sh
cd <the project you drive from>
~/.claude/skills/maestro-drive/bin/init.sh --detect                 # aliases here
~/.claude/skills/maestro-drive/bin/init.sh --host <alias> --detect  # sims, apps, checkouts
~/.claude/skills/maestro-drive/bin/init.sh --host <alias> \
    --fqdn <mac>.local --app <bundle-id> \
    --repo <checkout on the Mac> --write
```

The second command also lists the git checkouts under the Mac's home directory
and marks the one whose `origin` is the same repository as the directory you
ran it from — `git@host:org/thing.git` and `https://host/org/thing` are reduced
to `host/org/thing` first, so the two forms match. A checkout that only shares
the directory name is marked as such rather than treated as the answer; two
repositories can be spelt the same and only one of them is yours. On a Mac with
twelve checkouts it takes about three seconds, which is one SSH call rather
than the three session B spent guessing at `~/src`, `~/Development` and
`~/Projects` by hand.

That writes `.maestro-drive.conf` and creates `maestro/journeys/` and
`maestro/app-notes.md`. Then, once per machine, push the Mac-side helpers:

```sh
~/.claude/skills/maestro-drive/bin/install.sh
```

## 10. Prove it, in order

Each step depends on the one above it, so stop at the first failure rather than
carrying on.

```sh
ssh -o BatchMode=yes <alias> 'echo ok'                       # 2, 3
curl -s -x "$grpc_proxy" -o /dev/null -w '%{http_code}\n' \
     http://<mac>.local:9990/                                # 4, 5 (404 is fine; a hang is not)
bin/preflight.sh                                             # 6, 9
bin/wall.sh                                                  # prints the URL to post
bin/drivers.sh up                                            # a driver per simulator
bin/drivers.sh && bin/driver.sh find "." | head              # 1, everything
```

Step 7 (the MCP registration) is only needed for real Maestro flows —
`bin/drivers.sh` starts its own drivers and does not use the server. Check it
separately with `list_devices` in Claude.

## What breaks, and what it actually means

| symptom | cause |
| --- | --- |
| `Network is unreachable` from ssh | no `Host` block for that name, so no `ProxyCommand` — use the alias |
| ssh hangs, then times out | wrong alias for the network the Mac is on; try the other one |
| ssh asks for a password | the key is not on the Mac. With `BatchMode=yes` this reads as a plain failure |
| `socat: command not found` | install `socat` on the Linux box (Debian/Ubuntu: `apt install socat`) |
| curl hangs on `<mac>.local` | missing from `allowedDomains`, or missing from `/etc/hosts` |
| MCP tools "failed to connect" | `PATH`/`JAVA_HOME` missing from the registration, or Maestro not installed on the Mac |
| MCP worked, now every call fails | a `maestro` CLI run took the driver. Reconnect the server; nothing else recovers it |
| `no driver listening on <port>` | no driver for that device — `bin/drivers.sh up [udid]` |
| `git fetch` on the Mac fails with `Permission denied (publickey)` | the Bitbucket key exists but is not offered in a non-interactive session. Set `core.sshCommand` on the repo: `git config core.sshCommand 'ssh -i ~/.ssh/bitbucket -o IdentitiesOnly=yes -o BatchMode=yes'` — or add a `Host bitbucket.org` block with `IdentityFile` to the Mac's `~/.ssh/config` |
| `CocoaPods is installed but broken` | it is under a different Ruby. `bin/build.sh --detect` finds it and reports the `GEM_HOME` a build needs |
| `flutter: command not found` on the Mac | the repo pins its SDK with fvm and nothing is on `PATH`. `bin/build.sh --detect` names the pinned one |
| `Target file "lib/main.dart" not found` | the project is flavoured. `bin/build.sh --detect` works out which flavour builds `APP_ID` |
| a read or tap goes to the wrong simulator | an MCP call or a CLI run rebuilt that device's driver on 22087. `bin/drivers.sh` shows where each one is now |
| MCP returns the wrong device's screen | it always serves the device on 22087, whatever `device_id` it is given. Use `driver.sh` with `DEV` |
| every Bash call prompts for permission | project `settings.local.json` missing the `ssh mac-*` allow |
| the skill does not appear | the symlink was made after the session started, or made from inside the sandbox and silently failed |
