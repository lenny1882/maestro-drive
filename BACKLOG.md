# maestro-remote-mac — backlog

One item remains — 87 — and it is not gated. **17 is done** — the package has a git
repo, a version, a manifest, an installer and an update path. That releases
**28**, which waited on it and is now the only decision left in this file.

**70–82 were raised on 17 Sep** by an audit of the fourteen simulator-driving
sessions of 15 and 16 Sep (PROJ-1812/1811 reproduction and fix verification).
They are the first items to come out of *driving at scale* — four or five
simulators, two live sessions on one Mac, and an observation that had to run for
hours. **73, 74 and 75 are the multi-device failures**; 80–82 are conduct with a
skill change behind them.

**70, 71 and 72 were built the same day and are in `BACKLOG-DONE.md`.** 70 was
the item that cost those two days — `driver.sh watch`, built on 72's `rows` and
71's detached-work rules, verified live on an iPhone the same afternoon. **69 is done and
shipped.** Its route fix is in `skill/bin/driver.sh` and in the v1.0.0 tarball,
and the isolation its fold asked for was run on 18 Sep, which found the cause:
`/swipe` does not rotate its coordinates and `/swipeV2` does, so on a landscape
iPad a v1 swipe lands off the view and is answered 200.

**74 is done and it came back with the opposite of what it claimed.** A device
budget is not the fix: seven simulators idle with the wall up sit at load 6,
while booting **one** more takes the Mac to 122 in 36 seconds. The failure is a
boot storm, not a crowded machine. That makes serialised boots a hard
requirement on item 76 rather than a preference.

**73 and 76 are done.** Ports are pinned per device in a map on the Mac, and
`drivers.sh rig up|down|status` brings several simulators up as one — serialised
boots per 74, and a teardown scoped to what this session booted. **67's
`SessionEnd` piece is now closed.** The hook is in
`skill/hooks/rig-down-on-end.sh`, and `install.sh` registers it rather than
leaving the `settings.json` entry as the machine's step — that reversal is the
whole point: the hook sat unregistered from 17 Sep, which is the failure it
exists to prevent. **67 is closed.** Piece 4 — what a label with no live session
looks like — was decided and built on 17 Sep: `remote/wall.py:96` sets
`HIDE_FROM_PREVIOUS_DAY` and `:136` applies it, so a name from an earlier
calendar day is not shown and the tile falls back to the handset.

**Nothing from the earlier run is still open here.** 75, 77, 78, 79, 80 and 81
are done, and 67 and 69 are closed — see their entries in `BACKLOG-DONE.md`.
**28 is done for everything this repository controls**; the four deletions it
listed are in the pre-repo working directory and are not this package's to make.
**82 is closed here and owned by `flutter-hot-reload-mac` item 16** — the fix is
a hook on that skill's entry points, so nothing in this package was ever going to
change for it.

**Where the toolkit now lives.** Item 17 moved it into its own git repo — the
one this file is in — where `src/` became
`skill/` and the root carries the installer, `manifest.sh`, `VERSION` and
`update.sh`. `build/` and `ship.sh` are superseded and were left in
`~/claude-sandbox/maestro-remote-mac/`, source of truth for nothing; the four
things in that directory that were stored nowhere else —
`MAESTRO-REVIEW-TRACKER.md`, `HANDOFF.md`, `flutter-router-dropdown-repro/` and
`remote-STALE-pre-skill/` — are now in this repo's root.

**Nothing from 17 Sep is live.** The old `~/.claude/skills/maestro-remote-mac`
symlink into `build/` was removed when the package was uninstalled, so there is
no installed skill at all until `./install.sh --link` is run from the repo.
Everything built on 17 Sep is in `skill/` and comes with it.

68 was raised and done on 16 Sep — the wall's tiles no longer overflow their
cards — and 64, 65 and 66 were done on 15 Sep. All four are in
`BACKLOG-DONE.md` with the rest of the history of all 68 earlier items.

**85 is done, on 18 Sep.** It was the first item about setting the skill up
rather than running it, and exercising it cost an afternoon and found eight
faults — eight in the wizard, one of them a wrong conclusion drawn in its own
comments, and one found only by asking what a fresh Mac would do. Nearly every one showed as the same sentence, a connection closed
during the banner exchange, which named none of them. Phases A, B and C have
now run live end to end against the real Mac, including the `sudo` install and
the Wi-Fi cycle, and the `--remove` round trip ran on the real three files.

**86 was raised and fixed on 18 Sep** — the suite went red with no code
change, on a test that was only correct when it was not shortly after midnight.
It is in `BACKLOG-DONE.md`.

**87 was raised on 18 Sep**, the first item about what this package is *for*
rather than how it works. With 85 done it is the only item left open in this
file.

**Next item number: 93.** Items 1–92 are allocated; new items start from 93.

**Two commits on `backlog/87-runner-modules` carry the wrong item number.** They
say `BACKLOG 88` and `BACKLOG 89`, and both of those were already allocated and
done — 88 is the rig-reap item, 89 is `wall.sh label` swallowing its flags. The
work in them is real and is now filed as **91** and **92** below. The commit
messages are left alone rather than rewriting the branch's history for a label.

---

## 90. The wall shows simulators only, and a phone is a device too — **OPEN, raised 18 Sep**

`bin/wall.sh` puts every booted simulator on one page, live, and it is the first
thing a session starts. A physical iPhone driven through `runners/ios-device` is
invisible on it — so the one device whose screen you cannot see from your chair
is the one the wall does not show.

**Two things stand in the way, and only the second is hard.**

**The wall asks ONE platform module.** `remote/wall.py` resolves
`runners/<PLATFORM>/platform.sh` from the environment and calls `devices
--booted` on it. A Mac with three simulators and a phone has two platforms live
at once, so the wall would have to ask every module it can find and merge the
answers, tagging each row with the module that produced it. That is a small
change and a real one: it is the first place in the package where the two axes
stop being "one choice per session".

**Nothing is known to stream a physical device's screen.** `runners/ios-device
capture-cmd` exits 2 saying exactly that, and it is not a gap to be filled by
guessing. What is known, measured 18 Sep 2026:

  `devicectl device capture screenshot` works on the phone — 6.7MB PNG, about a
  second. That is a poll, not a stream.
  `devicectl device capture screen-record` exists and records to a FILE, which
  is the wrong shape for a tile that has to start before anyone is watching and
  survive the browser going away.
  Whether Maestro's `simulator-server` binary drives a physical device at all is
  unestablished. It takes a platform word — `ios` for a simulator — and nobody
  has tried another.

So the first question is whether a phone can be streamed or only sampled. If
only sampled, the wall's Stream class assumes MJPEG frames arriving from a
child process, and a polled tile is a different thing living beside it rather
than a parameter of it — a phone tile that updates every few seconds is still
worth having, and saying so in the tile is better than a still frame that looks
live.

**Gated on:** nothing in this package. It is gated on finding out what can
stream a phone.

**Related.** Item 87 built `runners/ios-device` and left `capture-cmd`
unanswered for this reason.

## 91. A live driver stopped protecting a peer's wall label — **DONE 18 Sep 2026**

Found by the first live `rig up` after item 87's Stage 3, which printed
`awk: backslash not last character on line`.

The live-driver guard in `_wall_label` is a `$( )` inside a double-quoted `_ssh`
string, so the LOCAL shell expands it and the awk runs here. Its field
references were escaped as `\$1` and `\$2`, as though it ran on the Mac, so awk
died and the substitution came back empty — making the test always false.

One of the three guards on reclaiming another session's label has therefore
never worked. Only the age check stood, and a peer whose label was older than
`LABEL_STALE_AFTER` would have been renamed out from under a live session, which
is the exact failure item 67 added that test to prevent.

The tests did not catch it because they reimplement the reclaim in shell and
test the intended logic rather than the shipped string, and because a recent
label is kept by the age check whether or not this guard fires. The new test
reads the file.

## 92. Three wrong-shell mistakes across the SSH boundary — **DONE 18 Sep 2026**

Item 91 was found by accident, so this searched for the rest of its family
rather than waiting for the next one. Three shapes:

  **a local `$( )` escaped as though remote** — item 91 was the only instance.

  **a POSIX helper sourced into the shell ssh hands over, which is zsh.**
  `remote/gitstate.sh` had two constructs zsh does not share — it neither
  word-splits an unquoted expansion nor globs an unquoted `case` pattern — and
  reported every lock file as somebody's work for as long as it was
  parameterised. `remote/appcheck.sh` was the same shape and survived on luck.
  Both are executed with `sh … --run` now and zsh is out of the path.

  **a pipe eating an exit status**, three times. `sh module inspect … | tail -1`
  on the remote side returned tail's status, so an exit 2 arrived as success.
  `bin/flow.sh` ran `maestro test | grep | tail`, so EVERY FLOW REPORTED
  SUCCESS — and the first fix for it was itself incomplete, because flow.sh then
  ended on `if [ -n "$SHOT" ]`, whose false condition exits 0.

The lesson the tests carry now: read the shipped file, do not model it. Two of
these passed a test that checked the intent.

---

## 85. SSH and network setup is seven manual steps across three files that must all agree — **DONE 18 Sep 2026; A, B and C all run live end to end, and the nine faults that took**

`reference/setup.md` describes the whole SSH and network side and a person does
it by hand. It is correct and it still gets done wrong, because it spans three
files that must agree and is read once, at the wrong moment. A wizard should do
it instead.

**Seven parts.**

1. **Key creation.** `ssh-keygen` for a purpose-built key, not a reused personal
   one. Every script passes `BatchMode=yes`, so a passphrase prompt fails
   immediately with no explanation — and note that is a *key passphrase*, a
   different thing from the password authentication `reference/setup.md:55` warns
   about, which fails the same way. Neither setup.md nor this item said the key
   must be made with `-N ''`. **Drift found 17 Sep**: setup.md documents
   `-t rsa -b 4096 -C "maestro-remote-mac"`; the key actually in use is RSA 3072
   with a default comment, so the documented command was not followed when the
   key was made — which is this item's own argument.

2. **Getting the key onto the Mac.** `ssh-copy-id -i <key>.pub <user>@<addr>`
   authenticates with the Mac's *login password*, prompted on the terminal — the
   `-i` only names the key to copy. That is the one moment the Mac's password is
   typed, so the wizard runs the command in the foreground and lets ssh prompt
   from `/dev/tty`. It must not capture the output, must not pass `BatchMode=yes`,
   and must not background it. Runs **once per machine**, not per network:
   `authorized_keys` is one file on the Mac whatever address reaches it.
   Preconditions worth naming rather than eyeballing (setup.md § 1 lists Remote
   Login as a checkbox): refused on 22 is Remote Login off, timed out is the
   wrong address or the wrong network.

3. **`~/.ssh/config`.** One `Host` block per network, identical but for the
   `Hostname`, named for the place rather than the machine, each carrying the
   socat `ProxyCommand` that tunnels through the sandbox proxy. **One trap, not
   two**: `%s` must be doubled because ssh_config expands `%` itself. The
   `ConnectTimeout` ordering belongs to `bin/lib.sh:69-80`, where `_probe`
   prepends its own value ahead of `SSH_OPTS`, and is already solved there —
   command-line `-o` beats the config file whatever order the file is in, which
   also makes the blocks' own `ConnectTimeout` and `ServerAliveInterval` dead for
   everything going through `bin/`. Merge-not-replace with a backup: it is the
   user's file, with fourteen commented-out entries for unrelated hosts.
   Ownership is matched on `Host <alias>`, with no marker comment — the need is
   only to avoid a duplicate stanza, which `ssh` silently shadows because it
   takes the first value it obtains for each keyword.

4. **`/etc/hosts`.** One line per network mapping `<mac>.local` to that
   network's address, all present at once: the resolver returns them all and the
   client tries each in turn, so the name follows the Mac. The cost is that two
   of three are dead on any given network and each one is a connect timeout
   before the live one answers — file order is try order, so the network used
   most often belongs first. Needs root, so the wizard **asks whether to write it
   itself, defaulting to no**, and prints the lines otherwise. The existing block
   is already marked by `# mac for ios simulator work`, which is the region the
   wizard owns.

5. **`~/.claude/settings.json` → `sandbox.network.allowedDomains`.** The name AND
   every address. Without it the proxy refuses and the Mac reads as switched off
   while SSH still works, which is what makes the failure confusing. Union, never
   replace — the array may hold entries for unrelated tools — and the
   `sandbox.network` path may not exist at all. `jq` is already a hard dependency
   (`install.sh:51`), and `install.sh:97-108`'s write-to-temp, `diff`, move
   pattern is what to copy, diff preview included.

6. **Per project — not the wizard's. Both halves now covered.**
   `.maestro-mac.conf` is already covered by `bin/init.sh`, which `bin/config.sh`
   routes into when no conf is found. The permission allows are the uncovered
   half. `reference/setup.md` § 6 documents them, wildcard prefix and all — what
   was missing is that nothing writes them and nothing checked whether they were
   there, so every `ssh` and `scp` waits for a prompt until someone reads § 6 or
   adds them by hand.

   **Built 17 Sep in `bin/config.sh`, not a hook.** It sits immediately after the
   conf check, which is the same moment and before any SSH happens. Read `permissions.allow` from `~/.claude/settings.json` and the
   project's `.claude/settings.local.json`, strip `Bash(…)` and a trailing `:*`,
   and glob-match the patterns against the real `ssh <host>` and `scp <host>`
   command strings for every alias in `MAC_HOST`. Print what is uncovered, once
   per session, marked in `$LDIR`. Block nothing. Detection only: a shell script
   cannot write either settings file, so the session asks which file the user
   wants and writes it with `Edit`. Global counts for every project;
   project-local means being asked again in the next project, which is intended.

   **Not a hook, and the reason matters.** A hook was the first design. It cannot
   write the settings file either, so its only advantage over `config.sh` was
   imaginary — while it would fire on every Bash call for the life of the machine
   to test a condition true once per project, and would need a third registration
   in `install.sh`. See item 67 for how a registration goes missing.

   **Verified against five cases**: nothing configured anywhere warns and names
   both files; a wide `Bash(ssh mac-*:*)` in the global file silences it; a
   project file covering one alias reports only the uncovered one; a second
   call in the same session is silent; and a malformed `settings.json` is
   survived rather than crashing the skill on load.

   **Two findings from the first attempt, which was written, tested and reverted.** The
   suggested entry should use the longest common prefix of the aliases, not the
   first alias: `mac-a mac-b` gives `Bash(ssh mac-*:*)`, which is exactly
   what the two projects on this machine already have by hand, whereas per-alias
   suggestions produce an entry that does not match. And this machine's `python3`
   is **3.8.10**, so `str.removesuffix` is unavailable and the suffix strip is
   manual — worth checking what else under `skill/` assumes 3.9+.

   **State on this machine.** `~/.claude/settings.json` has no `ssh` or `scp`
   allow at all. the client checkout and `claude-sandbox` each carry
   `Bash(ssh mac-*:*)` and `Bash(scp mac-*:*)` in
   `.claude/settings.local.json`, identical and duplicated by hand.

7. **The two Mac-side pieces that handle a network change.** Not an Automator
   script — that guess was wrong. It is `/usr/local/bin/network-change.sh`
   (root:wheel 755, 242 lines) driven by `/Library/LaunchDaemons/networkChange.plist`,
   label `com.you.networkchange`, which fires on `WatchPaths` over
   `/var/run/resolv.conf`, `NetworkInterfaces.plist` and
   `com.apple.airport.preferences.plist` plus `RunAtLoad`, logging to
   `/tmp/netchange.log` and `/tmp/netchange.err`. The script applies a per-SSID
   IPv4 profile to the Wi-Fi service and is idempotent, because WatchPaths fires
   two or three times per real change.

   **The script half is vendored** at `skill/setup/network-change.sh` — three
   real SSID blocks cut to one example on `192.0.2.0/24`, plus a header covering
   what each value means, the Terminal commands that find them on the Mac, and
   how to check the result. Body is byte-identical to the Mac's from the config
   block down. The real table is the LAN layout of every network the Mac joins,
   so it stays local: the wizard writes it, the repo never carries it. **The plist
   is vendored verbatim** at `skill/setup/networkChange.plist` — 837 bytes, six
   keys, no site-specific values in any of them, so it needs no redaction and
   installs as-is.

   **Optional, and last.** It exists to give the Mac a fixed address per network.
   Anyone whose router does DHCP reservations gets the same result with nothing
   installed on the Mac. Offered only after a new network is added, never on its
   own.

   **How the path was recovered, and why it nearly wasn't.** Nothing in the repo
   or in any surviving transcript names these files. A sweep of all 246
   transcripts returned a clean negative — but 417 of 577 sessions no longer have
   a transcript at all, pruned on the rolling 30-day `cleanupPeriodDays` window
   (nothing before 19 Aug survives), and both sessions that set this up (10–11
   Aug) were among them. The path survived only in `~/.claude/history.jsonl`,
   which the window does not touch, in a prompt from 11 Aug 11:03. **Two defects
   found on reading it**: the third SSID's DNS server and its gateway differ by
   one digit, which reads as a typo; and `current_ssid()` calls
   `ipconfig sertverbose 0`, misspelt, so the verbose mode the function turns on
   is never turned off. The second is fixed in the vendored copy; both are still
   live on the Mac.

**Design, settled 17 Sep. Two phases and an optional third.**

**Phase A — once per machine.** Ask the Mac's username and its `.local` name.
Ask for an existing key path or create one: `ed25519` for a new key, no check on
an existing one's type, because the Mac already trusts an RSA key. Print and run
`ssh-copy-id` in the foreground; verify with `BatchMode=yes`. **There is no
stored key path** — the `IdentityFile` line in the `Host` block is the record,
and a later pass reads it back. `known_hosts` cannot serve: it holds the Mac's
host key, not this machine's identity.

**Phase B — once per network, repeatable.** Ask the place name and the Mac's
address on that network, then write the `Host` block and the `allowedDomains`
entry. Both are needed *during* phase C, so they are written with the DHCP
address first and corrected afterwards if C moves it.

**Phase C — optional, offered only when a new B completes.** Install
`network-change.sh` and the plist on the Mac, which needs root there and so is a
printed command the user runs, as in part 2. Discovery runs live on the Mac:
SSIDs offered as a list from `networksetup -listpreferredwirelessnetworks en0`
plus the current one, and mask, gateway and DNS read from `networksetup -getinfo`
and `netstat -rn`. **The static address defaults to the Mac's current address
with the last octet replaced by `250`** — which reproduces all three already in
use, including the /22 where the mask differs — asked rather than assumed, and
refused if it answers `ping`. It must sit outside the router's DHCP pool, which
the Mac cannot see, so the wizard cannot derive it.

**`/etc/hosts` is written last**, once the address is final, whether or not C
ran. It is the only one of the three that can wait: SSH uses the `Host` block's
literal `Hostname` and the proxy needs the address in `allowedDomains`; only
`curl` on the `.local` name needs `/etc/hosts`.

**C drops the connection it runs over**, by design. The last command before the
drop cycles Wi-Fi, detached so SIGHUP does not kill it mid-cycle:

```sh
ssh <alias> 'nohup /bin/sh -c "sleep 2; \
  networksetup -setairportpower en0 off; sleep 5; \
  networksetup -setairportpower en0 on" >/dev/null 2>&1 </dev/null &'
```

The leading `sleep 2` lets ssh return an exit code rather than a broken pipe.
Note `RunAtLoad` already applies the profile on `launchctl load` — the cycle
proves the `WatchPaths` trigger fires, which is the part that must work
unattended.

**Tested live 17 Sep, 23:07.** Four results:

- **`networksetup -setairportpower` needs no sudo**, to read or to set. Exit 0 as
  the ordinary user. That was the last unverified point in phase C.
- **The detached form survives the drop.** The `nohup … &` above returned exit 0
  and the `off`/`on` pair completed after the connection died.
- **One cycle fired the daemon three times** — 23:07:09 not associated, 23:07:18
  and 23:07:28 both `already static … no change`. Exactly the "2-3 times per real
  change" its own header predicts; the lock and the idempotence check absorbed
  it, nothing was written and `/tmp/netchange.err` stayed 0 bytes.
- **Recovery took 19 seconds** end to end. The two-minute poll is slack.

**The poll must wait for the drop before waiting for recovery.** A poll started
immediately succeeds on the connection it is about to lose — observed: the first
attempt returned "up" one second in, before the `sleep 2` had elapsed, which
reads as success and is not. Wait for a failure first, then for the recovery.

**Re-runs of phase A assume the Mac is reachable, but a failure does not prove
it is not.** Compare this machine's current network against the addresses
already stored; if it matches one, ask whether the Mac is on and reachable.
Regardless of the answer, ask whether to set up a new network — that is the
common reason for a re-run, and the Mac may be on a network this machine has
never seen. Reachability is therefore phase B's question about a specific
address, never phase A's about the machine.

**Before any command that needs the Mac**, say plainly that the Mac must be
turned on and joined to the network being configured. Phase C can only discover
the network the Mac is currently on.

**Where it lives.** `skill/setup/wizard.sh`, so it installs with the skill and
can be re-run months later without the repo on the machine. `install.sh` calls
it, and checks a **phase A completion marker** in
`~/.local/share/maestro-remote-mac/` — where `install.sh` already points
`LIB_DIR` — offering the wizard when it is absent. A flag, not a state file:
networks are discoverable from the `Host` block, the `/etc/hosts` line and the
`allowedDomains` entry, which are the record.


**Built 17 Sep — `skill/setup/wizard.sh`, 673 lines.** Phases A, B and C and the
`/etc/hosts` write all exist, and `install.sh` offers the wizard when the phase A
marker is absent. `skill/` installs wholesale, so `setup/` ships with it and the
wizard lands at `~/.claude/skills/maestro-remote-mac/setup/wizard.sh` with no
manifest change. Modes: no argument runs it, `--status` reports what is
configured and writes nothing, `--hosts` re-runs the `/etc/hosts` step alone,
because reordering is a reason to come back without adding a network.

**Tested — 52 package cases, up from 37, plus the skill's 360.** `skill/setup/`
was in none of the three sweeps before this, so the wizard was not even
parse-checked. Fifteen cases now cover what it decides to write, against copies
in `$TMP`: the static address proposal, the SSID table gaining an arm per
network rather than being replaced, an SSID with trailing spaces surviving
splicing, a re-add replacing its arm rather than duplicating it, `--status`
writing nothing, and the `/etc/hosts` rewrite leaving unrelated entries alone
while honouring the requested order. Phase B was exercised by hand against
copies of the real `~/.ssh/config`: a new alias appends a block that `ssh -G`
parses with the `ProxyCommand` byte-identical to the hand-written ones, an
existing alias has its `Hostname` updated in place with no duplicate stanza, and
an address change drops the old entry from `allowedDomains` in the same diff.

**Discovery was run against the Mac and matched the live table** — address, mask
and gateway exact, and the service-name `awk` survived two layers of SSH
quoting. It found one defect: `sort -u` reordered the DNS list, putting a public
resolver ahead of the gateway, which is the opposite of what the table does and
would quietly change what the Mac resolves locally. Now deduped in place with
the gateway promoted, and the discovered line is byte-identical to the Mac's.

**Not yet exercised, and all of it needs a live run.** Phase A's fresh branch
(`ssh-copy-id` with a real password, writing `authorized_keys`), phase A's
subnet comparison (`ip -o -4 addr` returns nothing inside the sandbox, because
every Bash call gets its own network namespace), and phase C's install-and-cycle
sequence. The cycle command itself was verified live — see the test record above
— but not the wizard's wrapping of it.

**Two defects found in this package's own new code while testing it**, both
fixed: `allowedDomains` accumulated a stale address on every address change, and
the DNS ordering above. A third was a bad test rather than bad code — the case-arm
count matched the `printf` continuations inside `ipv4_config()`.

**Run live 18 Sep, in `--dry-run`, against the real Mac. Eleven defects, all
found by running it rather than by reading it.**

`--dry-run` was built first, precisely so the run could be made without writing
anything: it asks everything and reads everything — probing the Mac, listing its
networks, reading back the three files — and writes nothing. Reads stay on
because a dry run that skipped them could not show what it would write.

**Three that stopped the run dead.**

- **Phase C appeared to hang at its own header.** It was not a hang. Under
  `set -euo pipefail`, `dev=$(mac_run …)` against an unreachable Mac takes the
  whole script down before the caller can check whether the value came back
  empty, so the "no Wi-Fi device found" warning never printed and the exit code
  was 255. `mac_run` now always succeeds and prints nothing when the Mac cannot
  be reached, which is what a read helper should do.
- **The same bug one level up.** `phase_c` returning non-zero was the last
  command of its `then` branch, so the shell exited at the `fi`. Both that call
  and `write_etc_hosts` now report and carry on: one phase failing is not the
  run failing.
- **Phase C talked to the alias**, which `--dry-run` describes without writing,
  so `ssh <alias>` tried to resolve the alias as a hostname. It now picks its
  target — the alias once its block exists and this is not a dry run, otherwise
  the key and the address, which need nothing written yet.

**Four about values that were guesses dressed as facts.**

- The `.local` name defaulted to **this machine's own hostname** with `.local`
  appended, which is never the Mac's.
- A name with no dot was taken as given. `oi-james-mac` was about to be written
  into `allowedDomains`, where it would resolve to nothing while `curl` on the
  real name kept failing. The suffix is added when absent, and a name differing
  from the one already configured is challenged.
- The **key path** was a hardcoded `~/.ssh/mac_rc`. `IdentityFile` in an
  existing block is the real answer and is now preferred; the literal name
  survives only as a fallback for a machine with nothing configured.
- **"Network to try first"** defaulted to the first `Host` block in the file —
  the one thing that prompt exists to change. It now probes each alias and
  offers the one that answers, and offers nothing when none does.

**Two about the shape of the run.**

- **The network loop had no memory and no end in sight.** It asked "set up a
  network now?" after every pass, because the prompt was its condition; the same
  alias was typed and the whole thing ran again, which read as being stuck.
- **So the loop was removed.** A second network cannot be finished in the same
  run anyway: phase C reads every value off the interface the Mac is joined to
  right now, and phase B's probe against an address the Mac is not on fails, so
  the block would be written unverified. One network per run, then `/etc/hosts`,
  then a line saying to re-run after joining the next one.

**Two more, from running it against a machine with nothing configured — the case
it exists for, and the one path never exercised.**

- It **aborted at the first prompt**: `local known_user` under `set -u` leaves
  the variable UNSET rather than empty, and the loop that would assign it never
  runs when no `Host` block exists.
- The `/etc/hosts` step reported **"no configured networks" immediately after
  phase B configured one**, because it reads blocks off disk and a dry run
  describes rather than writes. It now counts the network configured in this
  run.

**What the run confirmed, which nothing else could.** Phase C's discovery is
correct against the real Mac: the Wi-Fi device, the preferred-network list
including the SSID with trailing spaces, and mask, gateway and DNS defaults that
reproduce the live table exactly. The splice started from the Mac's own script
and reported `profile replaced`, so a second network extends the table rather
than replacing it. The profile line it would write is byte-identical to the one
running. The subnet comparison in phase A also works outside the sandbox, where
`ip -o -4 addr` returns real interfaces.

**Still untested: the real write path.** `ssh-copy-id` with a password, the
actual writes to `~/.ssh/config`, `settings.json` and `/etc/hosts`, and phase C's
install-and-cycle on the Mac. The cycle command itself was verified live on
17 Sep; the wizard's wrapping of it was not.

**The write path was run for real on 18 Sep, and it found three defects.** Every
earlier test passed `--dry-run`, and the suite's own header said so — *"nothing
talks to a Mac and nothing touches the real files"* — so until now the wizard had
never written anything, not even to a copy. Run against `SSH_CONFIG`, `SETTINGS`,
`HOSTS_FILE` and `LIB_DIR` pointed at a throwaway directory, with `sudo` stubbed
on `PATH`:

- **A failed `sudo` was reported as a successful write.** `write_etc_hosts` ends
  `sudo cp; sudo cp; ok "written"` with no status check. It is called as
  `write_etc_hosts || warn`, and a function invoked with `||` runs with `set -e`
  suspended for its whole body, so the failure did not abort either. Measured
  against a sandbox whose `sudo` is not setuid: two `sudo: must be owned by uid 0`
  lines, then `ok written`, with the file untouched. `/etc/hosts` is the third leg
  of the all-three-or-none this item opens with, so a false success here is
  precisely the failure it exists to prevent. Both calls are now checked and the
  warning names what is inconsistent: the ssh config and settings.json written,
  this one not.
- **The network just configured was offered twice.** `configured_aliases` prints
  one alias per LINE; the guard against listing `$B_ALIAS` twice tested
  `case " $aliases " in *" $B_ALIAS "*`, which cannot match a newline-separated
  list beyond its first entry. The `/etc/hosts` step then asked which network you
  use most and listed the same one twice. Now newline-delimited.
- **Declining `settings.json` silently costs `/etc/hosts`.** The `.local` name is
  read back from `allowedDomains`, so without that write `MAC_NAME` is never
  learned and the step skipped with *"no .local name known, so there is nothing to
  map"* — which describes the cause and reads as though there were nothing to do.
  It now says the file cannot be written, where the name comes from, and what
  fails without it.

**Eight cases added, and they run the wizard rather than a function out of it.**
`sudo` is stubbed to fail and then to succeed, so both branches are covered; the
hosts file is asserted unchanged after the failure; and the `.local`-unknown
message is asserted to name its consequence. One of the eight was wrong when
first written — it matched `ok    written` loosely and caught settings.json's own
`written (backup: …)` from the same run — which is the same class of mistake as
the defect it was written for.

**A sixth defect, found by running `--hosts` against a copy of the real
`/etc/hosts` with the answers piped in: every `ssh` in the file needed `-n`.** A
successful ssh reads and discards whatever is on stdin, and stdin here is where
`ask` and `confirm` get their answers — so the `/etc/hosts` liveness probe
reached a Mac that answered and swallowed every answer after it. Reduced to a
three-line stream through one `ssh <alias> true`, after which `read` returned
nothing. Invisible interactively, because a person has not typed ahead, and only
reproducible when the Mac is actually reachable: both are the real-machine case
this item is about. Six calls, not the four a manual sweep found — the static
test caught two more in phase C, one inside a 40-iteration poll. `ssh-copy-id`
keeps its stdin, because it reads the password through it.

**The re-run path is now covered too.** Every other case adds a NEW alias; a
live run updates one that exists. Three cases assert the Host block is updated
rather than appended beside itself, that it carries the new address, and that
the address it replaced leaves `allowedDomains` instead of accumulating there.

**This machine needs no preparation, which is also why B cannot be exercised on
it.** Checked 18 Sep: the three Host blocks, `allowedDomains` and the
`/etc/hosts` marker block all agree, so a run would find nothing to change — a
rehearsal against a copy of the real file produced one whitespace difference and
nothing else. Exercising B for real means deliberately removing one network's
three entries and letting the wizard restore them, or joining the Mac to a
fourth network.

**Phase A was run live against the real Mac on 18 Sep at 13:18 and passed.** The
marker at `~/.local/share/maestro-remote-mac/phase-a-done` is the proof, and it
proves more than that the phase ran: it is written only after the `BatchMode=yes`
verification returns 0, which is after `ssh-copy-id` has returned 0. So both
halves of the one thing that had never run are now exercised — against a key
already on the Mac, so `ssh-copy-id` reported the keys as already installed and
never prompted, which is what makes it safe to re-run.

Declining the network question stopped it cleanly: `~/.ssh/config`, `/etc/hosts`
and `settings.json` were all untouched afterwards, timestamps unchanged from
14 Sep, 14 Sep and this morning's install. `--status` now reports `ok marker`
where it reported `warn no marker`, so the re-run branch — "Phase A ran on …,
nothing to do" — is live from here, and that is the branch every subsequent
network depends on.

**An anti-wizard, built 18 Sep: `wizard.sh --remove <alias>`.** Adding a network
writes three things that must agree, and this item's opening sentence cuts both
ways — two out of three is a failure that looks like something else whether you
got there by adding or by taking away. An address left in `allowedDomains` after
its `/etc/hosts` line has gone means the sandbox permits a host that no longer
resolves; a Host block left behind means `ssh <alias>` hangs on an address
nothing answers.

It is the mirror of phase B and reuses its parts: the Host block goes first
because the rest is derived from it, then `allowedDomains` loses the address that
block named, then `write_etc_hosts` — the same function the add path ends with —
rebuilds the whole block from the aliases that remain, so the file cannot end up
describing a network that is no longer configured.

Four refusals, each for a way of stranding the machine:

- **the last network**, because phase A's key path and the Mac's username are
  both read back *from* a Host block, so removing the last one loses the record
  of them as well as the route;
- **a Host line naming several aliases**, which is one block serving all of them
  — removing "the block" would take the others silently;
- **an unknown alias**, which exits 2 and prints what *is* configured, because a
  typo's useful answer is the list;
- **an address another alias still uses**, which is kept, and the message names
  the alias keeping it.

What it deliberately does not touch: the key, the phase A marker, and the Mac's
own network-change profile. The last of those is not squeamishness — nothing
local records which SSID belonged to which alias, because phase C reads it off
the interface live, so the script says so and points at the file to edit.

**Nine cases, and the round trip is the one that matters**: add a network, remove
it, and all three files are back where they started — `ssh_config` and
`/etc/hosts` byte-identical, `allowedDomains` identical in value (jq rewrites the
file, so the bytes move and the values must not).

**B and C were both run live on 18 Sep, and B was broken in a way only a live
run could show.** Every probe in this file named a raw `$user@$address`. A raw
address has no `Host` block, so it carried no `ProxyCommand` — and inside a
Claude session that address is unroutable. `PROXY_CMD` now names the string
once and phase B's probe, phase A's `ssh-copy-id`, phase A's `BatchMode` proof
and `c_target`'s fallback all pass it with `-o`. The generated block is
byte-identical to the three hand-written ones, checked both ways. **Phase A
could never have run from inside a session either**; that it passed at 13:18
says that run was in an ordinary terminal.

**Then a real network change was used to exercise B and C, and it found five
faults in an afternoon — four of them in this wizard.** The Mac was moved to a
fourth network and the first probe failed with
`kex_exchange_identification: Connection closed by remote host`, which is a
sentence that names nothing. In order:

1. **A probe that could not reach a new network from inside a session.** Every
   connection goes through the sandbox proxy, which carries only what
   `allowedDomains` names, and phase B wrote that entry *after* the probe
   passed. A network being set up for the first time could therefore never be
   verified from inside a session. Same proxy, same command: an address in the
   list gets a connection, one that is not gets `Bad Gateway` before anything
   leaves the machine. `allowedDomains` now goes first, and only that file —
   probe-then-write is unsatisfiable for the file that decides whether the probe
   can happen, and it is the safe one to write early, because an entry permits a
   host, it does not route anything and it cannot make `ssh <alias>` hang.

2. **The line that said what happened was thrown away.** The diagnosis printed
   `tail -1` of stderr, and the ProxyCommand's own message comes *before* ssh's
   summary — so `Bad Gateway` was discarded and `kex_exchange_identification`
   was all that survived. It keeps the output by the line now.

3. **The username was a fact the files recorded and nothing could change.** The
   Mac's account had been renamed. `resolve_from_existing` reads it from a `Host`
   block's `User` line, phase B never asks for it and never printed it, and
   correcting it meant editing every block by hand — while macOS drops an account
   it does not know *during the banner exchange* rather than answering it, so it
   arrives as the same silence as everything else. Phase A stops being
   create-once: a re-run prints the username, the `.local` name and the key with
   the file each came from, and offers to change any of it. Each fact is written
   where it lives and by the phase that owns it. `--edit` runs that alone, and
   `--status` prints the account each alias would connect as — the one field with
   no way to see it, which is how this got a day old unnoticed.

4. **One subnet, no ARP: the access point, not the Mac.** Remote Login was on for
   all users, sshd accepted its own loopback and returned exit status 0, the Mac
   held the address it said it held, and neither machine could ping the other.
   The access point was refusing station-to-station traffic, which nothing on
   either machine reveals and every arm would have blamed the Mac for. ARP is the
   test rather than ping — a host that drops ICMP still answers ARP — and the
   check runs ahead of the error text because it is a measurement where the other
   arms are readings of a message. The message says outright that nothing on the
   Mac is wrong, and gives the confirming ping from the other end.

5. **The retry loop sustained the failure it was diagnosing.** OpenSSH 9.8
   penalises a source address that keeps failing and drops it mid-handshake;
   `min:15` and `max:600` mean any penalty lasts at least fifteen seconds and can
   reach ten minutes, and a connection the penalty drops is itself another
   failure. Firing straight back renews it. The arm names penalties and how to
   clear them, and the retry says to wait rather than inviting another attempt.

**The anti-wizard ran live and found a sixth.** `--remove` took a network out of
all three files, and `/etc/hosts` came back unchanged with no sudo prompt after
the answer was yes. It asked twice — once before the file was built and once
after the diff, both defaulting to no, the second reading as a repeat of the
first. Every test passed through it because each answer stream happened to carry
a spare answer that landed on the second prompt. One question now, after the
diff, and the new case carries nothing spare.

**Two more things the afternoon argued for.** `--list` prints a row per network
saying which of the three files knows it, because a list of aliases alone hides
the state this whole item is about — a `NO` under allow means the proxy refuses
the address and the Mac reads as switched off, a `NO` under hosts means curl on
the `.local` name does not resolve. And `--remove` no longer demands an alias:
typing one from memory is how the wrong network goes, so a bare `--remove`
prints that list and takes a pick.

**Phase A asks which blocks a username or key change reaches.** The first
version wrote every one of them, on the argument that one Mac has one account
name — true of this machine and not of the file, which is the user's and may
name a second Mac, a work account, or a host that only looks like ours because
it borrows the key.

**Phase C, run live as far as a password allows.** Discovery off the live
interface matched the Mac's own table exactly, it took the `starting from the
script already on the Mac` branch, reported `profile replaced`, staged both
files, printed the five `sudo` commands and stopped clean on `Done? n`. The
staged plist is byte-identical to the installed one and the staged script is the
same 8209 bytes carrying the same profile line.

**All of it ran, on the third attempt, once the Mac was back on a network that
carries station-to-station traffic.** Phase B's *verified* add — the probe
passing and the block written on the strength of it — happened at last; the two
earlier attempts were defeated by the proxy ordering and then by client
isolation on the only spare SSID, which cannot be turned off.

**Phase C then found a seventh fault, and `bash -n` caught it before anything
reached the Mac.** The Mac's `Tachikoma:Redux` arm had been commented out by
hand, and the splice reported `profile replaced` and produced a script that
would not parse. The pattern was not anchored: `[ \t]*"SSID")` matches *inside*
a commented arm, starting after the `#` because what follows it is whitespace,
and the lazy run to the next `;;` then skips every commented one and stops at a
live arm's. So it deleted the live `The Sharp Project Tenants` arm and glued the
orphaned `#` onto `    "SenseGuest")`, commenting out its pattern and orphaning
its `echo`. `^` and `re.M` in both `splice_profile` and `drop_profile`: anchored,
a commented arm is not an arm, so the SSID reads as absent, a live arm is added,
and the comment is left where it is — it is a record of a choice, and the file
then says what it does.

**And an eighth, which was a wrong conclusion rather than a bug.** *"sudo there
has no passwordless path"* was true, and the thing built on it was not: sudo
needs a **terminal** to ask for a password on, not a passwordless rule, and
`ssh -tt` gives it one — which `ssh-copy-id` in phase A had been relying on since
the day phase A was written. Phase C now offers to run its five commands itself.
It still prints them, still lets you decline to the old "run these, then say
Done", and a failed install says how to check what got part-way and asks before
carrying on rather than cycling Wi-Fi over a half-installed daemon. `-tt` and
deliberately not `-n`, exempted from item 84's rule the way `ssh-copy-id` is, and
a case caps the exemption at exactly one call.

**A ninth, found by asking what a fresh Mac would do rather than by it
failing.** `install` does not create parent directories, and `/usr/local/bin`
does not exist on a Mac that has never had Homebrew or anything else put
something there — so on a genuinely fresh machine the script install would fail
with `No such file or directory`, which is the one machine phase C has never
run against. `/Library/LaunchDaemons` always exists, so the plist needs no such
step. The directory step is guarded rather than unconditional: measured on the
Mac, BSD `install -d` on a directory that already exists returns 0 and rewrites
its mode anyway — 700 came back 755 — so with `-o root -g wheel` it would rewrite
the owner too, and on an Intel Mac Homebrew owns `/usr/local/bin` as the user.
`[ -d ] ||` makes it a no-op on every machine that has run this before. Verified
both ways on the Mac: an existing 700 directory comes back 700, a missing one is
created 755.

**The install and the cycle then ran end to end.** `network-change.sh.bak`
records the file the install replaced, the new script is on the Mac and parses,
the plist was reinstalled and bootstrapped, and `/tmp/netchange.log` shows the
Wi-Fi going down at 16:32:08 and 16:32:25 and the daemon firing on reassociation
at 16:32:29. The WatchPaths trigger fires, the Mac comes back, and it holds the
static address. One caveat on what that proves: the daemon logged `already
static … — no change`, so the recovery and the trigger are exercised and
*applying* a new address is not — this Mac already held the address the profile
names.

**The round trip ran on the real files too.** `--remove mac-home` took it out of
all three, and the add put it back; `--list` now reports all three networks in
all three files.

**Coverage: 144 package cases, up from 37 when this started.** Seven are the
fresh-machine path, which had none. The rest of today's are the diagnosis and
the way back: each arm checked for the action it should name and the ones it
should not, the retry, the editor, the list, and the count of questions the
`/etc/hosts` write asks. Four harnesses now stub `ssh` rather than aiming at an
address that will not answer, and the suite unsets `grpc_proxy` and sets it
again in the one case that is about it — what a dead address produces is the
environment's business, and letting it vary made every fixed answer stream
depend on where the suite was run from. The suite no longer touches the network.
**Why 3, 4 and 5 belong in one tool: they must all three be right or none is.**
`setup.md:159-161` already says it — *"Add a new address when the Mac joins a new
network, in three places at once: here, `/etc/hosts`, and a new `Host` block in
`~/.ssh/config`. All three or none — two out of three produces a failure that
looks like something else."* That sentence is the item. A third network has been
added since the backlog last mentioned two, so this keeps happening.

**Two existing items are symptoms of the same gap.** Item 18 — `MAC_HOST` became
a space-separated list so a moving Mac stops looking like a broken one, and its
footgun, that `$MAC_HOST` raw is not usable as a hostname, is still open. Item
48 — the MCP server hardcoded one alias and missed the fix every script already
had. Both should cross-reference this one.

**Why a wizard and not more prose.** The same argument items 51 and 56 made: the
instructions exist, are correct, and are read at a moment when they cannot be
acted on.

**Gates.** None.

---

## 87. Flutter and iOS are wired in, not plugged in — **OPEN, raised 18 Sep; seam designed 18 Sep, nothing wired to it yet**

The driving half of this skill does not care what built the app. Maestro taps a
coordinate, reads a hierarchy, runs a journey and takes a screenshot the same way
whatever produced the binary, and `driver.sh`, `drivers.sh`, `flow.sh`, `img.sh`,
`wall.sh` and the journey tooling are all written against Maestro rather than
against Flutter. That half already generalises.

The *other* half — getting an app onto a device and looking inside it while it
runs — is Flutter and iOS all the way down, and it is not separated from the
part that generalises. Wanting to drive a React Native app, or a plain Android or
iOS one, means either forking the package or teaching every one of these files a
second way to do its job.

**Where the framework is wired in.** Counted 18 Sep by `grep -ciE
'flutter|dart|pubspec'`:

| file | hits | what it does that is framework-specific |
| --- | --- | --- |
| `remote/build.sh` | 31 | discovers how the project builds, builds for the simulator, installs |
| `remote/vmservice.sh` | 10 | finds the Dart VM Service base URI and main isolate id |
| `bin/net.sh` | 9 | reads the app's real HTTP traffic out of the Dart VM Service |
| `bin/publish.sh` | 5 | republishes that loopback-bound service on the LAN |
| `remote/gitstate.sh` | 5 | splits tracked changes into build residue and real edits |
| `bin/preflight.sh` | 3 | is the installed app the code under test |
| `bin/prefs.sh`, `bin/driver.sh`, `bin/build.sh`, `bin/config.sh`, `bin/hier.sh`, `bin/secrets.sh`, `bin/resolve.py`, `remote/relay.py`, `remote/net.py`, `remote/wall.py` | 1–2 each | a mention apiece, mostly a path or a comment |

**Where the platform is wired in**, separately and just as deeply — `grep -ciE
'xcrun|simctl|XCUITest|iphonesimulator'`: `remote/wall.py` 11, `remote/build.sh`
8, `bin/driver.sh` 8, `remote/deviceup.sh` 5, `bin/drivers.sh` 5,
`remote/driverup.sh` 4, then `wall.sh`, `lib.sh`, `shot.sh`, `prefs.sh`,
`preflight.sh`, `init.sh` with two or three each. **Nothing under `bin/` or
`remote/` mentions `adb`, an emulator or Android at all**, so Android is not
half-done, it is absent.

**Two axes, not one.** Framework (Flutter, React Native, native) decides how the
app is built and how you see inside it. Platform (iOS simulator, Android
emulator, a physical device) decides how it is installed and driven. They are
independent — React Native on Android is a real combination — and the code
currently assumes one point in that grid without saying so anywhere.

**Approximate shape of the seam.** A runner is a small set of answers, and
everything else stays as it is:

- **detect** — is this checkout mine? (`pubspec.yaml`, `package.json` with a
  react-native dependency, `*.xcodeproj`, `build.gradle`)
- **build and install** — for a given device, returning the installed app id
- **is the installed build the code under test** — `preflight.sh`'s question,
  answered per framework
- **build residue** — the paths `gitstate.sh` should ignore when deciding
  whether a working tree is dirty
- **traffic**, optional — the Dart VM Service for Flutter, Metro or a proxy for
  React Native, nothing at all for native. `net.sh` and `publish.sh` become one
  runner's answer rather than a feature of the package.

Platform is the same shape: install, list devices, boot, screenshot, and the
driver bring-up that `driverup.sh` and `deviceup.sh` do for XCUITest.

**Why it is worth doing rather than forking.** Everything expensive in this
package is in the half that already generalises — the rig, the wall, the journey
tooling, the driver lifecycle, the SSH and network side that item 85 is about.
A fork would copy all of it to change `build.sh`.

**Related.** Item 82 is four sessions opening the wrong skill because one builds
and the other drives; a package that names its runner explicitly makes that
distinction structural rather than a sentence in a description. `flutter-hot-reload-mac`
is the sister package and is Flutter by definition — it is not in scope here, but
whatever seam this item settles on is the one it would plug into.

**Gates.** None. Item 85 touches none of these files.

---

### The seam, as designed 18 Sep. `skill/runners/README.md` is the contract.

**The grep above overcounts.** Recounted by reading the files rather than
grepping them: **eight** hold Flutter *logic* — `remote/build.sh`,
`remote/vmservice.sh`, `bin/net.sh`, `bin/publish.sh`, `remote/net.py`,
`remote/gitstate.sh`, `bin/preflight.sh` and `bin/prefs.sh`. Every other hit in
the table is a comment explaining a measurement. `driver.sh`'s two, `hier.sh`'s,
`resolve.py`'s, `secrets.sh`'s, `wall.py`'s and `relay.py`'s all survive the word
being deleted, so they are not work. `bin/prefs.sh` was missed by the grep
entirely — its default filter is `flutter`, because `shared_preferences`
prefixes every NSUserDefaults key — which is the reverse error and worth the
same note.

**Two modules, confirmed.** The four names the seam is wanted for split cleanly
across the two axes this item already identified: `flutter` and `react-native`
are frameworks, `ios` and `android` are platforms. A single
`RUNNER=flutter|react-native|ios|android` cannot work, because it would make
`flutter` and `android` alternatives to each other when both are true at once.
`ios` and `android` also answer the framework questions for a project with no
framework above the platform.

A module is one POSIX `sh` script per axis, dispatching on its first argument.
**Exit 2 means "this framework does not have that verb"**, and it is not a
failure — it is what lets `net.sh` say "native apps have no traffic endpoint"
instead of "the relay is broken", which is the same distinction `vmservice.sh`
already draws and which cost a session six minutes before it did.

- framework: `claim describe variants variant-for-appid build residue
  devsession inspect traffic-arm traffic-list traffic-one prefs-prefix`
- platform: `claim devices boot shutdown install container data-container
  prefs-read prefs-flush orientations screenshot driver-up driver-down
  driver-scan capture-cmd`

**Written.** `skill/runners/README.md` (the contract, the seven call sites, and
what the stubs found), `runners/TEMPLATE/` (the module to copy),
`runners/flutter/framework.sh` and `runners/ios/platform.sh` (worked, delegating
to today's scripts), `runners/react-native/framework.sh` and
`runners/android/platform.sh` (stubs — **nothing in either has been run**, and
each verb says whether it is documented-not-measured or unanswered),
`bin/runner.sh` (the dispatcher: `which`, `path`, `rpath`, `detect`).

**Applied to the existing code**, behaviour unchanged and Flutter still coupled:

- `remote/build.sh` prints `artifact <path>` on a successful build and gains
  `--build-only`. This is the one real change the seam demanded and it is done:
  the simulator install is `_install_sim`, a named unit `runners/ios` mirrors,
  and on the physical-device path `--build-only` emits the build half of the
  script handed to the GUI session without the `devicectl` half. Five tests.
- `remote/gitstate.sh` — the residue list is `$RESIDUE_GLOBS`, defaulting to the
  same five patterns. Verified against a React-Native-shaped override.
- `bin/preflight.sh` — the dev-session heading, pgrep pattern and consequence
  text are variables, still holding the Flutter values.
- `bin/config.sh` — `RUNNER=flutter`, `PLATFORM=ios`. Nothing reads them yet.
- `bin/install.sh` pushes `runners/` to `$RDIR`; `bin/build.sh --no-install`
  passes `--build-only` through.

**Six verbs left unanswered on purpose, and they are the useful part.** Each is
a hole in the contract, not work nobody got round to. `android boot` — an AVD
name and an emulator serial are not the same identifier, and the contract
assumes they are. `android container` — `appcheck`'s timestamp-and-plist
comparison, the single most valuable check in `preflight.sh`, has no Android
equivalent. `android driver-up`/`driver-down`/`driver-scan` — Maestro's Android
driver is an instrumented APK behind `adb forward`, and whether its port can be
chosen per device at all decides whether several-devices-at-once crosses.
`react-native variants` — iOS schemes and Android product flavours are two
lists, which makes it the one verb where the axes are not independent.

**Done 18 Sep: `bin/build.sh` splits into two SSH calls, not one.** Call site 3
is the first of the seven wired, and it is the only one that needed a decision
rather than a substitution. `framework.sh build` then `platform.sh install`,
both reached through `runner.sh rpath`; `platform.sh claim` replaces the
UUID-shape test, `platform.sh devices --booted` replaces the inline `simctl`
parse behind `--all`, `framework.sh describe` answers `--detect`, and
`--install-only <path>` is new. Verified live against the Mac: `runner.sh
detect` claims the real checkout as Flutter, `--detect` reports through the
module, and a build returns 22s with the artefact path parsed back out. **The
install half is not verified live — no simulator was booted.**
`framework build` returns `artifact <path>` to this side, then one
`platform install` loops over the target devices on the Mac. Concatenating the
two verbs into a single remote command would save one round trip — 0.35s
against a 36s incremental build, about 1% — and would leave the artefact path
as a shell variable on the Mac.

Keeping the path here is what lets a *second* install skip the build. Not the
several-simulators case: `--all` already builds once and installs to every
booted simulator in one call, so devices present at build time cost the same
either way. It is every install of an artefact already built — a simulator
booted after the build (item 24), a reinstall after `simctl erase`, an
uninstall to test first launch, a driver or device replaced mid-session.

**A no-op build is 21-22s, measured 18 Sep 2026.** Three consecutive
`bin/build.sh --no-install` runs against an unchanged tree on the Mac: 34s
(19.6s Xcode), 22s (13.2s), 21s (12.4s). The first also re-confirms the 13 Aug
figure of 36s. It does not collapse to nothing, because Xcode re-runs Flutter's
script phase every time whatever the staleness of its outputs, and ~9s goes on
`pub get` resolution before Xcode starts at all.

So each repeat install saves 21s rather than the 36s first claimed here, and
one of them still pays for sixty builds' worth of the single-call saving.

Left open by that: the physical-device path polls a GUI-session build for up to
1200s and keeps its own `TMO`, so the two paths do not share a timeout rule.

---

### What is left, in units

Each unit is one commit. `runners/README.md` has the contract and the shape of
every call site's change; this is the order and the stopping condition.

**Stage 1 — wire the call sites that need no new answers. DONE 18 Sep**, five
commits, 1.1 to 1.5. Every call site now asks a module, and `RUNNER` changes
what five scripts say. Verified live against the Mac at each step; the three
bugs it turned up are in the unit notes below.

**1.1 DONE.** 1.1 Residue comes from the framework.** `bin/preflight.sh` passes
`RESIDUE_GLOBS=$(framework.sh residue)` into the remote call before it sources
`gitstate.sh`. `gitstate.sh` keeps its current default, because it is also
sourced standalone and by the tests, but nothing in the live path uses it any
more. *Files:* `bin/preflight.sh`. *Done when:* preflight against a checkout
whose runner answers `yarn.lock` reports `yarn.lock` as residue and
`pubspec.lock` as a change.

**1.2 DONE.** 1.2 The dev-session probe comes from the framework.** The three
`DEVSESSION_*` variables are filled from `framework.sh devsession` rather than
defaulted in the script. It runs on the Mac, so it folds into preflight's one
SSH call rather than adding another. *Files:* `bin/preflight.sh`. *Done when:*
`RUNNER=react-native` makes preflight say Metro rather than `flutter run`, and
say the app may not start at all rather than that driving is unaffected.

**1.3 DONE.** 1.3 `publish.sh` finds its endpoint through the framework.** The
`vmservice.sh` call becomes `framework.sh inspect`; `_profiling` and
`_profiling_on` become `framework.sh traffic-arm`. The relay, the state file and
the per-device suffix stay — `relay.py` does not care what is behind the port.
*Files:* `bin/publish.sh`. *Done when:* a framework whose `inspect` exits 2
makes `publish.sh` say that framework has no debug endpoint, rather than that
the relay failed.

**1.4 DONE.** 1.4 `net.sh` reads traffic through the framework.** The two `ext.dart.io`
URLs and the `net.py` calls become `traffic-list` and `traffic-one`. Keep the
fast-path/SSH-fallback choice and keep `_explain_empty`: "the app made no
calls" and "capture was never armed" look identical and must not be conflated.
*Files:* `bin/net.sh`. *Done when:* `RUNNER=react-native` makes `net.sh` print
the proxy explanation and exit 2, and Flutter behaves exactly as it does today.

**NOTE on 1.3 and 1.4.** The `traffic-*` verbs run **in the sandbox**, through
`$grpc_proxy`, while every other verb runs on the Mac. `runner.sh framework`
handles the local side and `runner.sh rpath` the remote one. A verb invoked on
the wrong side fails as a network error, which reads as a broken relay rather
than as a wiring mistake.

**1.5 DONE.** 1.5 `prefs.sh` uses both modules.** The container lookup and the plist read
become `platform.sh data-container` / `prefs-read` / `prefs-flush`; the default
filter becomes `framework.sh prefs-prefix`. The only call site that needs both.
*Files:* `bin/prefs.sh`. *Done when:* the default filter comes from the runner
and a framework with no prefix reads every key rather than none.

**Stage 2 — prove it against something that is not Flutter.** Doing this before
the mechanical work means Stage 3 is done against a contract known to hold
rather than one hoped to.

**2.1 DONE 18 Sep**, and extended on the same day to the multi-device forms.
Every booted-device path in the platform contract has now run against a real
device, which none of them had: Stages 1 and 3 were verified
only on empty and error paths, because nothing was booted.

Exercised through their real callers, not by hand — `boot`, `driver-up`,
`driver-scan`, `devices --booted`, `install`, `container`, `orientations`,
`data-container`, `prefs-flush`, `prefs-read`, `screenshot`, `capture-cmd`,
`last-used`, `uninstall`, `driver-down`, `shutdown`. `locked` returns 2 for a
simulator, which is the self-gate working.

**The split's saving, measured rather than argued: `--install-only` is 3s
against 25s for build-and-install.** That is the 22s the no-op build costs,
recovered exactly as predicted.

Two things it found:

  `rig up` printed an awk error. The live-driver guard on the wall's label
  reclaim is a $( ) inside a double-quoted _ssh string — expanded LOCALLY — and
  its field references were escaped as though it ran on the Mac. awk died, the
  substitution came back empty, and the guard has never fired. One of the three
  tests protecting a peer's label was dead, leaving only the age check. Raised
  and fixed as item 88.

  The reclaim tests did not catch it because they reimplement the logic in shell
  and test the intent rather than the shipped string. The new test reads the
  file instead.

**The forms that need more than one device, verified 18 Sep with two booted:**

  drivers.sh down <udid>   stops one driver and leaves the other alone
  drivers.sh up <udid>     brings it back ON THE SAME PORT — 22088, which is
                           the per-device ports map holding across a restart,
                           and is the whole reason that map lives on the Mac
  build.sh --all           one build, both installs, `platform.sh devices
                           --booted` feeding the target list and the install
                           loop running on the Mac in ONE round trip
  --all --install-only     both devices in 23s against 88s for the build-and-
                           install, which is the saving scaling with the device
                           count rather than being spent per device

Left as found: rig down, nothing booted.

**2.2 React Native on iOS, end to end.** The cheapest second target by a
distance: `runners/ios` already works, so only `framework.sh` is new. Fill in
`describe`, `build` and `residue` against a real checkout. **Needs a React
Native checkout on the Mac — there is none today.** *Files:*
`runners/react-native/framework.sh`. *Done when:* `bin/build.sh --detect`
reports an RN project and `--no-install` produces an artefact path.

**Stage 3 — call site 7. DONE 18 Sep**, seven units, seven commits. It was
planned as four files and "one command substituted for another, repeatedly".
Call site 7 covers seven files, and two of the substitutions were not
substitutions at all.

**3.1 `lib.sh` DONE.** `_dev` and `_driver_scan` become `devices --booted` and
`driver-scan`. The module paths are plain strings set in `lib.sh` rather than a
call to `bin/runner.sh`, because `runner.sh` sources `lib.sh` and every `_dev`
would otherwise pay for a subprocess to learn what `config.sh` already knows.

**3.2 `drivers.sh` DONE.** Six call sites, five of them substitutions.

The sixth was `rig reap`'s freshness probe, which walked CoreSimulator's per-app
data containers for an mtime — two levels deep, because a container's own mtime
only moves when its IMMEDIATE contents change and a device driven all day on the
18th reported the 16th. That is archaeology rather than a command, so it became
**`last-used`**: `<id>|<yyyymmdd>|<human>|<today>` for every booted device in one
call. Today's date comes from the device's own host, so clock skew between the
two cannot reap a live device. Android's is unanswered and says why — an
emulator image's mtime says the emulator is running, not that anyone is driving
it, which is a different question.

Boot and settle also split. `platform.sh boot` waits for the DEVICE;
`drivers.sh` still waits for the MACHINE afterwards, and it is the second that
decides whether the next boot or a driver start survives. Two different things
that happened to share a function.

**3.3 `shot.sh` DONE.** One line.

**3.4 `wall.py` DONE, and reading it settled the open decision rather than a
design argument.** `wall.py` used the runtime ONLY to sort and dropped it from
the return — so no JSON form was needed. `devices` gained an optional fourth
column carrying the runtime, and the single text format stays. No `simctl`,
`XCRUN` or `SIMSERVER` left in the file.

The module's `devices` reads `-j` and parses it with python rather than scraping
simctl's human listing, because that listing puts the runtime on a heading line
ABOVE its devices and a line-at-a-time parse cannot carry it down to the rows.

**3.5 `preflight.sh` DONE.** `container`, and `orientations` — which already
existed and had no caller. `orientations` takes the container rather than the
device on purpose: it reports what the INSTALLED BUILD declares, not what the
device supports, and those differ on exactly the case the check exists for, a
landscape-locked app on a natively-portrait iPad.

**3.6 `flow.sh` DONE.** The other screenshot.

**3.7 `driver.sh` DONE**, and it needed two verbs the contract lacked.

`uninstall <id> <app-id>` for `clearstate`. Removing the app removes its data
with it, which is the point: clearstate wants a first-launch app, not a
logged-out one. An app already absent is not a failure.

`locked <id>` has THREE statuses — 0 locked, 1 not, **2 the question does not
apply** — and the third is what lets the check self-gate. `devicectl` returns
nothing for a simulator udid, so a simulator gets 2 and the caller never needs
to know which kind of device it holds. Verified live.

That third status caught a latent test bug. The three lock stubs answered by
PRINTING `passcodeRequired: true`; they answer by status now, and the simulator
case returns 2 where it returned 0 — which under the new code means "locked".

**Three verbs and a column added across the stage:** `last-used`, `uninstall`,
`locked`, and `devices`' optional fourth column.

**Nothing under `bin/` calls `xcrun`, `simctl` or `devicectl` any more.** What
still matches is comments in `build.sh` and `driver.sh`, and three files that
are a module's own territory rather than a caller's: `remote/vmservice.sh` and
`remote/build.sh` belong to the flutter framework runner, `remote/deviceup.sh`
to the `ios-device` platform runner. Moving them inside `runners/` would leave
`remote/` holding only shared code, and is worth doing before a second platform
arrives.

`bin/init.sh` is the real remainder and is **5.2**: it lists devices and
installed apps for the setup wizard, which is conf-writing rather than driving.

**Stage 4 — answer the six unanswered verbs.** Two are paper decisions and can
be taken now. Two need hardware this Mac may not have.

**4.1 `android boot` — settle the identifier.** An AVD name and an emulator
serial are not the same thing and the contract assumes they are. Either add
`resolve <name> -> <id>` or have `boot` print what it booted. *Paper.*

**4.2 `react-native variants` — settle the second argument.** iOS schemes and
Android product flavours are two lists where the contract asks for one, which
makes this the single verb where the two axes are not independent. *Paper.*

**4.3 `android container` — give `appcheck` an Android form.** The
timestamp-and-plist comparison is the check that caught a wrong-branch build
twice and it has no Android equivalent. `dumpsys package <id>` gives
`versionName`, `versionCode` and `lastUpdateTime`. *Needs a device.*

**4.4 The Android driver trio.** Maestro's Android driver is an instrumented
APK behind `adb forward`, sharing nothing with XCUITest. The question that
decides the shape: **can its port be chosen per device?** `bin/drivers.sh`
exists only because Maestro's iOS client hardcodes 22087, so if the Android
client does the same, several-devices-at-once does not cross. *Needs an Android
SDK and a booted emulator.*

**Stage 5 — what falls out once a second runner works.**

**5.1 DONE 18 Sep.** A paragraph beside the config step saying what a runner is
and why there are two settings, and the sentence that does the work: everything
Flutter or iOS in the rest of the file is one runner's answer. Step 5 is "a dev
session" and carries the warning that no Metro is not the same as no
`flutter run`. The build numbers are 18 Sep's, including `--install-only` at 3s
against 25s. `--detect` is named as the framework's `describe`; `bin/runner.sh`
joins the tool table.

**5.2 DONE 18 Sep.** The framework is asked, not assumed — with a REPO, init
runs `runner.sh detect` and writes what claimed it. Without one it writes the
default AND SAYS SO, because a default presented as a finding is how a wrong
runner survives a setup. PLATFORM is ios with the reason given: nothing is
booted yet to ask about. The gitignore advice covers `.maestro-mac.conf.*` too,
which is where a credential actually lives in a two-environment project.

**5.3 `flutter-hot-reload-mac`.** The sister package, Flutter by definition, and
it plugs into this same seam. Out of scope for this item and it will not stay
out.

**5.4 `remote/` keeps only shared code.** Raised by Stage 3 rather than planned:
three files there are a module's own territory and sit outside `runners/`
because that is where they were before the seam existed.

  `remote/vmservice.sh`  the Dart VM Service discovery — the flutter framework
                         runner's `inspect`, which already shells into it
  `remote/build.sh`      the Flutter build — the same runner's `build`
  `remote/deviceup.sh`   the physical-device driver bring-up, with its usbmux
                         forwarder and its tunnel wake

**The first two are DONE 18 Sep.** `remote/build.sh` and `remote/vmservice.sh`
are `runners/flutter/`'s now. The gain was not tidiness: `variants` and
`variant-for-appid` REPRODUCED build.sh's flavour rule rather than calling it,
so the subtle part — a flavour is real only when both an xcscheme and a
`lib/main_<f>.dart` exist — had two implementations that could drift. build.sh
gained `--list-variants` and `--variant-for`, and both verbs ran for real
against the seven-flavour repo for the first time: six flavours listed,
`variant-for-appid` narrowing to exactly `uat`.

**The third is not a move.** `remote/deviceup.sh` belongs to `runners/ios-device`,
which does not exist — and both `bin/build.sh` and `runners/ios/platform.sh`
already name `ios-device` as a platform that ought to. Creating it is closer in
size to 2.2 than to a file move: devicectl rather than simctl, a profile build,
a usbmux forwarder, a lock refusal, and `remote/iproxy.py` with it.

**This one has a dependency the rest of Stage 5 does not.** `remote/` holding
iOS-specific helpers is what a second PLATFORM trips over, so 5.4 wants doing
before 4.3 and 4.4 rather than after them.

**The flutter module is verified end to end as of 18 Sep — EVERY verb has run
live.** `claim` against sixteen checkouts, `describe`, `variants` and
`variant-for-appid` against the seven-flavour repo, `build`, `residue`,
`devsession`, `prefs-prefix`, `inspect` in both failure modes and in success,
`traffic-arm` with both states, `traffic-list` and `traffic-one`.

The last two needed a recorded request, and this app only calls out on login.
The login needs a PIN, and the PIN is in the `hugoboss-flutter-runner` project's
own `.maestro-mac.conf` **on this machine** — which is the convention working
exactly as designed, and which I first looked for on the Mac and under one local
path and wrongly concluded was absent. Pointing `MAESTRO_MAC_CONF` at that
project picks up its conf, its `DEV`, its dev flavour and its committed
journeys, and `00-login-store-set.journey` does the rest.

  traffic-list  GET /v1/users?storeId=1927 -> 200, /v1/chats -> 401, and more
  traffic-one   headers and body, user-agent: Dart/3.11 (dart:io)

The credential stayed where it belongs throughout: the journey reads
`${APP_PIN}` from the conf rather than taking it on the command line, so the run
log shows the variable name and not the value, and `bin/secrets.sh check`
afterwards reported clean — no project value in any file git would commit.

The live run also found a bug in 1.4 that could never have worked: the module
addressed net.py as `$RDIR/net.py`, a path on the MAC, for verbs that run in the
sandbox. Only the SSH fallback worked, and nothing had reached the fast path.

**Order.** Stage 1, 2.1, Stage 3, 5.1, 5.2, 5.4's first half and the traffic
verification — all done. Left: 5.4's second half (`runners/ios-device`), Stage 4,
5.3, and 2.2 whenever there is an RN checkout to use.

**Answered 18 Sep: neither is on that Mac today.** No `adb`, no SDK directory,
no `~/.android/avd`, no emulator binary; `~/.maestro/deps` holds the iOS capture
binary and nothing else. And no React Native checkout — both runners were asked
to claim all sixteen repos on the Mac and every one is Flutter, including
`hb-phase2`, which the name does not give away.

So 2.2, 4.3 and 4.4 are each blocked on an install rather than on a decision,
and the two are not the same size: an RN checkout is node, a `react-native init`
app and a `pod install`, while Android is an SDK, an emulator and Maestro's
Android driver on top.
