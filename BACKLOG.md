# maestro-remote-mac — backlog

Two items remain, and neither is gated. **17 is done** — the package has a git
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

**Next item number: 85.** Items 1–84 are allocated; new items start from 85.

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
