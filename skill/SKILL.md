---
name: maestro-remote-mac
description: DRIVE the app — tap, type, swipe, scroll, navigate and run whole UI journeys on an already-running iOS simulator app on the remote Mac. This is the skill for 'drive the app', 'start driving', 'test the UI', 'reproduce a bug', 'step through the app', or any interaction with the running app. The app must already be installed; this skill does NOT build or launch from source (that is flutter-hot-reload-mac). Works in any project; settings come from a per-project .maestro-mac.conf.
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# Maestro on a remote Mac

Everything runs on the Mac; nothing is installed here. Two paths reach it:

- **`bin/drivers.sh` and `bin/driver.sh`** — this toolkit runs its own
  XCUITest drivers, one per simulator, and talks straight to their HTTP API
  relayed onto the LAN. It reads the hierarchy in 0.28 s, taps in 0.46 s,
  resolves elements by label itself, runs whole journey files in one call, and
  drives **several devices at once**. **This is the default and it needs
  nothing else running.**
- **The `maestro-mac` MCP server** (`run`, `take_screenshot`, `cheat_sheet`,
  `open_maestro_viewer`) for anything that has to be a real Maestro flow — CI, a
  report, a Maestro-generated artifact.

**The MCP server can only ever address one device, and it does not say so.**
`MaestroSessionManager` and `McpMaestroSessionManager` both compile the driver
port in as a literal `22087` with no override, and the session map has no
invalidation path. So `inspect_screen` returns **whatever device is on 22087**,
regardless of the `device_id` you pass, with a response that looks entirely
correct. Measured on 12 Aug: asked for the iPhone, it returned the iPad's tree.
Two real sessions lost time to this, one of them an hour.

So: bring the drivers up yourself, drive through `driver.sh`, and treat any MCP
reply about a device as unverified unless only one simulator is booted. A
`maestro` CLI run has the same effect on 22087, and reconnecting the server is
still the only thing that clears a session it has cached.

## Start of session, in order

**1. Start the wall and post its URL, unprompted.**

```sh
$SKILL/bin/wall.sh            # -> http://<mac>:9990/
```

Every booted simulator, live, on one page. Put that URL in the conversation on
its own line, somewhere obvious, before anything else — the work can then be
watched rather than taken on trust. The port is fixed, so it is the same URL
every session and it can be bookmarked once. Post it again after any restart.

It spawns Maestro's capture binary per device — one `simulator-server ios --id
<udid>`, started by its own scan loop whether or not a browser is attached
(measured 17 Sep 2026: seven booted, seven capture processes) — and never
touches an XCUITest driver, so it is safe to start in the middle of a run.

**What costs the Mac is booting a simulator, not having one.** Measured 17 Sep
2026 on this Mac: seven simulators booted, the wall up, ~1,470 processes inside
simulator runtimes, one-minute load **6**. Booting one more took load to **122
within 36 seconds** while adding only ~170 processes, and it fell back as soon
as that boot settled. So a device budget is the wrong instinct: several
simulators sitting idle are cheap, and it is a boot storm that makes the machine
look broken. Boot them **one at a time, waiting for each to settle**, and do not
start drivers during a boot — `drivers.sh up` says so if the load is already
high. A session that read a boot storm as a crowded machine on 16 Sep killed
four working simulators to recover from it.

The URL is built from `MAC_FQDN` and `WALLPORT`. Where the Mac is reached some
other way — a tunnel, another hostname, a reverse proxy — set `WALL_URL` in the
project conf and that is checked and published instead.

**Do not use `bin/viewer.sh` for this.** Maestro's own viewer cannot be watched
remotely: it hands the browser an absolute `http://127.0.0.1:<random>/stream.mjpeg`,
which the browser then fetches from its own machine. It also attaches a device
only when exactly one simulator is booted. `viewer.sh` is still there for the
viewer's command rows, and says so itself.

If the wall reports that SimulatorKit is missing, Xcode 27 moved it —
`bin/wall.sh status` prints the two commands that put the path back.

**Name what you are driving.** A tile otherwise says only which handset it is,
and three handsets driven by three projects look identical:

```sh
$SKILL/bin/wall.sh label "Checkout flow, PR 101" --group brandco-flutter-runner
```

Each label records which session wrote it — the session colour, so it matches
what your terminal is showing, plus seven characters of the session id to break
a tie. The page shows it under the name, with how long ago it was set, so a
wrong name on a Mac two sessions are sharing can be traced to one of them.

With no udid it names the device `DEV` resolves to. Devices sharing a `--group`
appear together under a heading. `bin/drivers.sh up` writes a default — `PROFILE`
or `APP_ID` for the name, the project directory for the group — and never
overwrites a name set by hand; `drivers.sh down` clears it.

**A name from a previous day is not shown at all.** The tile still says which
handset it is, and `drivers.sh rig status` still prints who last had the device
— the label file is untouched — but the wall stops claiming somebody is driving
it. By calendar day rather than by hours, because that is how a wall reads: a
name put up at 09:00 is still today's work at 23:00, and one put up at 23:00 is
yesterday's by breakfast. A name that has merely gone quiet for an hour is
greyed, not hidden; a long-running session keeps its name.

**A label left by a session that has gone is reclaimed.** Nothing clears a label
at session end, so without this every stale one reads as hand-set — the wall has
shown simulators named thirteen hours earlier, none of them working, under
sessions that had ended. The test is all three of: the label names a different
session, that device has no live driver, and it has not been touched for
`LABEL_STALE_AFTER` (default 3600s). A mismatch alone is deliberately not
enough, because two live sessions share this Mac routinely; the age is there
because Maestro tears a driver down on every CLI or MCP run, so "no driver right
now" on its own would rename a peer's device mid-session. The label is a file
on the Mac written over the same SSH everything else uses, so the wall is only
ever read from.

**2. Check the project is configured.** Every script sources
`bin/config.sh`, which looks for `.maestro-mac.conf` — `$MAESTRO_MAC_CONF`
first, then from `$PWD` upwards, then `~/`. If it is missing the scripts stop
with instructions. Do not invent values: ask the machine, then ask the user.

```sh
$SKILL/bin/init.sh --detect                  # ssh aliases on this machine
$SKILL/bin/init.sh --host <alias> --detect   # the Mac's name, booted sims, installed apps
```

Put the real candidates from those two calls into an `AskUserQuestion` — which
Mac, which app — then write the file:

```sh
$SKILL/bin/init.sh --host <alias> --fqdn <mac>.local \
                   --app <bundle-id> --repo <checkout on the Mac> --write
```

That is per-project. If the *machine* has never been set up — the SSH alias and
its proxy routing, the `/etc/hosts` entry, the sandbox network allowlist, the
`maestro-mac` MCP registration — none of the above will run, and
`reference/setup.md` has the whole sequence with the failure each missing piece
produces.

**3. Read the project's app notes if they exist** — `bin/notes.sh path`. They
record what has already been measured about this app, which is the difference
between driving it and rediscovering it.

**And list the executable prior work beside them** — `$JOURNEY_DIR`
(`maestro/journeys/`) and `maestro/flows/`, plus `COVERAGE.md` if the project has
one. The notes are measurements; the journeys and flows are the screens somebody
already got working, in the order they work in. A screen covered there is
replayed, not rediscovered — the journey file is the unit of work, not a
`driver.sh` call (rule 1). `preflight.sh` prints the counts, so the gap is in
front of you before the first tap.

**4. Bring the rig up.** Several simulators brought up and taken down as one:

```sh
$SKILL/bin/drivers.sh rig up <udid> <udid>   # or RIG_DEVICES in the conf
$SKILL/bin/drivers.sh rig status             # what is up, whose it is, on what port
$SKILL/bin/drivers.sh rig down               # only what THIS session booted
```

`rig up` boots, waits each boot out, then starts a driver per device and names
it on the wall. **Boots are serialised on purpose** — see the numbers at the
wall step — and drivers start only once every boot has settled, because a
driver begun during a boot storm is the one that dies.

It does **not** build or install: `build.sh` must not run unprompted, and a rig
that silently replaced the build under test would be worse than no rig.

`rig down` takes down only the simulators this session **booted**, recorded per
session on the Mac. A device that was already up when the rig found it belongs
to somebody and is left alone — a teardown that takes a peer's simulator with it
is worse than one that leaves something behind. **Run it when the driving is
finished.** The `SessionEnd` hook in `hooks/rig-down-on-end.sh`, which
`install.sh` registers, covers the endings that are not tidy ones — but it takes
down only what this session booted, so it is a backstop, not a substitute.

For a single device, or to add one to what is already running:

**Bring the drivers up.**

```sh
$SKILL/bin/drivers.sh up      # one driver per booted simulator, ~30s each
$SKILL/bin/drivers.sh         # what is running, and on which port
```

Then `bin/install.sh` once per machine or scratch path.

Every simulator gets its own driver on its own port, so **`DEV=<udid>` selects
the device** and everything after it goes there:

```sh
DEV=<ipad-udid>   $SKILL/bin/driver.sh nodes
DEV=<iphone-udid> $SKILL/bin/driver.sh tapon "^CONTINUE$"
```

`driver.sh` finds the port from the live processes on the Mac, so nothing has
to be kept in step by hand. With one driver running and no `DEV`, it uses that
one. With several and no `DEV`, it **refuses and lists them** rather than
picking — driving the wrong simulator looks exactly like the app misbehaving.

One simulator holds one driver: starting a second replaces the first.

**A device keeps its port.** The assignment is remembered on the Mac, in
`$RDIR/ports.map`, so a driver that died and came back is on the same number as
before and nothing that cached it is now pointed at a different simulator.

```sh
$SKILL/bin/drivers.sh ports          # who holds what
$SKILL/bin/drivers.sh ports adopt    # write down what is already running
$SKILL/bin/drivers.sh ports forget [<udid>]
```

Ports used to be handed out lowest-first among the drivers currently alive, and
Maestro tears a driver down on every CLI or MCP run, so numbers moved. Twice on
16 Sep 2026: an iPad's driver came back on 22087, which was the iPhone 16 Pro
Max's port; and a session holding relay 9105 sent 22 swipes to **another
session's iPhone** after a restart moved its iPad to 9106. `ports adopt` is for
a Mac whose drivers predate the map — it writes down what is running and
restarts nothing.

Resolve the relay port on every call rather than caching it, even so.

**Bare `drivers.sh up` walks every booted simulator**, which is a ~30s
xcodebuild each and restarts a peer's driver under them. It now names the
devices another session has labelled on the wall before it does. Name yours:
`drivers.sh up <udid>`.

**Naming a device on the MCP server or the CLI destroys that device's driver,
and then answers about a different device.** Measured 12 Aug: with the iPad on
22087 and the iPhone on 22088, `maestro --device <iphone> hierarchy` tore down
the iPhone's driver, found the iPad's alive on 22087, and returned the iPad's
hierarchy. The MCP tools behave the same way, and so does a run that fails —
the teardown happens when the command finishes either way (measured again
13 Aug with three drivers up; the other two were untouched).

The damage shows up one call later, on whatever tries to use that device next,
which is what made it cost ten minutes in a real session. `drivers.sh` now
records what it started, so `driver.sh` can say the driver was taken rather
than that there never was one, and name what takes them:

```
no driver for BA42FF52-....
  bin/drivers.sh up started one on port 22088 at 15:51, and it is gone.
  Running Maestro against a device destroys that device's driver when it
  finishes — the MCP server, bin/hier.sh, bin/flow.sh, bin/shot.sh.
  No other device is affected: the other 2 still have theirs.
  bring one up:  bin/drivers.sh up BA42FF52-...
```

`drivers.sh list` shows the same thing as `was 22088 / GONE`. Bringing it back
is about 30 s.

`bin/preflight.sh` answers repo state, app installed, debug session, VM service,
the count of journeys and flows already written for this project, and the
documentation mirror's version in one round trip.

Its working-tree line separates **build residue** from real changes:

```
branch     unit/PROJ-1788-automated-logout-phase
residue    ios/Podfile.lock pubspec.lock
           regenerated by any build, and tracked, so a branch switch
           stops on them. Discard when they are not a real change:
             git -C <repo> checkout -- ios/Podfile.lock pubspec.lock
untracked  1 file(s) — these do not block a branch switch
```

Lock files and generated xcconfigs are rewritten by every build and are tracked
in most projects, so `git checkout <branch>` refuses to move until they are
dealt with — and in a flat `git status` they look exactly like work somebody
did. The command is printed and **not run**: a `Podfile.lock` change can be a
genuine dependency update, and only whoever made it knows which it was.

**Read the "is that the code under test?" block before trusting anything on
screen.** It compares the installed build's timestamp with the newest commit in
the Mac's checkout. A build older than that commit cannot contain it, and
preflight says so plainly. Two separate sessions worked this check out from
scratch and **both found the simulator running a build from another branch** —
without it, both reviews would have been worthless.

A build *newer* than the commit is not proof it came from that branch, because
a checkout can move after a build, and the wording says as much. When that
matters, set `BUILD_MARKER` in the project conf to a string only the build under
test contains — a widget key, a feature-flag name — and preflight greps the
installed bundle for it. That costs about a second on top.

**Reviewing several branches at once** (item 24): the driver ports, the VM-service
cache and the published-relay state are already per device, so `DEV=<udid>` keeps
concurrent sessions apart. Two things are on you. `BUILD_MARKER` stops being
optional — every flavour-dev build shares one bundle id, so with several worktrees
the timestamp check is ambiguous and the marker is the only thing that says which
branch is installed. And each concurrent run must use its **own checkout or `git
worktree`**: `build.sh` builds whatever is checked out, and anything that runs
`git checkout` on the shared repo moves HEAD out from under live work — a silent
clobber, not just a limitation.

If preflight says the docs mirror is stale, say so to the user and offer
`bin/docs-refresh.sh` — which downloads on the Mac, because there is no route to
the internet from here. Never treat it as a blocker; the pages are still mostly
right, but check anything version-sensitive against `maestro <cmd> --help` on
the Mac.

**5. Ask before building or starting a debug session.** Preflight also says
whether a `flutter run` is active. The app is expected to be on the simulator
already; `bin/build.sh` exists for when it is not, and **must not be run
unprompted**.

If there is none, driving is unaffected: taps, journeys and the hierarchy all
work. The only thing missing is network visibility — the Dart VM Service exists
only when the app was started by `flutter run`, so after a `launchApp` or
`driver.sh launch` both `bin/net.sh` and `bin/publish.sh` come back empty. That
looks like a broken relay and is not one.

**Do not start one unprompted.** It rebuilds and reinstalls, replacing whatever
build is on the simulator — which may be the very thing under test — and takes
minutes. Say what is missing, say what it costs, and let the user decide. The
same goes for `bin/build.sh`.

`bin/build.sh --detect` is the safe half and the right thing to run before
asking: it reads the repo on the Mac and reports what a build would use,
building nothing.

```
flutter    /Users/…/repo/.fvm/flutter/bin/flutter
           Flutter 3.41.9 • channel stable • …
cocoapods  not on PATH; using GEM_HOME=/Users/…/.gem
flavour    dev — the only one whose bundle id is acme.e.brandco.runner.dev
target     lib/main_dev.dart
last build /Users/…/build/ios/iphonesimulator/Runner.app (2026-08-13 14:56)
```

Three things it works out rather than being told, because each of them presents
as a different problem than it is:

- **The SDK.** A repo that pins with fvm has no `flutter` on any `PATH`, not
  even the login shell's, and a bare `flutter` says "command not found" — which
  reads as a broken install rather than a version manager doing its job. The
  pinned SDK is preferred over anything on `PATH`, because it is the version
  the project expects.
- **CocoaPods.** Installed under a different Ruby, the build stops with
  "CocoaPods is installed but broken". `GEM_HOME` is set only when `pod` is
  genuinely missing from the PATH the build will have — setting it when it is
  not needed breaks a working install just as easily.
- **The flavour.** A flavoured project has no `lib/main.dart`, so a plain
  `flutter build ios` fails with 'Target file "lib/main.dart" not found'. The
  flavour is derived from `APP_ID`: Xcode names each build configuration
  `Debug-<flavour>` and each carries its own `PRODUCT_BUNDLE_IDENTIFIER`, so
  the app being driven can be traced back to the flavour that produces it. If
  that is not decisive it lists the candidates and **refuses** — building the
  wrong flavour installs a different bundle id and leaves the app under test
  untouched, which nothing reports.

Then `bin/build.sh` builds and installs onto `$DEV`, or `--all` for every
booted simulator. Measured 13 Aug 2026: 36 s end to end for an incremental
build, 22 s of it Xcode. `--no-install` builds without installing;
`BUILD_FLAVOR` and `BUILD_TARGET` in the conf override the discovery for a
project where it cannot be decided. It exits non-zero if a requested install
does not land — and confirms the bundle is actually on the simulator afterwards
— so a detached run that built but installed nothing fails loudly rather than
looking done.

If they say yes, start it detached, because nothing on this side survives the
call. Flutter is often not on `PATH` at all: check the repo for `.fvm/flutter`
or `.fvmrc` and use the pinned SDK, since that is the version the project
expects.

```sh
bin/mac.sh 'nohup ./.fvm/flutter/bin/flutter run -d <udid> \
              > /tmp/flutter-run.log 2>&1 & sleep 2; tail -3 /tmp/flutter-run.log'
bin/publish.sh          # once it is up — the VM service port is new every time
```

Detached means no hot-reload keys; stopping it is `pkill -f flutter_tools` on
the Mac.

**Re-run `bin/publish.sh` after any restart, including a hot restart.** It
publishes the relay, finds the live isolate and turns dart:io HTTP profiling
on. All three change together: a restart gives a new isolate, on a new port,
with profiling off again — and an unrecorded profile looks exactly like an app
that made no calls. `publish.sh` prints what it found and where the state file
is; `bin/net.sh` says which of the two an empty list was.

## Driving

```sh
bin/driver.sh nodes                    # every node, frames included
bin/driver.sh rows "Request ID"        # every match in draw order, one line each
bin/driver.sh find "CONTINUE" --explain # what a pattern matches, and the arithmetic
bin/driver.sh tapon "^CONTINUE$"       # resolve, tap, wait for the screen to settle
bin/driver.sh type "^Search$" "some text"
bin/driver.sh expect "^Home$"          # now; or "^Home$" 15 to wait up to 15s
bin/driver.sh script reset.journey full.journey
```

Exploring is act, look, decide, and the looking does not need its own call.
`--tree` or `--nodes` directly after the verb prints the screen once the action
has settled, so the pair above becomes one round trip:

```sh
bin/driver.sh tapon --tree "^CONTINUE$"
bin/driver.sh tap --nodes 200 483
bin/driver.sh type --tree "^Search$" "some text"
```

It goes after the verb and never at the end, because `type` takes the rest of
the line as the text to type. The screen is printed even when the action failed
— that is the moment you want to look at it.

**When two actions in a row leave the tree byte-identical**, `driver.sh` says
so: that is what a simulator with dead touch injection looks like — reads keep
working, writes are discarded, and every verb still reports ok. `driver.sh probe`
taps the blank point and reports whether the screen moved. It will say
*inconclusive* rather than claim a pass, because a screen that ignores a tap on
empty space is normal. A wedged simulator is not fixed by restarting its driver;
the driver is answering fine. Shut it down and boot another.

**A screen is usually a list.** `find` diagnoses one element and refuses when
several match; `rows` prints them all, in draw order, one line each, with
whether each is genuinely visible (`vis`), off the viewport (`off`), under the
keyboard (`kbd`) or reported zero-sized (`zero`). Fixed columns and no
diagnostics mixed in, so two readings of the same screen can be diffed — which
is the only way to answer "did anything leave the list while nobody touched it".
`--json` for a machine. **An empty list is a result, not an error:** it prints
`n=0` and exits 0, because a list that has emptied is usually the finding.

## Watching for a change nobody causes

`expect` waits for one element to appear or clear, in the foreground, against a
timeout. When the question is *did the list change while nobody touched the
device* — a row ageing out, a status arriving on a poll, an item pushed off the
page by something new — that is `watch`:

```sh
bin/driver.sh watch "Request ID" --context "^(Open|All)" --interval 25
bin/driver.sh watch status          # is it actually running? how many samples?
bin/driver.sh watch stop
```

**Start it with the harness's `run_in_background`, not `nohup`** — see rule 9 —
and read its log as it goes. One sample per interval, one line each, with a
`>>> CHANGE` line naming what arrived, what left and what moved. Four things it
does that a hand-written poll loop kept getting wrong:

- **No deadline.** It runs until `watch stop`. A watcher given a fixed number of
  checks ended ten minutes before the event it existed to catch, and the whole
  run had to be set up again.
- **A failed read is not "no change".** A cycle that cannot read the device logs
  `ERR` and leaves the baseline alone, so a dropped driver can never be recorded
  as the list holding steady.
- **`--context` goes on every line.** Whatever it matches — the filter chip, the
  tab, the mode — is written beside every sample, so the log proves which view
  was being watched. One watcher spent an afternoon on the wrong filter.
- **One watcher per device.** A second `watch` on a watched device refuses and
  names the first, because two writing one log makes every change arrive twice.

`watch status` will say **`NOT watching`**, and that is its job: the worst
failure here is a session reporting that it is watching when the start was
refused at the permission prompt and nothing is running.


## Write journeys as you go

A **journey** is a text file of those lines, chained with `include`, with
`${VAR}` from the environment. They live in the project — `maestro/journeys/`
beside the conf file, or wherever `JOURNEY_DIR` points — and a bare name passed
to `script` is looked up there. None ship with this skill.

**The moment a sequence of steps works, write it down before moving on.** That
is the whole economy of this toolkit: discovering a screen costs a round trip
per action with a decision in between, and replaying it costs about 1.3 seconds
an action with none. A 34-step journey that took fifteen minutes to work out
runs in under a minute afterwards, and the difference is almost entirely the
model being out of the loop.

Do not wait until the end of a journey to write it down. Write each screen as
you get it working, so a failure three screens later does not cost the two that
already worked.

How to split them:

- **One file per screen boundary.** A unit starts on a known screen and ends on
  a known screen. That is what makes it swappable.
- **End every unit with `expect`.** It is the unit's contract, and it makes a
  wrong assumption fail on the line that caused it.
- **Parameterise the data, not the structure.** Stores, PINs, search terms and
  sizes are `${VAR}`; the steps are not.
- **Keep the state reset in its own file**, and say in a comment what state it
  assumes. Relaunching usually restores a session rather than clearing it.
- **When a step has to differ:** change a variable first; recompose units on the
  command line second; fork a unit only when the *steps* differ, and keep both.

**Changing a journey goes through `bin/journey.sh`, not a hand-rolled
replace.**

```sh
$SKILL/bin/journey.sh edit 01-signin.journey --replace-once '<old>' '<new>'
$SKILL/bin/journey.sh edit 01-signin.journey --replace-once '<old>' '<new>' --dry
```

`--replace-once` is the only mode, deliberately. A replace whose `old` is absent
**exits 3 and writes nothing**, naming the closest line in the file and saying
when the two differ only in whitespace; one that matches more than once exits 4
and writes nothing. The idiom this replaces — `s.replace(old, new)` in a heredoc
— rewrote the file byte-identical on a miss and reported success, so a failed
edit read as an edit that did not help, and the next thing anybody did was
re-run the journey and take the result as a fact about the app.

**Trying a variant needs no file.** `script --steps 'tapon "^X$"; expect "^Y$"'`
runs a sequence inline — `;` or a newline separates the steps — so recomposing
units on the command line is something you can actually do. Write it down as a
file the moment it works; the inline form is for the trying, not for keeping.

Format, the failure output, and a worked six-file example:
`reference/journeys.md`.

## Keep the app notes

Everything measured about a specific app goes in the project's own notes file,
created from a template:

```sh
$SKILL/bin/notes.sh init      # writes maestro/app-notes.md from the template
$SKILL/bin/notes.sh path
```

`bin/init.sh --write` does this as part of setting a project up, so a project
that starts with nothing ends up with the file, the headings and the rules for
filling them in.

**Two kinds of finding do not belong here, and each has its own home.** The app
notes are read at the start of every session, so they have to stay short —
every entry that is not about driving *this app* dilutes the ones that are.

- A finding that would still be true of a **different app** — something about
  Maestro, iOS, or the driver — is not app-specific. Put it in the project's
  `maestro/tooling-findings.md`, not under an app heading. The test is not "does
  it mention Flutter" but "would it still be true of another app". (When
  something like that is worth folding back into the skill for every project,
  that is a person's job from the source repo, never a project session editing
  the symlinked skill — see item 17.)
- A finding about what is **wrong with** the app — a bug, a wrong value, a
  handler that does nothing — is not a driving measurement. It belongs in the
  project's bug or test findings, not here. The app notes are *how to drive* the
  app, not *what is broken in* it.

When unsure, `tooling-findings.md` is the safer home: this file is the one that
must not grow unreadable.

**It is read at the start of every session, so its size is everybody's
problem.** `bin/preflight.sh` prints the line count and says when it is past the
threshold; `bin/notes.sh archive` opens a dated archive beside it and lists the
entries that look superseded. It moves nothing by itself — only a person can
tell a superseded measurement from a current one, and a wrong note somebody has
already acted on is worth keeping findable. One project's notes reached 1,302
lines before anything measured them.

**Nothing writes to it for you.** Append at the moment of the finding, with one
command, before the next action:

```sh
$SKILL/bin/notes.sh add "bounds" "Dropdown row reported y=91, true y=259 — overlay offset 168pt; Maestro taps y=115."
$SKILL/bin/notes.sh add "screen quirks" "Search screen: keyboard covers below y=538; rows under it take the tap."
```

The section is matched by case-insensitive substring, so a rough name finds the
right heading, and an unknown one starts a new section. Entries are dated.

**Write one whenever any of these happens** — this is the checklist, not a
habit to remember:

- a tap or a resolve failed and you worked out **why**
- you found a label or pattern that works, and copied it verbatim
- you measured something that will be needed again: a frame, an offset, a
  timing, a threshold
- you tried something that did **not** work, so nobody tries it again
- you established what a reset actually does on this app
- a journey unit reached a working state — record it in the Journeys table

The bad run is when this matters most and when it is most likely to be skipped.
If you are three failures deep and have just understood one of them, that
understanding is the note.

What goes in it:

- A number read off the device, together with the reading that produced it.
- A label copied verbatim from the hierarchy.
- A behaviour seen, with how well it is known — see below.
- A thing tried that did not work, so it is not tried again.

**Every note says how well it is known**, and `bin/notes.sh add` will not write
one without it: `--measured`, `--once`, or `--inferred`. Five notes have turned
out to be wrong and every one was written from a single sighting stated as a
fact — two of them lived in this skill's own example notes and taught a method
that does not work. A note carrying `seen once` is a lead: check it before
relying on it, and promote it to `measured` when it holds.

**A note that contradicts what is on screen is corrected in place, then, before
carrying on.** Not worked around, not left for the end of the task. Mark the
original wrong, add the correction as its own note with what was measured, and
leave the wrong version visible — the next reader has probably already acted on
it.

What stays out: anything not actually run; anything true of Maestro or iOS
generally, which belongs in this skill's `reference/` instead; screenshots as
evidence for positions; and credentials.

**A credential goes in `.maestro-mac.conf` and nowhere else.** That file is the
one a project keeps out of version control — the journeys, the flows and the
notes are all committed. Anything named `APP_*` in the conf is exported, so a
journey says `${APP_PIN}` and the value stays in one gitignored place:

```sh
: "${APP_PIN:=1234}"             # .maestro-mac.conf
type "^Passcode$" ${APP_PIN}     # the journey
```

`bin/notes.sh add` refuses a note containing one, and `bin/secrets.sh check`
searches everything git would commit for a value that got in another way.

**Establish first whether the app reports bounds correctly** — the template
opens with that check, because it decides whether Maestro selectors can be
trusted at all, and everything else follows from the answer.

`reference/apps/example-app.md` is a filled-in example of what one looks like
after two days on an app whose bounds cannot be trusted. Its measurements are
real; every name and code in it is invented, because nothing app-specific ships
with this skill.

## The rules that matter most

1. **Batch.** Making calls faster buys almost nothing; making fewer calls buys
   everything. A journey of 34 steps runs in 48 seconds against 15 minutes of
   one-action-per-round-trip. Of that saving, 7.5 s is process startup and the
   rest is not stopping to think between steps. **The unit of work is a journey
   file, not a driver call.** Before driving any screen, check whether a journey
   starts there — a journey's header names its starting screen, so this is a
   one-line check, not a reading exercise. If one does, run it; if none does,
   write one as you go. Listing `maestro/journeys/` is not enough — the directory
   has been listed and the screen hand-walked anyway.
2. **Never author a selector from a screenshot.** Copy the text verbatim from
   the hierarchy. Maestro's `text:` is a full-string regex, so a partial string
   does not match.
3. **Do not trust reported bounds — and do not carry a coordinate across
   calls.** A tap on a matched element is a tap on the centre of its reported
   bounds, so wrong bounds defeat every selector equally. `resolve.py` derives
   the true point from marker nodes in the tree; use `find --explain` when an
   answer looks wrong. A form shifts 80–140 points when a keyboard opens or a
   menu closes, so a coordinate read in one call and tapped in the next lands on
   nothing. Resolve and tap in the same call. On the iPad, set the device to the
   app's orientation first (`driver.sh orient landscapeLeft`), then `tapon` — the
   resolver sends the right point and the driver rotates it. Only raw-`tap` a node
   the tree cannot reach (the nav rail, item 26), and then send app-space
   coordinates — never a hand-rolled `834 - app_y`, which lands nowhere (measured,
   item 57). Full rule in `reference/driving.md`.
4. **A resolved point is not always reachable.** Off the screen, or under the
   keyboard, and the tap silently goes elsewhere. The resolver refuses both
   (exit 5); the fix is `driver.sh dismiss` or a `swipe`, then an `expect` on
   what the tap did. `dismiss` taps the emptiest point on the screen and, if
   that leaves the keyboard up, presses return — iOS offers nothing else, and
   which of the two works depends on the app. It says which it used, because
   return submits the focused field. The refusal prints the arithmetic behind it —
   check that against `driver.sh nodes` rather than against a screenshot before
   using `--anyway`. One was overridden on the strength of a screenshot on
   12 Aug and typed a stray character into the field underneath.
5. **Never add a `sleep` after a driver call.** Every action verb — `tapon`,
   `tap`, `type`, `text`, `key`, `button`, `erase`, `swipe`, `launch`, on the
   command line and in a journey alike — waits for the screen to go still
   before it returns, so a sleep after one waits for something that has already
   happened. Four earlier sessions added 154 of them, one to six seconds each.
   `isScreenStatic` stays false while a spinner turns, so the wait covers
   backend latency and not just animation; `SETTLE=0` turns it off for a screen
   that never stops moving and `SETTLE=<n>` shortens it.
6. **Assert inside the batch, and a filled field is not a set value.** Every
   journey unit ends with an `expect`, so a wrong assumption fails on the line
   that caused it. Maestro and the driver both report success for a tap that hit
   nothing. A control showing the right string may have committed nothing; assert
   the committed value — an `expect` on what the form now reads, or a read-back —
   never the text visible in the field.
7. **Read state from the app, not from pixels.** Network first (the Dart VM
   Service in a debug build), then the hierarchy, then source, then screenshots
   — and screenshots only for questions genuinely about appearance.
8. **Never restart the app in response to a failure.** When a journey fails or
   the screen is in an unexpected state, read the hierarchy — it already carries
   the field values, placeholders and layout. Decide from what it shows: dismiss
   a keyboard, tap what is already on screen, or run a different journey.
   Restarting discards state that was already correct (a remembered store, a
   completed login) and costs 30–60 seconds. On 14 Sep a session restarted
   twice after a journey failure, lost the stored store both times, and then
   failed the login journey because the screen it expected was gone. Reading the
   hierarchy would have shown the store was already set.
9. **Put residency on the Mac.** Every Bash call here is its own PID and network
   namespace, so no tunnel, socket or background process survives. The Mac has
   no such limit and is reachable by name over HTTP through the sandbox proxy.
   Where something must run on this side across calls — a watcher, a sampler, a
   long poll — `nohup … &` is not it: it returns a pid, prints nothing wrong and
   is dead by the next call (measured; 21 attempts over 15-16 Sep). The
   harness's `run_in_background: true` is the mechanism that survives, and
   `Monitor` with an until-loop is how to wait for one. Anything started that
   way starts outside the project, so pass `MAESTRO_MAC_CONF` to it.
   `reference/connection.md` has all three with their measurements.
10. **Before waiting for a timed state, find the three ways to reach it.** Name
    the event, then name how it could be reached by *waiting*, by a *backend
    action*, and by a *config override* — and say which you are taking and why,
    before the waiting starts. 15 Sep 2026 went from 12:46 to 21:56 across two
    sessions waiting for request TTLs to expire so a list would shed rows; at
    18:55 it turned out a **cancel** produces the same shed, and the next
    afternoon that took forty-two seconds. Where the project has an API client,
    the backend action is usually there already. Item 58's warning still applies
    to the third route: a timer fudged in the app's source races the driver's own
    latency, and a fudged build must be rebuilt from clean source before any real
    verification.
11. **Test before you report a capability impossible.** The shipped docs mirror
    and the skill's own assumptions are not authority over an empirical test on
    the connected device. The mirror said iOS physical devices are unsupported;
    the binary drove one. Before telling the user something cannot be done, try
    it on the device and report what happened.
12. **A conf credential lives only inside this toolkit's own process.**
    `bin/config.sh` exports `APP_*` into the script that sources it — `driver.sh`,
    a journey, a flow — not into your shell. So `${APP_PIN}` in a hand-built Bash
    command expands to nothing, four PIN attempts send an empty string, and the
    app answers "please enter the pin" as if the field were broken. Type a
    credential through a journey line or a flow, never a raw shell command with
    `${APP_PIN}` in it. Same shape as rule 2 — a plausible-looking action that
    silently does the wrong thing — with a worse failure mode, because an empty
    credential reads as an app defect rather than a tooling one.

## Reference

Read the one that matches the problem; none of them are needed up front.

**Where this skill lives, and where to write a finding about it.** The source is
the `maestro-remote-mac` git repo, whose `skill/` directory is this one.
`~/.claude/skills/maestro-remote-mac` is either a symlink to that `skill/`
directory (`./install.sh --link`) or a copy of it taken from a release tarball
(`./install.sh`). Check which before editing:

```sh
readlink -f ~/.claude/skills/maestro-remote-mac
```

**If it is a copy, anything you write under the `~/.claude/skills` path is
thrown away by the next install** — and a `find` under `~/.claude` does not
follow a symlink either, so the source can read as missing rather than as
elsewhere. Under the old `ship.sh`/`build/` arrangement that cost two sessions:
findings written into `build/…/reference/`, and a rival `BACKLOG.md` created
because the real one looked gone. `./install.sh --link` is what removes the
trap, because then the live path and the checkout are the same directory.

A change wanted in this toolkit goes in that repo's `BACKLOG.md`, appended and
numbered on, with the measurement next to the claim. Check for an existing item
first and add a sighting to it rather than a new number. Do not edit `bin/` to
fix it yourself.

| file | when |
| --- | --- |
| `reference/setup.md` | installing this on a new machine — Mac prerequisites, SSH config and proxy routing, hosts, settings, MCP registration |
| `reference/driving.md` | the method in full — reading state, selectors, wrong bounds, batching, preflight |
| `reference/driving-discipline.md` | how to *use* the toolkit well — the rules with their evidence, and where the next skill-usage lesson goes (here, not a project's memory) |
| `reference/journeys.md` | the journey file format, and how to split one into units |
| `reference/driver-api.md` | the driver's undocumented HTTP API, and what Maestro does to bounds (nothing) |
| `reference/maestro-notes.md` | Maestro's own surface: commands, mechanisms, config, CLI flags, YAML traps |
| `reference/connection.md` | SSH, the sandbox proxy, relays, what survives a call |
| `reference/app-notes-template.md` | the template a project's own notes are made from, and the rules for what goes in |
| `reference/apps/example-app.md` | a worked example of filled-in app notes, with invented names |
| `docs/pages/` | a 154-page mirror of the Maestro documentation (2.8.0). Grep it; there is no route to the internet from here |

## Scripts

| script | does |
| --- | --- |
| `bin/init.sh` | detect candidates, write `.maestro-mac.conf`, lay out `maestro/` |
| `bin/notes.sh` | create, locate, append to or archive the project's app notes |
| `bin/journey.sh` | edit a journey with a replace that fails loudly when it does not match |
| `bin/secrets.sh` | has a credential from the conf escaped into a committed file? |
| `bin/docs-check.sh` | is the bundled docs mirror still the installed version? |
| `bin/docs-refresh.sh` | re-download the mirror (runs on the Mac) |
| `bin/drivers.sh` | a driver per simulator, each on its own port — list, up, down, ports, rig |
| `bin/driver.sh` | the driver API: read, resolve, tap, type, swipe, run journeys |
| `bin/resolve.py` | label pattern -> true point (used by `driver.sh`) |
| `bin/jtok.py` | split a journey line into arguments, then expand `${VAR}` in each |
| `bin/typed.py` | did the text `type` sent actually land on screen? |
| `bin/tree.py` | render a view hierarchy as an indented tree (used by `driver.sh`) |
| `bin/watch.py` | sample a list until it changes, and say what changed (used by `driver.sh watch`) |
| `bin/img.sh` | crop, rotate and shrink a PNG, on whatever tool the machine has |
| `bin/build.sh` | build the app on the Mac and install it — **never unprompted**; `--detect` only reads |
| `bin/wall.sh` | every booted simulator, live, on one page — start, stop, status, log, label |
| `bin/viewer.sh` | find the live Maestro viewers and republish one; not for watching |
| `bin/preflight.sh` | one SSH call: repo, is the installed app the code under test, driver, VM service |
| `bin/publish.sh` | republish the Dart VM Service after an app restart |
| `bin/net.sh` | what the app requested and what came back |
| `bin/mac.sh` | run anything on the Mac with Java and Maestro on PATH |
| `bin/flow.sh`, `bin/hier.sh`, `bin/shot.sh` | Maestro CLI paths, for a real flow or a Maestro artifact |
| `bin/bench.sh` | re-derive the timing numbers after a Maestro upgrade |
