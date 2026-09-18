# maestro-remote-mac — backlog

Three items remain, and none is gated. **17 is done** — the package has a git
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
71's detached-work rules, verified live on an iPhone the same afternoon. **69's
route is fixed in `skill/` but 69 stays open**: its fold gained a measurement that
withdraws its own "confirmed on the iPhone" claim, and the test that settles what
the 15 Sep sweeps were worth has not been run.

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
exists to prevent. What remains of 67 is the label half.

**75, 77, 78, 79, 80 and 81 are done** and in `BACKLOG-DONE.md`. What remains is
**82** (a hook in the sister skill, so not this package's to take), **69**'s
outstanding measurement, **67**'s remaining label half, and **28**.

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

**85 was raised on 17 Sep** and is the first item about setting the skill up
rather than running it.

**86 was raised and fixed on 18 Sep** — the suite went red with no code
change, on a test that was only correct when it was not shortly after midnight.
It is in `BACKLOG-DONE.md`.

**87 was raised on 18 Sep**, the first item about what this package is *for*
rather than how it works.

**Next item number: 88.** Items 1–87 are allocated; new items start from 88.

---

## 28. Machine and client data left in this directory, and two files that should go — **OPEN and unblocked, raised 19 Aug**

The 12 Aug sweep read all 573 files and found no credentials. Client and machine
data was in eight places; four were removed or redacted and four remain by
The maintainer's decision, because a handoff that will not name the Mac it talks to is
less useful:

| file | what it carries |
| --- | --- |
| `RULES-STALE-pre-skill.md` | the full set — 11 alias mentions, 2 `/Users/dev` paths, banner-marked |
| `HANDOFF.md` | 4 alias mentions and 3 ticket keys |
| `README.md` | 2 alias mentions and a `/Users/dev` path |
| `BACKLOG-DONE.md` | a project path, a ticket key and the Mac's alias |

None of the four is in the package — they sit in `~/claude-sandbox/maestro-remote-mac/`
and the repo took only `src/`, now `skill/` — so this is only about what leaves
the machine. **Item 17 was that moment and it has passed**, half of it: the
package has git, one commit and no remote. Nothing is exposed yet, and the
decision is now due rather than gated.

**17 Sep adds a fifth file, and this one *is* in the package.** `skill/` carries
client identifiers of its own — the employer name, the client app's repository
name and its Jira ticket keys, in `SKILL.md`, `physical-device.md`,
`bin/init.sh` and `test/run-tests.sh`. The 12 Aug sweep did not count these, because at the time
nothing under `src/` was going anywhere. A remote changes that, so they belong
in the same decision as the four above.

Two leftovers were flagged on 12 Aug and not acted on. The top-level `docs/`
duplicates the docs mirror now in the repo at `skill/docs` — both 1.2 MB, the
same pages, differing only in that the top-level copy has `llms.txt` and no
`VERSION`, so it is the copy whose provenance cannot be checked. And
`RULES-STALE-pre-skill.md` should be deleted when `README.md` is dealt with,
since it is the pre-skill rules document and is wrong in two places its banner
does not name. `build/` and `ship.sh` join that list — superseded by the repo,
source of truth for nothing, and still here.

**Fix.** 17 is taken, so this is unblocked. Delete the duplicate top-level
`docs/`; delete `RULES-STALE-pre-skill.md` with `README.md`; delete `build/` and
`ship.sh`; and ask about the rest rather than redacting them — the two the maintainer kept
deliberately, and the identifiers inside `skill/`, which are the ones a remote
would actually publish.

---

## 82. Four sessions opened with `flutter-hot-reload-mac` when asked to drive — **OPEN, raised 17 Sep**

15 Sep, four separate sessions: `6d3227d1` (*"You made this same mistake
yesterday. Did I ask for hot reload?"*), `397ef6f2` (*"Right, you keep jumping
straight to hot reload, why?"*), `17b1a3ca` (*"Cunt, stop with the fucking hot
reload skill."*), `78615f38` (*"The fuck are you doing? maestro skill."*).

The description already says it. `SKILL.md`'s frontmatter carries *"The app must
already be installed; this skill does NOT build or launch from source (that is
flutter-hot-reload-mac)"*, and the sister skill's says the mirror image. It has
not worked. `397ef6f2`'s own diagnosis, when pressed for a real answer: *"I'm
pattern-matching 'start driving' + 'DEV app' + 'build' to 'launch the app', and
hot-reload is the skill that launches. The distinction I'm failing to make is
between running the app and driving the app."* The trigger is a request that
mentions a build or an environment, which is most of them.

Four repeats in one day, after the description was already written to prevent it,
is the same argument item 51 made for a hook over more prose: **a rule the model
reads at the wrong moment is not a rule.** Note also `397ef6f2` at 14:27 — told
to report the problem to the skill's own session, it sent the message to the wrong
session first and could not recall it.

**Approximate resolution.** The `gate-journey-first.sh` precedent: a PreToolUse
hook on `flutter-hot-reload-mac`'s entry points asking whether the app is already
installed on the target simulator — if it is, name `maestro-remote-mac` and stop.
The check is cheap (`preflight.sh` answers it in one round trip) and it fires at
the moment of the mistake rather than at session start. This belongs to the
sister skill as much as to this one; raised here because this is where the cost
landed.

**17 Sep: raised in the sister package, where the fix belongs.**
`~/claude-sandbox/flutter-hot-reload-mac/BACKLOG.md` item 16 carries the four
sightings, the session's own diagnosis, and the resolution — a `PreToolUse` hook
on that skill's entry points that asks whether the app is already installed and,
if it is, names this skill and stops. It points at
`skill/hooks/gate-journey-first.sh` as the worked precedent and at this
package's `install.sh` for how a hook ships with a skill.

**This item stays open here as the record of the cost**, and closes when that
one does. Nothing in this package changes.

**Gates.** None. Same argument as item 51.

---

## 85. SSH and network setup is seven manual steps across three files that must all agree — **BUILT 17 Sep, DRY-RUN AGAINST THE MAC 18 Sep; the real write path is still untested**

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

**Coverage: 59 package cases, up from 37 when this started.** Seven of them are
the fresh-machine path, which had none, and they were checked against the bug
they exist for — reintroducing the unassigned `local` turns six of the seven red.

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

## 87. Flutter and iOS are wired in, not plugged in — **OPEN, raised 18 Sep**

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

## 88. A simulator booted by a session that has ended stays booted for ever — **OPEN, raised 18 Sep**

Labels have a reclaim path and boots do not. `wall.sh` takes a label back once
three things hold — it names a different session, that device has no live driver,
and it has not been touched for `LABEL_STALE_AFTER` — and `remote/wall.py:137-139`
stops showing a name from a previous calendar day. Nothing does the equivalent
for the simulator underneath it.

**Measured 18 Sep 2026.** Seven simulators booted on the Mac. `/tmp/maestro-mac/rig`,
the claim ledger, was empty and last modified 17 Sep 16:49, so `rig down` and the
`SessionEnd` hook were both no-ops on all seven. Two carried labels written that
morning; the other five had last written app data on **16 Sep**, between 14:36 and
16:14 — two days earlier. Three of those five still had a live XCUITest driver from
17 Sep 16:48, which is what a driver looks like when nothing has run against it since.
They were shut down by hand with `xcrun simctl shutdown`, because the toolkit offers
nothing that would.

**Why the rig cannot do it as written, and should not.** `bin/drivers.sh:223` calls
`_rig_claim` only on the branch that boots a device; `:218` prints `already booted
(leaving it alone)` and records nothing. `rig down` then takes down only what is
claimed. That rule is right — item 74's teardown is scoped this way because taking
a peer's simulator down mid-run is worse than leaving one behind, and on 16 Sep a
session that read a boot storm as a crowded machine killed four working simulators
to recover from it.

**Why it matters rather than being untidy.** Item 74 measured the cost: seven booted
with the wall up sits at load 6, and booting one more took the Mac to 122 within 36
seconds. Idle simulators are cheap, so this is not about load. It is that the wall
is the thing two sessions share to see what is being driven, and five tiles nobody
has touched for two days make it unreadable — which is the same argument that got
labels their day rule and their reclaim.

**Fix.** The label reclaim already encodes the judgement this needs: a different
session, no live driver, and old enough. Apply the same three tests to the boot.
The pieces:

1. **A `drivers.sh rig reap`** that lists booted simulators which no session claims,
   have no live driver, and whose newest app-data write is older than a threshold —
   and shuts them down only when asked. Listing is safe; shutting down on its own
   initiative is what item 74 warns against.
2. **A number for "old enough."** `LABEL_STALE_AFTER` is 3600s, which is right for a
   name and far too short for a boot — a simulator idle for an hour is normal.
   Calendar day is the rule the wall already uses for names and is the obvious
   starting point, but it wants measuring rather than assuming.
3. **Say it on the wall.** A tile for a simulator nobody claims, with no driver and
   no activity since a previous day, could say so. This is item 67's piece 4, which
   asked the same question about labels and was left open deliberately; the two should
   be answered together.

**Gates.** None. It touches `bin/drivers.sh` and `remote/wall.py`, neither of which
item 85 or 87 changes.
