# maestro-drive — backlog (done)

Finished items, in number order. Open items are in `BACKLOG.md`.

## 1. One driver, one port — a second simulator cannot be driven — **DONE**

**What.** `McpMaestroSessionManager` keeps a `ConcurrentHashMap<deviceId,
session>` with no invalidation path and hardcodes `127.0.0.1:22087`. A second
device gets a second session object pointing at the same port, where the first
device's driver is still listening. MCP returns whatever device is on 22087 at
the time: with the iPad's driver there, `inspect_screen` for the iPhone's UDID
returned the iPad's tree.

**Why.** The wrong device's screen comes back looking exactly like a correct
answer. A screenshot requested for the iPad returns the iPhone.

- Reconnecting the MCP server, then touching the new device first, is the only
  thing that rebinds it.
- `pkill -f maestro-driver-ios` makes it worse: every later MCP call fails with
  `Device became unreachable during deviceInfo`.
- `maestro --device <udid>` from the CLI is ignored while another driver holds
  the port.

**Done.** `bin/drivers.sh` starts one driver per simulator, each on its own
port, using Maestro's own build products and `xcodebuild test-without-building`
with `TEST_RUNNER_PORT`. The port reaches the runner as `PORT`, which
`XCTestHTTPServer.swift` reads. `driver.sh` resolves the port from `DEV`.
Verified with an iPhone and an iPad driven simultaneously: a `launchApp` on one
left the other untouched. About 30 s cold per device, 12 s warm; reads
unchanged at 0.43 s. Mechanism in `reference/driver-api.md`, rules in
`SKILL.md`.

## 2. `DEV` does nothing for `driver.sh` — **DONE**

**What.** `driver.sh` never called `_dev()`; it talked to whatever driver was on
port 22087. `DEV` only reached `hier.sh`, `flow.sh`, `net.sh`, `publish.sh`,
`preflight.sh`, `shot.sh` and `bench.sh`. `SKILL.md` stated "Pin it before a long
run — the driver is per-device", which was false.

**Why.** `export DEV=<udid>` before a `driver.sh` command looked like it
targeted that device and did not. Commands went to whichever device held 22087.

**Done.** Built with item 1. `DEV=<udid>` selects the device for every
`driver.sh` command. With one driver and no `DEV` it uses that one; with
several and no `DEV` it refuses and lists them. The device-to-port map is read
from the live runner processes on the Mac: each runs out of its simulator's data
container, so its command line carries the UDID. Nothing needs keeping in step
by hand.

## 3. `net.sh` returns nothing — HTTP profiling is off by default — **DONE**

**What.** `ext.dart.io.httpEnableTimelineLogging` is off until something turns
it on, so `net.sh` returned an empty list with no explanation. A hot restart also
resets the flag.

A second cause: `remote/vmservice.sh`'s `valid()` accepted any reply containing
`"type"`. A collected isolate returns `{"type":"Sentinel","kind":"Collected"}`,
so after every hot restart the cached isolate passed validation and `net.sh` read
an isolate that no longer existed.

**Why.** An empty request list reads as a wrong isolate or a non-`dart:io`
client, and network capture gets abandoned. Both faults fire together after a
hot restart.

**Done.**

- `publish.sh start` reads the flag, turns it on, and reports which it was:
  `was off, now on — only calls made from here on are captured`, or
  `already on`.
- `net.sh` on an empty list checks the flag and says either that profiling was
  off, is now on, and the action should be repeated; or that profiling is on and
  the app has made no calls.
- `vmservice.sh` requires `"type":"Isolate"`.

Verified against a Flutter app on an iPad: capture works, both empty-list
branches print the right message, and repeating the action then shows the
request.

## 4. `published.state` cannot be found without reading the source — **DONE**

**What.** `LDIR` is defined only inside `config.sh`, so an ad-hoc VM service
call meant hunting for the state file first.

**Why.** Locating the file took five or six calls (`find`, greps of `lib.sh` and
`config.sh`, then sourcing it).

**Done.** `publish.sh start` and `publish.sh status` both print a labelled
block: base URI, isolate, profiling state, state file path, and the two ways to
read it — `net.sh`, or the exact two lines for an ad-hoc curl.

## 5. Building the branch on the Mac is not in the skill — **DONE**

**What.** Building a Flutter app on the Mac needed three facts worked out by
hand: the fvm-pinned SDK (`.fvm/flutter/bin/flutter`, nothing on `PATH`),
CocoaPods' `GEM_HOME=$HOME/.gem` with `$GEM_HOME/bin` on `PATH`, and the flavour
(`--flavor dev -t lib/main_dev.dart`).

**Why.** Working it out took 4.5 minutes against a 62-second build. Kept in a
per-project memory, each new app on the same Mac paid it again.

**Done.** `bin/build.sh` (local) and `remote/build.sh` (on the Mac), one round
trip. All three are worked out from the repo, not configured:

- **The SDK**, pinned first: `$REPO/.fvm/flutter/bin/flutter`, then the older
  fvm layout, then the version in `.fvm/flutter.version` under `~/fvm/versions`,
  then `PATH`, then the usual install locations. Pinned wins over `PATH`
  because it is the version the project expects.
- **CocoaPods**, only when needed. `GEM_HOME` is reported only if `pod` is
  absent from the build's `PATH`; setting it when not needed breaks a working
  install.
- **The flavour, from the bundle id.** Xcode names each build configuration
  `<Debug|Release|Profile>-<flavour>` and each carries its own
  `PRODUCT_BUNDLE_IDENTIFIER`, so `APP_ID` traces back to its flavour. A flavour
  counts only if both an Xcode scheme of that name and a
  `lib/main_<flavour>.dart` exist. That discards template entrypoints
  (`main_env.tpl.dart`), extension schemes, and either half alone. If the bundle
  id is not decisive it lists the candidates and refuses: the wrong flavour
  installs a different bundle id and leaves the app under test unchanged, with
  nothing reporting it.

`--detect` reports without building. `SKILL.md`'s rule that nothing builds
unprompted is restated; the script existing is not permission to run it.
Bitbucket access from the Mac is item 22.

Verified with a real build: 36 s end to end on an iPhone 16 simulator, 22 s of
it Xcode, then confirmed by item 6's check. Seventeen offline tests against a
fake repo of the same shape.

## 6. Nothing checks the installed app is the code under test — **DONE**

**What.** `preflight.sh` reported the repo branch and whether the app was
installed, but never compared them.

**Why.** A simulator running a build from a different branch, or a Mac checkout
on a different branch from the local one, makes every observation on screen
worthless. The manual check (`simctl get_app_container`, then grepping
`Frameworks/App.framework/flutter_assets/…` for a branch-only string) took three
or four calls.

**Done.**

- `remote/appcheck.sh` reads the installed bundle's executable timestamp and
  version from `Info.plist`, compares it with the newest commit in the Mac's
  checkout, and says which is newer. A separate file so it can be tested off a
  Mac; sent base64-encoded inside preflight's command, so preflight stays one
  round trip.
- `BUILD_MARKER` in the conf: an optional string only the build under test
  contains. Not named `APP_*`, because those are exported as project values and
  searched by `secrets.sh` as credentials. Adds about a second.
- Older than the newest commit is reported as STALE. Newer is not proof of the
  branch, because a checkout can move after a build, and the output says so.

Two silent bugs caught by the tests: `stat -f` exists on GNU too, where it means
file-system status and prints a block count; and reading a plist value from the
line after its key returns the next key's value when both sit on one line.
7 offline tests, with fixture timestamps on both sides of the comparison.

## 7. Exploration is one action per round trip, plus redundant sleeps — **DONE**

**What.** Only the journey verbs settled after acting. On the command line only
`tapon` and `type` waited; `tap`, `text`, `key`, `swipe`, `erase` and `launch`
did not. An action and a read also took two calls.

**Why.** Without a settle, a `sleep` after those verbs was doing real work, so a
rule of "never sleep" was false. With one, sleeps after settling verbs were pure
waste: of 190 sleeps counted across four driving runs, 112 followed a verb that
already settled and 42 followed one that did not.

**Done.**

1. **The command-line action verbs settle**: `tap`, `text`, `key`, `button`,
   `erase`, `swipe`, `launch`, `orient`. A settle timeout warns on stderr and
   leaves the exit status alone. Journeys keep the stricter rule, where a
   timeout fails the step. `SETTLE=0` means do not wait.
2. **`--tree` / `--nodes` on every action verb**, read directly after the verb,
   printing the screen once the action has settled. Not at the end of the line,
   because `type` takes the rest of the line as text. The screen prints even
   when the action failed. Measured 2.29 s combined against 2.61 s as two calls.
3. **`SKILL.md` rule 5** names every verb and says never add a sleep. Also in
   `reference/driving.md`, `reference/driver-api.md` and
   `reference/journeys.md`.

The inline tree renderer moved to `bin/tree.py`, verified byte-identical against
all three fixtures in both modes. `driver.sh` is tested offline for the first
time, with a stub `curl` and stub `lib.sh` giving it a fake device that is
always up, still and showing a fixture. Eleven cases.

## 8. On iPad the resolver works in the wrong coordinate space — **DONE**

**What.** `/touch` takes app-space coordinates, and app controls need no
conversion. What iOS draws — the status bar, permission alerts, the keyboard —
reports frames in the device's native space, which on a landscape iPad is
transposed. `/deviceInfo` returns `1194x834`, the same as the app root, so it
cannot reveal the mismatch. The status bar can: it is always a thin strip along
one edge, and `24x1194` against a `1194x834` screen means the spaces are
transposed, with its `x` giving the direction.

**Why.** System alerts and keyboard-occlusion checks used the wrong space on
iPad, so `tapon` on system elements missed and drivers fell back to raw
`tap x y` with hand arithmetic. Raw `driver.sh tap` on a landscape iPad is
unreliable even with the correct hand conversion `(834 − app_y, app_x)`.

**Done.** In `bin/resolve.py`, `system_transform()` converts system-drawn nodes
from native space into app space, and `keyboard_band()` takes the keyboard's top
edge from its size rather than its position. `tapon "^Allow$"` dismisses the
notification permission dialog first time, and a login journey runs unmodified
on the iPad. Covered by `test/run-tests.sh` with fixtures from both devices.

Verified in `landscapeLeft` on an iPad Pro 11-inch: `tapon` on a card's label
opened it first time where a raw `tap` at the hand-converted centre did nothing
twice. On iPad, use `tapon`, not raw `tap`. The navigation rail has no
accessibility entries and cannot be resolved by selector; that is item 26.

## 9. The occlusion refusal does not say what is covering the element — **DONE**

**What.** The keyboard-occlusion refusal gave no reasoning, so it could not be
told apart from a false positive.

**Why.** A correct refusal overridden with `--anyway` typed a stray character
into the field under the keyboard. The guard has since been fixed in both
directions (item 8), so the refusal is now trustworthy and naming the cause is
worth doing. The advice must not point at filter-then-return: item 14 measured
that the list does not always filter and `key return` commits nothing.

**Done.** The refusal shows its working: the element's centre, the keyboard's
top edge, how far below it the centre is, and how the edge was computed — the
screen height less the keyboard's thickness, measured from named containers
(`SystemInputAssistantView`, keyboard) by size, because their positions arrive
in the device's own space. It then says to dismiss the keyboard or scroll the
element clear, and to assert the result with `expect`. Printing positions next
to an app-space edge would invite the coordinate mistake the guard exists to
prevent, so it prints sizes and says why.

The off-screen refusal says which way and how far past the edge, and warns that
a node at `0,0 0x0` is off a scrolling container's viewport and dismissing the
keyboard does not bring it back.

`find --explain` carries the same reasoning. `keyboard_band` was split into
`keyboard_geometry`, which returns the edge, the thickness and the containers,
with `keyboard_band` kept as a wrapper. Nine tests, including one that fails if
the advice ever points at filter-then-return.

## 10. `init.sh --host X --detect` does not look for the checkout — **DONE**

**What.** `--detect` reported simulators and installed apps but not where the
app's checkout was on the Mac.

**Why.** Finding it took several SSH calls (`ls -d ~/src/* …`, then `find ~
-maxdepth 4 …`).

**Done.** `--host <alias> --detect` lists checkouts under the Mac's home and
marks the right one, in the same call. `remote/findrepo.sh` prints
`<path>\t<origin>`; `init.sh` ranks them.

- **Matches on the remote, not the directory name.** `git@host:org/thing.git`
  and `https://host/org/thing` both reduce to `host/org/thing` (lowercased, no
  `.git`, scheme or user). A name-only match is shown, labelled as one.
- **Prunes caches**: `Library`, `.pub-cache`, `.gradle`, `node_modules`,
  `Pods`, `.fvm`, `.Trash`, `.cache`, `.cocoapods`, `DerivedData`. Measured
  4.3 s and mostly `.pub-cache` clones unpruned; 3.3 s and twelve real checkouts
  pruned.

Verified against a real Mac: twelve checkouts, the right one first and marked
`<- same origin`. The whole `--detect` call is 5.1 s.

## 11. No screenshot crop or rotate — **DONE**

**What.** Landscape iPad screenshots came back sideways, and cropping evidence
to the defect meant `sips -r 270` and `sips -c … --cropOffset …` by hand on the
Mac, or probing the Linux side for an image tool. PIL is not installed there;
ImageMagick may or may not be.

**Why.** Each crop or rotation cost several calls, and nothing guaranteed a tool
was present.

**Done.**

- `bin/img.sh` crops, rotates and shrinks a PNG in pixels. ImageMagick if
  present, `sips` if running on a Mac, otherwise the file goes to the Mac and
  back (1.8 s), where `sips` always exists. `IMG_BACKEND` pins the choice.
  `--size` reads dimensions from the PNG header.
- `driver.sh shot` delivers the picture upright and in app-space points:
  `--on <pattern>` crops to a named element with `--pad`, `--crop x,y,w,h` takes
  points, `--scale` shrinks, `--raw` opts out.
- `shot.sh` takes the same three pixel options via `img.sh`. It has no
  hierarchy, so the upright correction and `--on` are not available there.
- `resolve.py --space` and `--rect` take the rotation and crop from the existing
  status-bar reading, so there is one detection.

Measured: iPhone shot 0.6 s (no hierarchy fetched when picture and screen
agree), iPad shot 1.2 s including rotation. 15 offline tests.

## 12. Build residue in the Mac's checkout blocks a branch switch — **DONE**

**What.** A build regenerates the tracked `ios/Podfile.lock` and
`pubspec.lock`, and those changes stop a branch switch on the Mac. `preflight.sh`
showed only `git status --short | head -5`.

**Why.** The branch switch fails and the lock files have to be found and
discarded by hand. Restoring simulator or app state is out of scope: testing
rebuilds from scratch (`simctl uninstall`, `install`, `launch`, login journey,
under a minute), which guarantees a first-run screen.

**Done.** `remote/gitstate.sh`, folded into `preflight.sh`:

```
branch     <branch>
residue    ios/Podfile.lock pubspec.lock
           regenerated by any build, and tracked, so a branch switch
           stops on them. Discard when they are not a real change:
             git -C <repo> checkout -- ios/Podfile.lock pubspec.lock
untracked  1 file(s) — these do not block a branch switch
```

The command is printed, not run: a `Podfile.lock` change can be a genuine
dependency update. Untracked files are counted, not listed, because they do not
block a switch.

Bug fixed on the way: the loop was `while read -r st path`, and on the Mac's zsh
`path` is tied to `PATH`. Reading a filename into it emptied `PATH`, and later
preflight sections failed with `command not found: tail` and
`command not found: appcheck`. The variable is `_p`; a test fails if `path`
returns. Verified on a real Mac with both lock files modified by a build.

## 13. The CLI fallbacks are labelled for the wrong situation — **DONE**

**What.** `hier.sh`, `flow.sh` and `shot.sh` opened with "FALLBACK ONLY. Prefer
the MCP server", but the usual reason to use them is MCP being bound to the
wrong device (item 1), which they did not mention.

**Why.** A reader working out a wrong-device problem found no guidance in the
headers.

**Done.** All three headers name the port-22087 binding and warn that running
them affects the device's driver. The exact effect is item 15.

## 14. Filter-then-return picks the wrong entry in a searchable dropdown — **DONE**

**What.** The skill's example app notes taught filter-then-return (type into a
dropdown, then `key return`) as the way to drive a searchable dropdown whose list
renders under the keyboard. It does not reliably commit the right row. Three
causes:

- **Journey tokenising.** A journey line was `${VAR}`-expanded and then
  `shlex.split`, so a value containing a space became two tokens. `text` in a
  journey took `${a[1]}` (first token only), where `driver.sh text` on the
  command line joined `"$*"`. `type` took `${a[2]}` and dropped the rest. A
  truncated string still filters a list and matches something, so the failure
  was silent.
- **Non-searchable dropdowns.** In a Flutter `DropdownMenu`, `enableFilter`,
  `enableSearch`, `requestFocusOnTap` and the filter callback can all hang off
  one `isSearchable` flag. Two dropdowns on one screen can look identical while
  only one filters. Typing into the other appends to its text, and `key return`
  neither commits nor closes; the next tap elsewhere closes the list and commits
  the first row. The text field and the list are independent controls, so a
  correct-looking field is not a selection.
- **`key return` commits nothing.** It dismisses the keyboard and leaves the
  list open. Tapping the row commits reliably. Rows past the menu's viewport
  report `0,0 0x0` and stay that way after the keyboard is dismissed. An open
  dropdown survives several further `driver.sh` invocations, including `tree`
  reads.

**Why.** The wrong row is committed and nothing reports an error. A form can show
the intended text while its backing selection is empty or different, and a
submit button stays disabled or the wrong value is saved. Correcting the skill's
example notes does not correct copies a project already took from them.

**Done.**

1. **Tokenising.** `bin/jtok.py` splits the line first and then expands
   `${VAR}` in each argument, so a value with spaces stays one argument for every
   verb (`tapon "^${PREFIX} Store$"` works), and `#` in a value is not a
   comment. `text` and `type` take the rest of the line in a journey and on the
   command line. The step log echoes the line as written, so `${APP_PIN}` is no
   longer printed expanded.
2. **Read-back.** `type` reads back what landed (`bin/typed.py`) and fails if
   the text is not on screen. A secure field never shows its contents, so a PIN
   step is exempt. `TYPE_VERIFY=0` turns it off. This does not catch a
   non-filtering dropdown, because the text did land; the docs say so.
3. **Assert the committed value.** `reference/journeys.md` tells authors to put
   an `expect` on the committed value after any step that commits.
   `SKILL.md` rule 6 reads "Assert inside the batch, and a filled field is not a
   set value": a control showing the right string may have committed nothing,
   so assert what the form now reads, never the text in the field. Also in
   `reference/driving-discipline.md`.
4. **Example notes.** `reference/apps/example-app.md` taught filter-then-return
   as verified and stated tapping a row never works. Corrected in place, with the
   wrong note left visible above the correction (item 16's shape).

The resolver refused row taps when a keyboard node sat parked at the bottom
edge; that is fixed under item 30. The prediction bar intercepting taps is
item 53.

Which dropdowns filter, and that tapping a dropdown's trailing arrow opens the
list without raising the keyboard, are per-app facts and belong in the project's
app notes.

**To do.** A row in a lazily rendered list that has not been rendered yet fails
with `resolve: no visible node matches`, which reads as absence. The message
could say the list may be scrolled or lazy, and to filter or scroll first.

## 15. Using the MCP tools destroys a `drivers.sh` layout — **DONE**

**What.** Running Maestro against a device — the MCP server, `bin/hier.sh`,
`bin/flow.sh`, `bin/shot.sh` — destroys that device's driver when the command
finishes, whether it succeeded or not. Measured with three drivers on 22087,
22088 and 22089: `maestro --device <second device> hierarchy` left that device
with no driver; the other two kept theirs.

**Why.** The next `driver.sh` call fails with `no driver for <udid>`, one call
after the cause. That reads as a dead relay or a broken app, not as something
the previous command did.

**Done.** `drivers.sh up` records what it started in `$LDIR/drivers.owned`
(`<udid> <port> <epoch>`); `down` and `down-all` clear it. `driver.sh` uses it to
explain the loss:

```
no driver for A0000002-....
  bin/drivers.sh up started one on port 22088 at 15:51, and it is gone.
  Running Maestro against a device destroys that device's driver when it
  finishes — the MCP server, bin/hier.sh, bin/flow.sh, bin/shot.sh.
  No other device is affected: the other 2 still have theirs.
  bring one up:  bin/drivers.sh up A0000002-...
```

A device the toolkit did not start gets the plain message. `drivers.sh list`
shows `was 22088 / GONE`. The registry is not a port map: the live process scan
stays the source of truth for ports, and this file only answers whether the
toolkit started a driver there. The headers of `hier.sh`, `flow.sh` and
`shot.sh` were corrected to say the named device's driver is destroyed.

Verified on a real Mac: failure reproduced, note shown, driver restored with
`drivers.sh up` and note cleared. Twelve offline tests.

## 16. Nothing re-checks a note once it is written — **DONE**

**What.** An app note recorded once was trusted indefinitely, with nothing to
distinguish a single sighting from a repeated measurement. Five notes turned out
wrong, two of them in `reference/apps/example-app.md`, which ships as the example
new projects copy.

**Why.** A wrong note sends the next reader to the wrong method with confidence:
rotating a simulator to fix a coordinate mismatch it did not cause, or using
filter-then-return (item 14).

**Done.**

- `bin/notes.sh add` takes `--measured`, `--once` or `--inferred` and refuses to
  write without one. No default, because a default would give every note the
  same confidence. The refusal names the three and says why.
- Notes are stamped `- (<YYYY-MM-DD>, measured) ...`. A note without a marker
  reads as `seen once`.
- The template says what each level means, that `seen once` must be looked at
  again before relying on it, and that confirming promotes it to `measured`
  with a second date.
- Correcting: mark the original **wrong**, write the correction as its own note
  with the measurement, and leave the wrong one visible. The example file
  demonstrates this.
- `SKILL.md`: a note that contradicts the screen is corrected in place before
  carrying on.

Two notes in the same file contradicting each other is a different failure;
that is item 19.

**To do.**

- A marker records doubt but does not stop a wrong value propagating. Add a
  reference rule: a value taken from a note that does not fit the field it is
  used for (a store id where a location belongs, free text where a selection is
  required) is suspect and must be checked before it is driven.
- A note about whether a bug reproduces should record the build mode and
  device. A debug simulator build can give a confident false negative for a bug
  that only shows on a profile or release build on hardware (items 6, 45).
- A caveat can expire: a hedge against a version mismatch stays worded as live
  after the versions converge. And stale evidence attached to a live finding
  (a request id, a record number) should be compressed into one note led by why
  it exists, not deleted.

## 17. The package has no version, manifest, installer or git — **DONE**

**What.** The package had no `VERSION`, `manifest.sh`, `update.sh`, installer
or git history. It was published by `ship.sh` rsyncing `src/` into a `build/`
directory symlinked into `~/.claude/skills`.

**Why.** A bad ship went live with nothing to roll back to. Nothing stated what
the published tree should contain, so a stray file or an edit made directly in
`build/` was invisible — and such edits were made, believing `build/` to be the
source, and would have been destroyed by the next ship. `build/` also drifted
the other way, missing content `src/` had.

**Done.** Packaged in the `claude-package-kit` house layout as its own git repo.
`src/` became `skill/`; the repo root carries `VERSION` (1.0.0), `manifest.sh`,
`install.sh`, `uninstall.sh`, `update.sh`, `lib/update-check.sh`, the release
workflow and a `/release` skill. `build/` and `ship.sh` are superseded.

- **Rollback.** Releases and `update.sh`: a bad version is a tag not installed,
  and the previous tarball stays on the release page.
- **Stray or missing files.** `manifest.sh` compares the installed tree with
  `skill/` file for file, and `install.sh` runs it on every install. It ignores
  `__pycache__/*.pyc` and `reference/staging/` (where `bin/notes.sh promote`
  parks findings), both of which appear only after use. `test/run-tests.sh`
  proves it catches a stray file and a missing one and does not flag those two.
- **Edits in the live tree.** `./install.sh --link` makes the live path a
  symlink to `skill/`, so an edit there is an edit to the repo, visible in
  `git status`. `SKILL.md` says to run
  `readlink -f ~/.claude/skills/maestro-drive` before editing, and that a copy
  install discards such an edit.

`ship.sh`'s gates are now cases in `test/run-tests.sh`: every shell and Python
file parses, and `lint-stdin.py` (item 84) finds nothing. Two more joined them:
every shell script carries its exec bit (eight did not, including `device.sh`,
whose missing bit broke item 46's recovery path), and the skill's behaviour
cases run from the installed copy rather than the checkout. The installer ends
by resolving `^SCAN$` from a captured iPhone hierarchy and checking the point is
`201 262.6`, so an install that cannot run reports failure. 25 packaging cases
and 360 skill cases. Client identifiers in `skill/` were handled by item 28.

---

## 18. `MAC_HOST` is one alias, so the Mac moving looks like the Mac being broken — **DONE**

**What.** `config.sh` took one `MAC_HOST` value and `lib.sh` handed it to every
`ssh`. When the Mac moved network, its alias pointed at the old address. The HTTP
half kept working because `MAC_FQDN` is resolved by the proxy, so only SSH
failed.

**Why.** Every call failed with `Connection timed out during banner exchange`
and `lost connection`, which reads as the Mac being asleep or off the network
rather than as the wrong alias.

**Done.** `MAC_HOST` takes a space-separated list. `_pick_host` in
`bin/lib.sh` uses the first alias that answers and caches it in
`$LDIR/mac-host`. A single value is never probed. Measured 0.3 s for one alias,
9 s the first time a list steps over a dead one, 0.4 s warm. When none answer,
the error names every alias tried and lists the others in `~/.ssh/config`.
Documented in `reference/connection.md`.

Two bugs the tests caught:

- `_pick_host` narrows `MAC_HOST` to the winner, so a later "more than one
  candidate?" check always answered no and the re-pick never fired. The list is
  captured at source time; capturing it inside the function fails because
  callers read it through `$( )`, a subshell.
- ssh takes the first value for a keyword, so `-o ConnectTimeout=8` after
  `SSH_OPTS` (which sets 15) did nothing. The order was swapped.

No project's conf is edited; a list is opt-in. Item 85 generalises this: the
wizard writes a `Host` block, an `/etc/hosts` line and an `allowedDomains`
entry per network together.

**To do.** `$MAC_HOST` used raw as a single host gets the whole list. A push to
`"$MAC_HOST:$REPO"` became `mac-a mac-b:…` and failed with
`hostname contains invalid characters`. Callers outside `_pick_host` — git
remotes, `scp` targets, the build/sync path — need an accessor that returns the
picked host, and the conf and docs should warn that `$MAC_HOST` is not itself a
hostname.

## 19. Two notes in one file can contradict each other unnoticed — **DONE**

**What.** Two notes in the same app-notes file, sometimes under the same heading
a few lines apart, could say opposite things about the same control, both marked
`measured`, and nothing read them together. Item 16's confidence marker does not
address this. One audit of a single `app-notes.md` found eighteen such
contradictions, including three incompatible measured answers to the iPad
coordinate transform; contradictions settled by hand drifted back.

**Why.** A contradiction does not merely confuse. One of the pair licenses the
wrong method: a note saying iPad app controls need no transform, next to one
saying they do, led to blind raw `tap`s instead of `tapon` (items 56, 57).

**Done.** `bin/notes.sh check` runs `bin/notes_check.py` over the app-notes file.
It reports pairs of notes under the same heading where one affirms a method or
behaviour and the other negates it, about the same named control or screen
element. It is conservative by design, because a checker that reports false
positives gets switched off. Notes containing `~~` strikethrough,
`**wrong**`/`**WRONG**`, `DID NOT REPRODUCE`, or starting with `CORRECTS` are
treated as superseded and skipped; notes marked `CONTESTED` are reported
separately as known conflicts. Covered by tests in `test/run-tests.sh` for a
contradiction, a superseded pair and a pair about different controls.

## 20. A branch switch appears to delete the project's journeys and app notes — **DONE**

**What.** A project's `maestro/` directory (journeys and app notes) is absent on
a feature branch cut before those files were committed.

**Why.** Driving the app with `maestro/` empty means re-deriving logins and
selectors by hand.

**Done.** Closed without a change: this is ordinary git, a merge brings the
files back, and `git show <commit>:maestro/app-notes.md` reads them without
switching branch.

## 21. Nothing dismisses the keyboard — **DONE**

**What.** The keyboard guard correctly refuses a tap on an element under the
keyboard, but `driver.sh` had no verb to put the keyboard away; `keyboard` only
reports whether it is up.

**Why.** Every caller had to invent a dismissal. `key return` dismisses the
keyboard on some screens and not others, and submits the focused field, which
can commit the wrong dropdown row silently. A raw tap at a blank point is not
discoverable, and on a screen filled edge to edge with rows there may be no
blank point.

**Done.** None of the driver's eighteen HTTP routes hides the keyboard, and
Maestro's own `hideKeyboard` is client-side Kotlin, not a driver call. So
`driver.sh dismiss [--no-key]` taps a point above the keyboard that sits on top
of nothing, falls back to `key return`, and says which method worked and what
`key return` may have committed. `--no-key` stops before `key return`. It reads
the keyboard back afterwards rather than assuming, reports a keyboard that will
not go as still up, exits 5 when there is no room above the keyboard instead of
tapping something, and taps nothing when the keyboard is already down. The
under-the-keyboard refusal names `driver.sh dismiss`. Covered by tests in
`test/run-tests.sh` ("putting the keyboard away").

## 22. Fetching from Bitbucket on the Mac fails as if there were no key — **DONE**

**What.** A plain `git fetch` on the Mac fails with `git@bitbucket.org:
Permission denied (publickey)`. The key exists at `~/.ssh/bitbucket`, but the
Mac's `~/.ssh/config` has no `Host bitbucket.org` block and a non-interactive
ssh session has no agent (`ssh-add -l` answers `Could not open a connection to
your authentication agent`), so `ssh -v` shows only the default
`id_rsa`/`id_ecdsa`/`id_ed25519` names being offered. Naming the key works:

```sh
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/bitbucket -o IdentitiesOnly=yes \
                            -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
git fetch origin <branch>
```

Setting `core.sshCommand` in a repository's local git config fixes that one
checkout and no other.

**Why.** The error reads as "this Mac has no Bitbucket access", so branches get
moved to the Mac as a `git bundle` over `scp` when a fetch would do.

**Done.** `reference/setup.md` has a symptom-table row for `git fetch` failing
with `Permission denied (publickey)`: set `core.sshCommand` on the repo
(`ssh -i ~/.ssh/bitbucket -o IdentitiesOnly=yes -o BatchMode=yes`), or add a
`Host bitbucket.org` block with `IdentityFile` to the Mac's `~/.ssh/config`. The
toolkit does not write the Mac's ssh config itself. The separate review-branch
skill's "no key, use a bundle" instruction is owned by that skill; nothing to
change here.

## 23. `secrets.sh check` never checks that the conf is protected — **DONE**

**What.** `bin/secrets.sh check` skips the conf by design, since that is where
the values belong, and searches only what git tracks. So the one file that
holds the credentials is never examined, and whether it is protected depends on
a `.gitignore` line the check never reads.

**Why.** On a branch cut before the `.gitignore` line was added, `git status`
lists the conf as untracked while `check` reports `clean`.

**Done.** `check` runs `git check-ignore -q` on the found conf in its own
repository. If the conf is not ignored it prints `WARNING: <conf> is NOT
gitignored.` with the line to add to `.gitignore`, counts it as a finding and
exits 1.

## 24. Concurrent reviews of several branches share one VM-service cache — **DONE**

**What.** Several devices are already drivable at once: `drivers.sh` allocates
a driver port per booted device from `DRIVER_PORT_BASE` (first device 22087)
and `driver.sh` finds the port from live processes, with no `Simulator.app`
window needed. Three things blocked concurrent reviews of several branches:

- The VM-service cache was single-tenant. `publish.sh` and `net.sh` read a
  remote cache hardcoded to `$RDIR/vmservice` and local state at
  `$LDIR/published.state`, shared across all runs.
- Every flavour build of an app shares one bundle id, so nothing on the device
  says which branch is installed, and `preflight.sh`'s freshness check compares
  against one checkout's newest commit.
- The Mac's repo holds one checked-out branch. `flutter-hot-reload-mac`'s
  `bin/start.sh` runs `git checkout <branch>` on the shared `$REPO`, and
  `build.sh` builds whatever is checked out.

**Why.** Two concurrent `flutter run`s overwrite each other's base URI and
isolate id, so network reading breaks (`publish.sh` printed a base URI of
`http://:9100/…` with an empty host). A `git checkout` on the shared repo moves
HEAD off in-progress work with uncommitted files, a silent clobber. Any use of
the `maestro` CLI or the MCP server destroys that device's driver (item 15),
and the MCP server uses port 22087 Mac-wide for whichever device it last
talked to: a leftover `simulator-server` holding 22087 made `inspect_screen`
fail with "Device became unreachable" while `list_devices` showed the device
connected, and kept respawning on 22087. Raising `DRIVER_PORT_BASE` above 22087
(item 1) moves `driver.sh`'s own driver clear of it. The app's shared dev
backend also needs a separate tenant per concurrent run (one store, account or
similar per branch).

Capacity on an 8-core, 16 GB Mac: a booted simulator plus driver plus
`flutter run` is estimated at about 2 GB, so three concurrent reviews are
realistic and four optimistic. Xcode builds are the CPU spike, so serialise
builds and parallelise driving.

**Done.** `publish.sh` and `net.sh` derive a device suffix (from `DEV`, else the
resolved driver, else empty) and name the files `$RDIR/vmservice-$DEV`,
`$LDIR/published-$DEV.state` and per-device `net*.json` scratch. With no
suffix the single-device path keeps the shared names unchanged. `SKILL.md`
("Reviewing several branches at once") documents `BUILD_MARKER` as required for
concurrent runs and its own checkout or `git worktree` per run as a safety
requirement. Verified on a Mac with two booted simulators each under
`flutter run`, `PUBPORT=9100`/`9101`: publishing for device B wrote
`published-<B>.state` and left device A's file untouched, no shared
`published.state` was written, `net.sh` with `DEV=A`/`DEV=B` each read its own
relay, and the Mac held two `vmservice-<udid>` caches. Not built: worktree
automation, per-run tenant separation, and a per-device relay LAN port; the
relay port is `PUBPORT` (default 9100), set per run.

## 25. Which branch the project's `maestro/` directory is on — **DONE**

**What.** Two notes files disagreed on which branch of the project held its
`maestro/` journeys and app notes.

**Why.** Driving from a checkout of the wrong branch means no project notes (item
20).

**Done.** Settled from the local checkout: the files are on the project's main
development branch and on the feature branch alike, from the same commit.
Nothing to change in the toolkit.

## 26. Controls with no selector can only be tapped by coordinate, and nothing says how — **DONE**

**What.** Some controls cannot be reached by any selector: a container with no
frame in the accessibility hierarchy (an iPad navigation rail), icon buttons
with no text, and a free-text field with no accessibility label. They can only
be tapped by coordinate. The rail's points depend on orientation: they hold in
`landscapeLeft`/`landscapeRight`, and in `portrait` the safe-area inset moves
and the top item is missed.

**Why.** A stored coordinate is fragile on four axes: keyboard up or down, text
size, orientation and device size. A journey tuned on an iPhone 16 Pro and run
on an iPhone 16 Pro Max landed nothing past its opening swipe. The failure is
silent: a wrong point makes `tap` report `ok` and the state does not move.

**Done.** `reference/driving.md` has a "When there is no selector at all"
subsection after the wrong-bounds section. It names the three shapes (no-frame
container, unlabelled icon, unlabelled field), the four fragility axes and the
silent-tap failure, and gives the method: derive the point from `driver.sh
nodes` (which prints the unlabelled containers `tree` hides), tag it
DERIVED-NOT-MEASURED, re-read rather than trust a stored point, and assert that
the state moved. A raw-coordinate journey is device-specific unless proven
otherwise; one that must run on several sizes resolves by selector at run time
or carries per-device coordinate sets. Real values stay in each project's notes;
the section points at `reference/apps/example-app.md` for worked numbers. The
item-51 hook already exempts the no-selector case (item 57 makes raw `tap` the
fallback for exactly these), so no hook change was needed.

## 28. Machine and client data in the package — **DONE**

**What.** Files under `skill/` carried machine and client identifiers: the Mac's
host aliases in fixture strings in `skill/test/run-tests.sh`, comments in
`skill/bin/config.sh` and prose printed by `skill/setup/wizard.sh`; the Mac's
real LAN addresses in `test/run-tests.sh`; and the client app's name and ticket
keys. Earlier redaction had been applied inconsistently inside single files —
`skill/bin/config.sh:90` was sanitised while `:269` and `:309` were not.

**Why.** The repository is public. Anything in a tracked file or in history is
published.

**Done.** Every tracked file was swept and the values renamed to the
placeholders the rest of the repo uses (`mac-a`/`mac-b`,
`192.168.1.x`/`10.0.0.x`). Because the repo was already public, history was
rewritten: all commits across `main`, `release/v1.x` and the `v1.0.0` tag,
verified to leave the tip tree byte-identical, with the five values at zero
blobs afterwards. The `v1.0.0` release asset was rebuilt from the rewritten tag
and checked by download. GitHub still serves the pre-rewrite commits by SHA until
it garbage-collects the repository; removing them needs a GitHub support
request, not a change to this package. Four leftover files and directories
(a duplicate `docs/`, a pre-skill rules document, `build/` and `ship.sh`) live
in the pre-repo working directory outside this repository; nothing here
references or ships them, and deleting them is not this repo's to do.

---

## 29. `tapon` cannot take `--anyway`, and the refusal tells you to use it — **DONE**

**What.** The keyboard refusal (item 9) ends by advising `--anyway`, but `tapon`
took only `<pattern> [index]` positionally: `driver.sh` passed `$2` straight to
`_resolve`, which turned it into `--index "$2"`. `tapon --anyway "^SEARCH$"` and
`tapon "^SEARCH$" --anyway` both died in `resolve.py`'s argparse. `tapon --nodes
--index 0 "^Foo$"` reported `--index: expected one argument`, naming a flag the
caller had not got wrong. Only `find`, which forwards `"$@"`, accepted
`--anyway` and `--explain`.

**Why.** The advice could not be followed by the verb that gave it. The only
route was `find --anyway` then `tap x y`: two calls.

**Done.** `_resolve` in `bin/driver.sh` now takes `<pattern> [index]
[--anyway|--enabled|--disabled]`, sorting the flags out of the arguments after
the pattern and forwarding them to `resolve.py`, and `_tapon` passes all its
arguments through. `tapon <pattern> [index] [--anyway]` works, and the refusal's
advice is true. Tests confirm `--anyway` still overrides the refusal.

## 30. The keyboard guard fires when the keyboard is down — **DONE**

**What.** `keyboard_geometry()` in `bin/resolve.py` derived the keyboard's top
edge as `screen_h - thickness`, taking the keyboard's size and discarding its
reported position. On the iPhone a dismissed keyboard stays in the hierarchy
parked off the bottom (`0,874` or `0,946` on an 874-point screen), so the guard
fired whenever a keyboard node existed at all.

**Why.** Correct taps were refused. On an iPhone 16 Pro (402x874) with the
keyboard parked at `0,946`, a menu row at y=571.5, two buttons at y=574 and a
SUBMIT at y=798 were refused, and all landed correctly by raw `tap`. Item 14
relies on tapping the row to drive a non-searchable dropdown, and this refused
it. On the assertion path the damage reads differently: a numeric keypad
parked at `0,874` put the guard at `874 - 233 = 641`, so `expect` reported a
VERIFY button at centre y=649 as not found, which reads as the app having
changed (item 38).

**Done.** `keyboard_geometry()` takes `screen_w` and uses the keyboard's
reported position when its reported width matches the screen width (one
coordinate space, as on the iPhone) and its size only when it does not (an
iPad's native space, e.g. `3,0 425x1194`). If the resulting top is at or below
`screen_h` it returns `None`: a keyboard parked off the bottom covers nothing.
The refusal message carries the derivation for whichever path was used. Tests
cover both paths: the iPad native-space case still bands at 409, and a
full-width keyboard genuinely up at 569 still refuses a covered element with
the `driver.sh dismiss` advice. The `iphone-portrait-keyboard-up.json` fixture
is a parked keyboard, so the refusal-message and exit-5 tests use two synthetic
fixtures, `kb-pos` and `kb-size`, one per code path. Settled offline against
real captures, not re-measured on a live device.

## 31. `typed.py` passes when the text landed somewhere other than the field — **DONE**

**What.** `bin/typed.py` (item 14) checked that typed text arrived with a
substring match (`if wanted in t`) across every node in the tree (`for n in
walk(root)`).

**Why.** The check could not fail on the screens it exists for. Typing `LOC1`
into a field already holding `0042` gives `0042LOC1`, which contains `LOC1`, so
it passed; that append is what a non-searchable dropdown does to a field with a
value. And a filtering dropdown always renders a row whose label equals the
typed text, so the string is on screen whether or not the field received it.

**Done.** `bin/typed.py` finds the `hasFocus` node and compares what it holds
against the typed text by equality across `value`/`label`/`title`, not
`placeholderValue`, which is the hint. An appended value fails, and a menu row
with the same text no longer stands in for the field. A tap that missed onto
another field is caught, because that field has focus and holds the wrong
value. With no focused node it says so and passes, and a focused secure field
is still exempt. Nine offline tests on synthetic hierarchies replace the
substring tests, one case per hole.

## 32. `tree.py` runs the flag column into the label — **DONE**

**What.** `tree.py` printed `S` (selected) and `F` (focused) immediately before
the label with no separator: `button    S SETTINGS`.

**Why.** A label beginning with `S ` or `F ` could not be told from a flagged
one, the frame column stopped aligning on flagged rows, and a label copied into
a selector carried the flag with it.

**Done.** The flag is a fixed-width bracketed field, `[S ]`, `[SF]`, and four
spaces on an unflagged row, so columns stay aligned. Covered by tests.

## 33. Both renderers silently truncate the strings the skill says to copy verbatim — **DONE**

**What.** `tree.py` cut labels at 60 characters and `resolve.py` cut them at 50
in `find` output, with no mark. Matching is unaffected, since `texts()` returns
the full value.

**Why.** Skill rule 2 says to copy selector text verbatim from the hierarchy. A
61-character label shown at 60 gives a selector that will not match, with
nothing on screen saying why. A list card whose label is the whole card joined
by newlines runs well past 60.

**Done.** Both renderers append `…` when they cut a string (`tree.py` at 60, and
80 in its compact `text` mode; `resolve.py` at 50). Covered by tests.

## 34. `--explain` prints a marker per level, which reads as compounding — **DONE**

**What.** `find --explain` printed the same marker line once per nested level
(`marker 134x291.333 at 0,0 -> scale 3 offset -0,-0`, twice). `walk()` replaces
the transform at each marker rather than multiplying it, which is correct.

**Why.** A list of steps reads as applied in sequence, so the output read as
×9. The printed centre was right; anyone checking the working was misled.

**Done.** Consecutive identical markers collapse to one line with a
`(replaces, not compounds)` note. Covered by a test.

## 35. The keyboard test uses the centre only — **DONE**

**What.** The keyboard refusal tests only `cy >= kb_top`. A tall element whose
top half is clear is refused, and the refusal's advice ("scroll the element
clear") is about the element, not the point.

**Why.** The refusal did not say when an element was only partly covered.

**Done.** The centre test stays, because the tap goes to the centre. When the
element's top edge is above the keyboard, the refusal adds that it is partially
covered, not fully hidden. Done after item 30 fixed the edge itself. Covered by
a test.

## 36. A journey can stop after one line and report success — **DONE**

**What.** `_journey` in `bin/driver.sh` read the file with `while read … done <
"$file"`, putting the journey on fd 0. A verb that shells out to `_ssh`, which
passes stdin through to the remote by design (`lib.sh`), swallowed the rest of
the file, and the loop ended cleanly with status 0. It always struck after the
first executed line, because `_driver_bind` and `_rebind` run ssh once per
invocation, and only when the cached port map needed refreshing, so it was
intermittent.

**Why.** The whole point of batching with `expect` between actions is that a run
cannot report on a screen it never reached. Here journeys printed one `ok` line,
returned 0 with no `FAILED` line or tree dump, and left the app unconfigured.

**Done.** The read owns its own auto-assigned fd (`exec {fd}< "$file"`, `read -u
"$fd"`), per call, so nested `include`s do not clobber the parent's read. An
EOF check after the loop fails loudly (`journey: <file> stopped after line <n>
with '<line>' still to run — did not reach the end`). A blanket `</dev/null` on
every ssh was not applied, because callers rely on `_ssh` passing stdin.
`bin/lint-stdin.py` treats `read -u <fd>` as the documented fix. Two offline
tests via the stub driver: a stdin-draining verb no longer truncates, and a real
failure still stops and returns non-zero; the stub gained `jtok.py`.

## 37. Nowhere to keep a second set of test values — **DONE**

**What.** A project has one conf, so a second environment (a different store,
tenant, account or region) meant passing changed values on every command line.

**Why.** A long run of `KEY=value` on the command line is how a value gets set
wrongly and silently, and the PIN that must not move lives in the same file as
the values that do.

**Done.** `PROFILE=<name>` makes `bin/config.sh` layer `.maestro-drive.conf.<name>`
over the base conf, and errors with `profile '<name>' not found — expected
<file>` when it is missing. Covered by a test. `bin/secrets.sh check` still
checks the ignore status of the base conf only, not each profile file.

## 38. No way to assert enabled state — **DONE**

**What.** `expect` matched a label whether the control was enabled or not,
though `resolve.py` carries `enabled` on every match and `find` and `tree` print
`DISABLED`.

**Why.** "Present but disabled" and "present and usable" were
indistinguishable, so assertions such as "SUBMIT is disabled until a value is
chosen" could only be read off `driver.sh tree` by eye and never failed a run.

**Done.** `resolve.py` takes `--enabled`/`--disabled` and exits 3 when the
match is in the other state. `_expect` passes them through, and journeys write
`expect "^SUBMIT$" disabled` or `enabled`. The failure prints `expect: /<pat>/
not found or not enabled` (or `not disabled`). Covered by tests on a synthetic
fixture.

## 39. `vmservice.sh` finds nothing while `flutter run` is healthy — **DONE**

**What.** `remote/vmservice.sh` rediscovered the Dart VM Service base URI only
from `xcrun simctl spawn "$DEV" log show --last 5m`. An app started more than
five minutes earlier had scrolled out of that window. Separately, `publish.sh`
built a URI with no host (`http://:9100/...`), because `ssh -G "$MAC_HOST"` was
handed the whole alias list (item 18) and returned no hostname.

**Why.** `bin/publish.sh` reported `no VM service found - is the app running in
debug?` with a live debug `flutter run` attached, the opposite of the truth,
and `bin/net.sh` then returned empty, which reads as the app making no HTTP
calls.

**Done.** `remote/vmservice.sh` reads the `flutter run` log first, from
`$FLUTTER_RUN_LOG` (default `/tmp/flutter-run.log`, the recipe in `SKILL.md`)
and `$FRUN_LOG` (`/tmp/frun.log`, the `flutter-hot-reload-mac` skill's), most
recent first, and takes the first URI with a live isolate. It falls back to the
simulator system log (`VM_LOG_WINDOW`, default 5m) only for an app started
without a redirected log. The failure message distinguishes "no URI in any log"
from "URI found but no live isolate". `publish.sh` calls `_pick_host` first and
errors if no LAN IP resolves, instead of emitting a hostless URI. Two offline
tests with a stub `xcrun`, a stub `curl` and a temporary `flutter run` log.

## 40. `bin/build.sh` can finish without installing — **DONE**

**What.** The install loop in `remote/build.sh` ended each iteration on `xcrun
simctl install … || echo "install failed" >&2`, so the echo was the last command
and a build that installed nothing exited 0.

**Why.** A build reported success with the old binary still installed, and only
`bin/preflight.sh` reporting STALE showed it. Same class of failure as item 36:
success reported for work not done.

**Done.** The loop tracks failures and exits with their status, and after an
install returns 0 it confirms the bundle is resident with `simctl
get_app_container`. The `_ssh` exit status propagates, so local `bin/build.sh`
returns non-zero too. Whatever interrupts the install, including the build
being detached with `nohup`, now fails instead of passing. Three offline tests
with a stub `xcrun`: install fails, install succeeds but the app is not
resident, clean install.

## 41. `expect` cannot wait for a condition — **DONE**

**What.** `expect` and `expect-not` called `_resolve` once and answered at once.
`settle` waits for the screen to stop moving and returns at once on a still
screen, and `wait <n>` is a blind sleep. So nothing could wait for a condition
that changes without the screen moving: a transient banner clearing on its own
timer (one sat over a CANCEL button for 2–3 s and took the tap), a status
arriving by poll or push, or an off-screen state such as a build finishing or
the app going online or offline. Maestro's equivalent is `extendedWaitUntil`.

**Why.** Converted Maestro flows became blind `wait 5`s. Hand-rolled poll loops
filled with `sleep`, and a poll that printed only on change was
indistinguishable from a hang. A `settle` straight after opening a transient
overlay (a dropdown, a menu) can return on the closed state and leave a journey
on the wrong screen; a bare `settle` in a journey caps at 10 s, against the
driver's 20 s `isScreenStatic` ceiling.

**Done.** `expect "^X$" <n>` and `expect-not "^X$" <n>` poll `_resolve` once a
second up to `<n>` seconds, print a heartbeat line each tick (`waiting for …
(1/2s)`), return as soon as the condition is met, and fail naming the limit. The
default timeout stays 0, so existing journeys do not start waiting, and a
non-numeric timeout is treated as 0. `expect-cmd <command> [timeout]` (default
30) polls an arbitrary command once a second with the same heartbeat and fails
with `expect-cmd: command did not succeed after <n>s`. `reference/journeys.md`
documents the timeout form and warns not to `settle` immediately after opening
a transient overlay: act on it in the same step, or `expect` the element.
Covered by tests, including heartbeat and deadline timing.

## 42. No way to run a project's own script on the Mac — **DONE**

**What.** `bin/mac.sh` ran a command on the Mac but could not run a file that
exists only in the local checkout, which is the usual case for a script talking
to the app's backend when the API host is unreachable from the sandbox. The
Mac's checkout is a working copy on whatever branch it was left on, so a local
helper is absent there, and copying it in leaves untracked residue that
`preflight.sh` reports.

**Why.** The manual route was `mkdir`, `scp`, then `ssh` with the PIN passed
inline on a command line, where it can be echoed or logged. Non-trivial inline
commands also break on nested quoting, through `ssh` and through `osascript -e
'tell application "Terminal" to do script …'` alike. macOS ships no `timeout`
(only `gtimeout`, with coreutils), and `/tmp` on the Mac is cleaned during use,
so a script written there can vanish before it runs.

**Done.** `bin/mac.sh --send <file> [args…]` copies the file to `$RDIR/send/` on
the Mac (under `$HOME`, never `/tmp`), runs it with the conf's `APP_*` values
exported into the remote environment rather than interpolated into the command
line, streams stdout back and removes the file. Any time limit belongs on the
local side of the SSH call, not in the command sent.

## 43. `tree` has no compact mode — **DONE**

**What.** `tree.py` printed every node: twelve `key` rows with the keyboard up,
the status bar on every read, a label repeated on a card and its parent, and a
frame on every line. On an empty screen it printed a few container lines
and nothing else.

**Why.** Most reads only ask what is on the screen, and paid for the full
indented tree. An empty result could not be told from a failed read or a
loading spinner.

**Done.** A `text` mode in `bin/tree.py`, reached as `driver.sh text` or
`--text` after an action verb: it drops keyboard and status-bar element types
by type, not by a string list, dedupes on the label, omits frames, and prints
`(no text nodes — a modal, camera, or loading screen?)` on an empty screen.
`maestro hierarchy` was not adopted as the transport (7.7 s against 0.28 s, a
JVM, and `maestro --device` destroys the device's driver, item 15). Covered by
tests.

## 44. Four things a Maestro flow can say and a journey cannot — **DONE**

**What.** The journey format had no equivalent of Maestro's `clearState: true`,
conditional `runFlow: { when: { visible / notVisible } }`, `optional: true` on a
tap, or `scrollUntilVisible`.

**Why.** Device-setup flows that test login screens must start signed out, and
`launch` and `kill` keep the session. A step that differs by environment (a
language list with one or two rows, a `Back` that may or may not be needed, an
iOS push-permission alert that may not appear) meant forking the journey per
variant. A section below the fold by a variable amount meant blind swipes.

**Done.** In `bin/driver.sh` and `reference/journeys.md`:
- `tapon? <pattern>` taps if the pattern is on screen and continues silently
  if not.
- `include-if <pattern> <file>` and `include-if-not <pattern> <file>` guard an
  include on whether the pattern is visible, instead of a general expression
  language.
- `scrollto <pattern> [direction] [max]` swipes and resolves repeatedly until
  the pattern appears (default down, 20 swipes) and fails naming the limit.
- `clearstate` uninstalls the app from the simulator; `launch` reinstalls it.

Covered by journey tests through the stub driver. Item 41's waiting `expect` is
the matching change for `extendedWaitUntil`.

## 45. Physical iPhone support lived entirely outside the skill — **DONE**

**What.** Driving and building for a physical iPhone worked only by hand.
`bin/drivers.sh` and `remote/driverup.sh` are simulator-only, extracting
`driver-iPhoneSimulator` from `maestro-ios-driver.jar`, though the jar also
ships `driver-iphoneos`. The device-specific facts:

- The driver's HTTP server binds on the phone, not the Mac, so it needs a
  usbmux forward. `iproxy` is not installed and there is no Homebrew, but
  `/var/run/usbmuxd` is world-writable, so about 50 lines of Python do it.
- Nothing signs from an SSH session: `launchctl managername` is `Background`
  and `codesign` returns `errSecInternalComponent`. `osascript -e 'tell
  application "Terminal" to do script …'` runs in Aqua and signs with no
  password.
- The device tunnel idles out and Maestro then reports the device as not
  connected; a `devicectl` call immediately beforehand wakes it.
- A device build needs `--profile` (a debug build will not launch standalone on
  iOS 14+) and installs with `devicectl device install app`.
- Maestro 2.8.0 cannot build its own device driver: the project references a
  `MaestroDriverLib` target whose sources are in no jar. The prebuilt
  `driver-iphoneos` products, re-signed into
  `~/.maestro/maestro-iphoneos-driver-build/driver-iphoneos/Build/Products/`
  with a `version.properties`, make it skip the build.
- `maestro test` picks a random `TEST_RUNNER_PORT` per run (only `hierarchy`
  uses 22087). `MAESTRO_DRIVER_STARTUP_TIMEOUT` is in milliseconds.
  `launchApp`/`clearAppState` are unimplemented for physical devices in
  `LocalIOSDevice`; `tap`, `type`, `scroll`, `pressKey`, `takeScreenshot` and
  `viewHierarchy` route to the XCTest driver and work.
- Even without a driver, `devicectl` installs, launches and terminates apps and
  reads the app's prefs plist out of the data container.
- `devicectl` can report a phone `available` while `xctrace` lists it `offline`
  (locked, or not paired for instruments), so readiness cannot rest on one
  signal.

**Why.** Without it the skill was simulator-only, and every device step was run
by hand. A phone missing from the Mac's provisioning profiles, with no signing
certificate and private key for the team, cannot have a current build
installed, and the toolkit must not create records in the Apple account to get
round that.

**Done.** Driving path:
- `bin/device.sh up|down|list` is the physical-device counterpart to
  `bin/drivers.sh`. `up` copies the two remote helpers to the Mac, brings up the
  forwarder and a persistent driver, and registers the device; `down` tears both
  down; `list` shows live status.
- `remote/deviceup.sh` mirrors `remote/driverup.sh`: `xcodebuild
  test-without-building` against the re-signed `driver-iphoneos` products with
  `TEST_RUNNER_PORT=<port>`, plus the usbmux forwarder, a `devicectl` tunnel wake
  and a locked-phone refusal up front.
- `remote/iproxy.py` is the usbmux forwarder, parameterised as `<udid> <port>`.
  Both helpers now live under `runners/ios-device/`.
- `bin/lib.sh` keeps a `DEVICE_MAP` registry that `_driver_map` merges, so
  `_driver_bind` resolves a phone like a simulator and `DEV=<udid>` selects it.
  `DEVICE_PORT_BASE` (22187) sits above the simulator range.

App-build path: `bin/build.sh` has a device mode that runs a profile build
through the Aqua `osascript` route, where codesign works, and installs with
`devicectl`. It is gated on a local provisioning profile and refuses with
instructions when there is none; it never uses `-allowProvisioningUpdates`. It
installs the exact `build/ios/iphoneos/Runner.app`, not the first
`build/ios/*iphoneos*/*.app` (which picked a stale `Debug-dev-iphoneos` build),
and verifies that the bundle id `devicectl` reports equals `APP_ID`.

Verified against a physical iPhone XS Max: `bin/device.sh up <udid>` then
`DEV=<udid> bin/driver.sh nodes` returned the real hierarchy, and `bin/build.sh`
built and installed a profile build whose bundle id `devicectl` confirmed. One
offline test of the registry seam, and three for the device build (exact path,
wrong installed id caught, no-profile refusal).

Known edges: `driver.sh`'s `_start` only `pkill`s the exact `relay.py <DPORT>
<DRIVER_PORT>` string, so a stale relay on the same port with a different
target survives and holds the port; `device.sh down` plus a `pkill` clears it.
The persistent driver dying mid-run is item 46. The re-signed driver products
need rechecking on each Maestro upgrade, and `bin/docs-check.sh` (item 55)
watches the version. Launching and cold-restarting the app on a device has to
go through `devicectl`, not the driver, and is not yet wired into a device
driving helper.

## 46. The device driver dies mid-run and every error blames the relay — **DONE**

**What.** On a physical iPhone the on-device XCTest driver dies while it is
running, with the CoreDevice tunnel still `connected` and the usbmux forwarder
still up. `xcodebuild` reports the same death as `The connection was
invalidated`, `** TEST EXECUTE FAILED **`, `** BUILD INTERRUPTED **`, or a live
process whose HTTP server answers nothing. Nothing in the toolkit named this or
recovered from it.

**Why.** The failure surfaced as a relay fault: `driver.sh` printed `relay
started but http://<mac>:9101/status did not answer` and `tree.py` died with a
`JSONDecodeError` on empty stdin. Neither mentions the device, so the obvious
response is to restart the relay, which is not the fault. `drivers.sh list`
reported GONE without saying which layer went. Measured facts about the death:

- It is not the tunnel idling and not an HTTP idle timeout: with `/status`
  polled every 3 s the driver still lived only ~40–70 s, and `devicectl`
  reported the device `connected` at the moment of death.
- A `lockState` keep-alive (`xcrun devicectl device info lockState` every 10 s)
  does not hold the driver up, and it contends for the same tunnel: with it
  running, `xcrun devicectl device install app` failed with
  `com.apple.dt.CoreDeviceError error 3002` / `IXRemoteErrorDomain error 6`
  (`Connection interrupted`). That fix was dropped.
- `devicectl device process launch --terminate-existing` always kills the
  driver, so a cold relaunch must be followed by a driver restart.
- A first `devicectl` call can fail with `RemotePairingError error 4` /
  `Connection reset by peer` and succeed on a plain retry.
- A locked phone produces the same symptom, because XCUITest cannot attach to a
  locked springboard; unlocked, `maestro hierarchy` passed 3 of 3 on Maestro
  2.8.0 / Xcode 26.6. A phone lying flat produces it too (item 50).
- Maestro 2.9.0's iOS device driver is byte-identical to 2.8.0's, and the
  prebuilt driver's `Info.plist` says `DTXcode 2600` with SDK
  `iphoneos26.0.internal`, so neither a Maestro upgrade nor a re-sign changes
  the driver. Xcode 26.6 (17F113) is a public release, not a beta.
- Root cause: the Mac's CoreDevice service. When the driver on a phone kept dying
  within two minutes, restarting the phone changed nothing, while `sudo killall
  -9 remoted` on the Mac (it restarts itself in seconds) took four consecutive
  10-minute runs, prebuilt and source-built drivers alike, from under two
  minutes to alive at 600 s. Measured on an iPhone 11 on iOS 26.5.2 with Xcode
  27.0.

**Done.**
- `bin/driver.sh` `_ensure_device`: when a registered device's driver stops
  answering, it restarts it through `bash "$HERE/device.sh" up` and retries once
  per invocation. It self-gates on `_is_device` (the `DEVICE_MAP` registry), so
  a simulator never triggers it. It calls `bash` explicitly because `device.sh`
  could ship without an execute bit; a direct call failed with `device.sh:
  Permission denied` and the recovery never ran.
- `_start` `pkill`s any `relay.py <DPORT> ` regardless of target, so a stale
  relay pointing at the wrong port cannot hold the socket.
- `_devdrv_hint`: when `/status` fails it reads the tail of the device driver
  log on the Mac and prints it with the explanation that the on-device XCTest
  session died, not the relay. It first probes `devicectl … lockState` and, on
  `passcodeRequired: true`, leads with "the phone is LOCKED — unlock it".
  `deviceup.sh` refuses a locked phone with the same message. Both self-gate:
  nothing prints for a simulator.
- A third driver restart within ten minutes prints the `sudo killall -9
  remoted` instruction (`_restarts_note` in `driver.sh`, and `deviceup.sh`);
  `physical-device.md` says to restart `remoted` before anything else.
- Offline tests cover the `_is_device` gate, ensure-driver as a no-op on a
  simulator, the hint and lock check against a fake `_ssh`, and recovery
  through `bash` with a non-executable stub `device.sh`. The lock refusal and
  the restart path were verified against a physical iPhone.

## 47. `relay.py` relays into itself when the viewer is not running — **DONE**

**What.** `remote/relay.py` binds `0.0.0.0` and forwards to `127.0.0.1`.
`viewer.sh` starts it as `relay.py 9999 9999`, so when Maestro Viewer is not
running the forward target sits inside the relay's own bind. Every accepted
connection is handed back to `accept()`, a thread pair is spawned for it, and it
recurses. Nothing returns HTTP; `curl` through the sandbox proxy gets a `502`.

**Why.** `viewer.sh` printed `relay started, but nothing answered on port 9999`,
which reads as a network or name-resolution problem. The checks go to mDNS, the
LAN address and the sandbox proxy, all of which are fine. The real fault is that
no viewer is running. Binding the LAN address instead would close the loop but
would stop URLs built from `MAC_FQDN` following the Mac between networks.

**Done.** `relay.py` probes the target before binding when `lport == rport` and
exits non-zero with "no service on port <rport> to republish — start the
service first, then run the relay". `viewer.sh` checks for a live viewer first
and prints "no Maestro viewer is running on <host>, so there is nothing to
republish", with a warning not to run `maestro studio`, which starts its own
XCUITest driver and destroys a running one.

## 48. The `maestro-mac` MCP server hardcodes one SSH alias — **DONE**

**What.** The MCP entry ran a bare `ssh … mac-b "… exec maestro mcp"`. It always
dialled one alias. Every `bin/` script instead gets `lib.sh`'s `_pick_host`,
which tries each alias in `MAC_HOST`, caches the winner and re-picks if it stops
answering.

**Why.** When the Mac was on the other network, SSH timed out during banner
exchange, the process exited, and Claude Code reported the server as
`CONNECTION_CLOSED` while `bin/mac.sh` worked. Every MCP tool, including
`open_maestro_viewer`, was unavailable. Pointing the entry at the other alias
only moves the failure to the other network.

**Done.** `bin/mcp.sh` sources `lib.sh`, runs `_pick_host` and `exec`s `maestro
mcp` against the alias that answered (or locally, under the local transport).
The MCP config names the script and never a host, so a new network is added
only to the conf. `reference/setup.md` documents the entry. Item 85 is the
general case: files naming a network drift apart when updated separately.

## 49. Nothing says to replay the project's existing flows and journeys — **DONE**

**What.** The start-of-session sequence said to read the app notes but never to
list `maestro/flows/` and `maestro/journeys/`. Nothing said that a screen a
journey covers is replayed, not rediscovered, or that a journey found to be
wrong is fixed in place.

**Why.**
- Covered screens such as the first-run login get hand-driven tap by tap, and
  bugs already recorded in `COVERAGE.md` get re-investigated.
- Conf credentials are exported only into the process that sources
  `bin/config.sh`, which is `driver.sh`, not the caller's shell. `$APP_PIN` in a
  hand-built Bash command is empty, and the app answers as though the PIN were
  wrong. A journey or flow is the only correct way to type a credential.
- Listing the directory is not enough: a listed journey whose header names the
  exact starting screen still gets hand-walked unless the rule says the journey
  is the unit of work.
- A journey known to be wrong rots if the correction goes only into the notes.
  Forking a copy to dodge a bug (as `01-device-setup-v3.journey` did to avoid an
  item 41 `settle`) adds a duplicate instead of a one-line fix.
- A journey that hard-codes a volatile test value (a location since deleted from
  the backend) fails with `resolve: no visible node matches`, naming the
  selector, not the cause.

**Done.**
- Rule 1 ("Batch") in `SKILL.md`: the unit of work is a journey file, not a driver call.
  Before driving a screen, check whether a journey's header names it as the
  starting screen; if so run it, if not write one as you go.
- A start-of-session step lists `$JOURNEY_DIR` and `maestro/flows/` and names
  `COVERAGE.md` if present.
- Rule "A conf credential lives only inside this toolkit's own process": a
  conf credential is readable only there,
  so `${APP_PIN}` belongs in a journey or flow, never a hand-built command.
- `bin/preflight.sh` prints `journeys N files · flows N files · COVERAGE.md …`.
- `reference/journeys.md` "When a journey is wrong": repair in place, do not
  fork, write findings back into the journey, keep volatile data out of
  journeys. A new journey is written only when no existing file covers the path,
  with a header saying what it adds.
- Item 51's hook is the enforcement half.

## 50. A flat phone crashes the driver on the first touch, silently — **DONE**

**What.** Lying flat, a physical iPhone reports `.faceUp`. The prebuilt
on-device driver's `actualOrientation()` maps only `.unknown` to portrait, so
the first `POST /touch` kills it with `ScreenSizeHelper.swift:99: Fatal error:
Not implemented yet`, then `** TEST EXECUTE FAILED **`. Reads keep working. The
jar's own `ScreenSizeHelper.swift` handles `.faceUp`; the prebuilt runner is
compiled from older source than the jar ships (item 55).

**Why.** The symptom is item 46's: `settle: screen still moving after 20s`,
`relay … did not answer`, and `tree.py`'s `JSONDecodeError`. It reads as a
transport fault. No restart fixes it; the phone has to be stood up. Once item
46's restart started working, the restart emptied the driver log before
`_devdrv_hint` ran, so the cause was never named and every tap on a flat phone
crashed and recovered silently.

**Done.**
- `_devdrv_hint` in `bin/driver.sh` recognises the `ScreenSizeHelper` / "Not
  implemented yet" fatal and prints "this is the FACE-UP crash (item 50) …
  STAND THE PHONE UPRIGHT", before the item 46 message.
- `_ensure_device` calls `_devdrv_hint` before it restarts, so the log is read
  while the cause is still in it. A test gives the stub restart a working driver
  (`/status` answers 200 once `device.sh` has run) and fails on the old order.
- The driver built from `cli-2.8.0` source (`runners/ios-device/driver/build.sh`,
  item 99) does not crash: on a flat iPhone XS Max reporting `faceUp`, the
  prebuilt driver died on touch 1 and the source build answered 5 of 5 touches
  with 200. `deviceup.sh` starts the source build whenever a signed one exists
  and falls back to the prebuilt one with a note that it crashes on a flat phone.
- Not built: a pre-touch refusal for the prebuilt fallback. Xcode 27's
  `devicectl device orientation get` reads `faceUp` on a physical phone, so
  `driver.sh` could refuse a touch on a flat phone; the driver's own
  `DeviceInfoResponse` carries no orientation.

## 51. The skill has no way to ship a hook — **DONE**

**What.** A `PreToolUse` hook that blocks raw coordinate taps had nowhere to
live. It only ever fires on a command containing `driver.sh`, so outside the
skill it is dead code on every Bash call in every project. `ship.sh` had no
notion of a hook, and the skill's setup had no place to document one.

**Why.** Prose rules in `SKILL.md` and memories are read before the screen is on
the table; a hook fires at the moment of the tap. Without a way to ship it, the
hook either does not exist or outlives the skill it polices.

**Done.** `hooks/gate-journey-first.sh` ships in the skill. It matches a Bash
command mentioning `driver.sh` with a `tap` or `swipe` verb followed by literal
numbers, including the `$D tap 179 481` form; `tapon` is not matched. It exits 2
once per Claude Code session, then lets the call through, because raw taps are
legitimate where the tree carries nothing (the iPad nav rail). Its marker lives
in `$TMPDIR`, and it fails open if the marker cannot be written.
`reference/setup.md` gives the `settings.json` block: a second `Bash` matcher
under `hooks.PreToolUse` running `bash ~/.claude/skills/maestro-drive/hooks/gate-journey-first.sh`.
`bash <path>` is used because the sandbox refuses `chmod +x` under `~/.claude`.
A person adds the entry by hand. A sharper variant, one bump per distinct
command instead of per session, is noted in the script.

## 52. A project has nowhere to put a finding that is not about its app — **DONE**

**What.** `reference/app-notes-template.md` says that anything true of Maestro
or iOS generally stays out of a project's notes, but gave nowhere else to put
it. `~/.claude/skills/…` is overwritten by the next install (item 17).

**Why.** General findings (a Flutter framework bug, Maestro limitations,
code-signing and usbmux steps) and app bug findings pile up in `app-notes.md`,
which is read at the start of every run. One project's file reached 168 KB,
about 42k tokens, with 16 KB of sections that fail the template's own test, so
it is not read in full and the app findings are diluted. `bin/notes.sh add`
starts a new section when no heading matches by substring, which produced four
stub sections duplicating existing headings. Notes also outlive the app build
they were measured on, though most structural findings stay true, so retirement
has to be by re-check, not by date (item 16).

**Done.**
- `SKILL.md` "Keep the app notes" and the template's "What stays out": a finding
  that would still be true of a different app goes in the project's
  `maestro/tooling-findings.md`; a bug in the app goes in the project's bug or
  test findings; app notes are for how to drive the app.
- `notes_add.py` fuzzy-matches a new section against existing headings
  (case-insensitive, cutoff 0.6) and warns naming the closest. Two offline
  tests.
- `bin/notes.sh promote` copies the project's `maestro/tooling-findings.md` to
  `reference/staging/<project>-tooling-findings.md` for a person to fold into
  `reference/`.
- Not built: retirement of notes when the app's version moves on.

## 53. The resolver does not account for the predictive-text / QuickType bar — **DONE**

**What.** The iOS QuickType suggestion strip sits above the keyboard and is
drawn by the system. `resolve.py` treated the keyboard band but not the
prediction bar above it.

**Why.** A tap on a list row whose centre falls in the bar's band lands on a
suggestion and types it into the focused field (for example "The ") instead of
selecting the row. Seen on a simulator and on a physical iPhone, so it is not
simulator-specific.

**Done.** The bar appears in the tree as `SystemInputAssistantView`.
`keyboard_geometry` in `bin/resolve.py` records its band separately, and a
target whose centre falls in it is refused with "UNDER THE PREDICTION BAR — the
tap will land on the QuickType suggestion strip, not the element". The advice
under it names `driver.sh dismiss` and `--anyway`. A test checks a target in the
band is named as the prediction bar, not the keyboard. `reference/driving.md`
describes the behaviour.

## 54. Reading persisted prefs is a multi-step gotcha with no helper — **DONE**

**What.** Reading the app's persisted preferences took two non-obvious steps.
`defaults read` cannot see the app's domain, so the plist has to be read as a
file from the data container. And iOS flushes `NSUserDefaults` lazily, so the
app must be backgrounded before the read.

**Why.** Without the flush, freshly written keys are missing from disk and the
read looks like an app bug. On a device, the `devicectl device copy from` syntax
is easy to get wrong (`Error: Unknown option '--username'`). This is the
measurement the toolkit leans on most for verification.

**Done.** `bin/prefs.sh [pattern|--all|--raw]` backgrounds the app
(`platform.sh prefs-flush`), locates and reads the store (`platform.sh
prefs-read`), and filters to the framework's prefix (`framework.sh
prefs-prefix`, `flutter` by default). The iOS, Android and template runners
implement the verbs. Documented in `reference/driving.md` "Reading the app's
persisted preferences". Tests check the prefixes and that `prefs.sh` names no
platform command of its own.

## 55. The shipped docs mirror is wrong about physical iOS — **DONE**

**What.** The Maestro 2.8.0 docs mirror under `docs/pages` says in
`supported-platform__ios__uikit.md` that "Executing tests on physical iOS
devices is not supported yet", while `maestro --device <udid> hierarchy` on the
same Mac builds a device driver and drives the phone. `--apple-team-id` is
listed only under `record` and is hidden on `hierarchy` and `test`.

**Why.** A reference that wrongly says *no* ends investigations that would
succeed. Physical driving was declared impossible on the mirror's authority
before it was tested and worked.

**Done.**
- Rule "Test before you report a capability impossible" in `SKILL.md`: test a capability on the connected device before
  reporting it impossible; the mirror and the skill's assumptions are not
  authority over an empirical test.
- `bin/docs-check.sh` carries a known-wrong list for the pinned mirror version
  (`KNOWN_WRONG_FOR="2.8.0"`), printed even under `--quiet`: the physical-iOS
  denial and the hidden `--apple-team-id` flag, each naming `maestro <cmd>
  --help` as the authority and pointing at `physical-device.md`. It is gated on
  `MAESTRO_VERSION`, so a `docs-refresh.sh` to a new mirror drops it.
  `preflight.sh` runs `docs-check.sh`. Two offline tests.
- The device driver is now built from the matching Maestro git tag by
  `runners/ios-device/driver/build.sh` and signed by `sign.sh`; `deviceup.sh`
  prefers it (items 50, 99). Re-signing the prebuilt driver
  (`physical-device.md` §3) is the fallback.
- Not done: stopping shipping a mirror that goes stale silently.

## 56. Skill-usage lessons land where the next repo never sees them — **DONE**

**What.** Discipline for using the skill (screenshots are not for locating
elements, batch a sequence into one round trip, do not carry a coordinate across
calls) was being written into one project's memory or into `reference/`, not
into the part of the skill read before driving.

**Why.** A lesson saved to one repo's memory does not reach the next repo. Rules
in `reference/driving.md` and in memories loaded at start were not applied at
the moment of the tap; rules surfaced at the moment of the action were.

**Done.**
- Rule 3 in `SKILL.md` "The rules that matter most" ("Do not trust reported
  bounds") extended: do not carry a
  coordinate across calls; a form shifts 80–140 points when a keyboard opens or
  a menu closes, so resolve and tap in the same call. Rule 1 (batch,
  journey-first) and rule 2 (never author a selector from a screenshot)
  already covered the rest.
- `reference/driving-discipline.md` is the in-skill home for skill-usage
  discipline.
- Item 51's hook enforces the coordinate-tap rule.

## 57. The docs give contradictory iPad-tap guidance and never point at `tapon` — **DONE**

**What.** `reference/driver-api.md` (sourced from the driver's Swift) says
`/touch` coordinates are portrait-referenced and that the handler passes them
through `ScreenSizeHelper.orientationAwarePoint`, which rotates the point itself
in landscape. `reference/apps/example-app.md:53` stated the opposite: hand-convert
with `device_x = 834 - app_y`, `device_y = app_x`. Nothing told the operator to prefer
`tapon` on the iPad, where the resolver applies the landscape transform (item 8).

**Why.** A hand-transformed raw `tap` on a landscape iPad is a double transform
and misses, while `tapon` on the same element lands first time. The docs led
operators to coordinate arithmetic instead of the resolver.

**Done.**
- `reference/apps/example-app.md:53` is flagged, with a correction bullet: the
  driver already rotates, so `tapon` sends the right point and hand-applying
  `834 - app_y` double-transforms; the raw mapping is device-space only. It
  points at `driver-api.md` as the authority.
- `SKILL.md` rule 3 gains an iPad clause: use `tapon`; only raw-`tap` a node the
  tree cannot reach (the nav rail, item 26), and then in app-space coordinates,
  never a hand-rolled `834 - app_y`.
- `reference/driving-discipline.md` carries the fuller rule.

Measured on an iPad Pro (11-inch) (3rd generation) simulator after
`driver.sh orient landscapeLeft` (device and tree both 1194x834), A/B-tapping the
Privacy row in Settings from a General baseline: the app-space point (207,431)
lands; the hand-transformed (403,207) misses. `find --explain` shows the true
transform is `scale 1 offset -360,0`, a pure offset with no rotation term. A
portrait device running a landscape-locked app was not measured; the rule (set
the device to the app's orientation with `orient`, then `tapon`) makes it moot.

Related: items 8, 26, 51, 56.

## 58. No clean way to force a timed state, and nothing says to read the app's supported orientations — **DONE**

**What.** (a) Forcing a timed state (an idle-logout modal) was done by patching
the timeout in the app source. (b) Nothing told the operator to read the app's
`UISupportedInterfaceOrientations~ipad` before choosing an iPad or an
orientation.

**Why.** (a) A 45-second source fudge lost about 15 seconds to driving latency
over SSH, so the modal arrived before the screenshot, and the fudged build then
had to be reverted and rebuilt on every target simulator. (b) A landscape-locked
app has no portrait iPad layout; chasing one wastes devices, and a newer iPad
letterboxes a landscape-locked app, which narrows its coordinate space.

**Done.**
- `reference/driving.md` "Forcing a timed state": force timers through the app's
  configuration (Remote Config, environment variables, a feature flag), not a
  source edit. If only a source change works, leave at least ~30 seconds of
  headroom, rebuild from clean source before any real verification, and record
  the original value in the journey.
- `preflight.sh` prints the app's `UISupportedInterfaceOrientations` and `~ipad`
  arrays from its `Info.plist` (the `orientations` case in
  `runners/ios/platform.sh`), and `reference/driving.md` says to check them
  before choosing an iPad simulator.
- `reference/app-notes-template.md` gives the Remote Config key as the example.

Related: items 8, 24, 26, 57.

## 59. Home-directory dotfiles appear untracked at the repo root — **DONE**

**What.** `.bashrc`, `.zshrc`, `.profile`, `.gitconfig`, `.bash_profile`, an empty
`.gitmodules`, `.idea` and `.mcp.json` appear untracked at the root of the
checkout under test during driven reviews. The writer is not identified; it may
be the sandbox, a GSD or harness step, the bundle-to-Mac path, or an IDE.

**Why.** `git add .` or `git commit -a` sweeps them into a PR branch alongside
the real changes.

**Done.** Cause not established. `reference/driving.md` "Home-directory dotfiles
appearing at the repo root" documents the hazard, says to stage only named files
during a review, and gives the list to add to the project's `.gitignore` or the
global `~/.config/git/ignore`.

## 60. `erase` deletes backwards from the caret, so it cannot reliably clear a field — **DONE**

**What.** `erase` sends backspaces from the current caret position. If the caret
is not at the end, or the field holds text the step did not type, some text is
left, and the following `text` appends to it.

**Why.** The failure is silent: the step reports success and the field holds the
wrong value. Without a working clear-then-type, a journey gets forked to avoid
the field instead of being fixed (item 49).

**Done.**
- `driver.sh clear <pattern>` long-presses the resolved element, taps
  "Select All" from the iOS edit menu and deletes the selection; it skips the
  delete when "Select All" does not appear (an empty field).
- `driver.sh erase --all` sends 9999 backspaces instead of the default 50, which
  helps only when the caret is already at the end. Both work inside journeys.
- `reference/driving.md` says `erase` deletes only from the caret back and to
  prefer `clear` when replacing a field's contents.
- Covered by tests in `test/run-tests.sh` ("erase --all and clear").

Related: items 31, 49.

---

## 61. The app is restarted on failure instead of the hierarchy being read — **DONE**

**What.** When a journey fails or the screen is in an unexpected state, the
operator relaunched the app rather than reading the hierarchy, which already
carries field values, placeholders and layout.

**Why.** A relaunch throws away state that was already correct — for example a
selection the app remembers from a previous login — and the next journey then
fails because the screen it expects is gone. Each restart costs 30–60 seconds.

**Done.** `SKILL.md` rule 8, "Never restart the app in response to a failure":
read the hierarchy and decide whether to use a different journey, dismiss a
keyboard, or tap what is already on screen. The standing lesson is in
`reference/driving-discipline.md`.

## 62. relay.py connects upstream to `::1` (IPv6) but Maestro binds IPv4 only — **DONE**

**What.** `src/remote/relay.py` lines 38 and 55 called
`socket.create_connection(("::1", rport))`. The Maestro XCUITest driver binds
`127.0.0.1` only.

**Why.** Every upstream connect failed: `curl` from the LAN got "Bad Gateway"
and `curl http://localhost:<port>/status` on the Mac returned empty.

**Done.** Both calls changed to `("127.0.0.1", rport)`.

---

## 63. Xcode 27's `lipo -verify_arch` fails with multiple architectures — **DONE**

**What.** Under Xcode 27 (macOS 27), `lipo -verify_arch arm64 x86_64` exits 1 on
a valid fat binary; each architecture passes on its own. Flutter's
`debug_unpack_ios` target in `darwin.dart` passes all requested architectures in
one call, and `defaultIOSArchsForEnvironment` hardcodes `[x86_64, arm64]` for
`EnvironmentType.simulator`.

**Why.** Every `flutter build ios --simulator` fails once `debug_unpack_ios` runs
fresh. A flavour with a cached unpack output from before the Xcode upgrade looks
unaffected until the next `flutter clean`.

**Done.** `remote/build.sh` exports `FLUTTER_XCODE_ARCHS=arm64` on Apple Silicon
Macs before `flutter build ios --simulator`. This flows through
`xcode_backend.dart` (line 641) to `-dIosArchs=arm64`, so `lipo -verify_arch`
gets one architecture and passes. x86_64 simulator support is only needed on
Intel Macs. A separate consequence of the same upgrade — Swift precompiled
modules built by Swift 6.0.3 (Xcode 16) against a Swift 6.4 toolchain — is
cleared by removing `DerivedData/Runner-*` and running `pod install`. Verified
with a simulator build completing in 42.1 s.

---

## 64. The published viewer URL is a guess, and the page it lands on is idle — **DONE**

**What.** Four faults, each enough on its own to leave the Maestro viewer blank:

1. **The port is not 9999.** `maestro mcp` without `--viewer-port` picks a free
   local port, so live viewers sit on 9999, 10001 and so on. `config.sh` pinned
   `VPORT=9999`, so `viewer.sh` republished whichever viewer won that port,
   possibly not the one driving.
2. **The relay starts before its target exists.** `SKILL.md` and
   `reference/driving.md` told the operator to run `viewer.sh` first, but the viewer binds only
   when a `maestro mcp` server starts. `relay.py`'s `lport == rport` probe finds
   nothing and exits 1.
3. **That failure is invisible.** `viewer.sh` ran the relay with
   `>/dev/null 2>&1`, hiding "no service on port N to republish — start the
   service first", and printed advice to run `maestro studio --device <udid>`,
   which starts its own XCUITest runner and destroys the driver `drivers.sh` holds.
4. **With two simulators booted the page never starts a device.** The viewer
   bundle's auto-start returns early when `/api/device/targets` lists other than
   exactly one device, and there is no picker. The state stays
   `{"status":"idle",...,"streamUrl":null}`, the screen pane renders only under
   `status === 'streaming' && streamUrl`, and no `maestro.flow_state` is emitted.

**Why.** The viewer had never shown anything, and its one suggested remedy breaks
the running driver.

**Done.** Done inside item 65. `bin/viewer.sh` was rewritten: it discovers live
viewer ports instead of assuming 9999 (`viewer.sh list`), lets `relay.py`'s
stderr reach the caller, drops the `maestro studio` advice, and states that the
device picture is blank from anywhere but the Mac (the command rows and device
list cross a relay; the picture cannot). Live video is served by the wall
(item 65).

---

## 65. Watch every booted simulator at once, from one URL on this host — **DONE**

**What.** There was no single bookmarkable URL showing every booted simulator on
the Mac live, independent of which `maestro mcp` server is running.

**Why.** The viewer is per-server and per-device (item 64), so watching several
simulators meant hunting for ports that move.

Reading `maestro-cli-2.8.0.jar` established the mechanism: the stream is MJPEG,
produced by a bundled native binary (`~/.maestro/deps/simulator-server`), not
ffmpeg, so nothing needs installing on the Mac; it is per-`deviceId`; browser
input also goes to `simulator-server`; and it never touches XCUITest — the path
that would replace a driver is `McpMaestroSessionManager$createIOSDriver`, reached
by MCP flow tools, not `/api/device/start`. So the single-port limit on driving
(22087, `drivers.sh` header) does not constrain video.

**Done.** `bin/wall.sh` and `remote/wall.py` are new. The wall binds its own port
(`WALLPORT`, 9990), spawns `~/.maestro/deps/simulator-server ios --id <udid>` per
booted simulator, reads the `stream_ready http://127.0.0.1:<port>/stream.mjpeg`
line each prints, and re-serves each stream at `/device/<udid>/stream.mjpeg`.
One upstream connection per device feeds any number of browsers: it parses the
frames and regenerates the multipart response per client, so a late joiner gets
the current frame. It rescans every 5 s, adding and removing tiles as simulators
boot and shut down and restarting a capture process that dies. `bin/viewer.sh`
was rewritten as described in item 64.

Xcode 27 moved `SimulatorKit.framework` from
`Contents/Developer/Library/PrivateFrameworks/` to `Contents/SharedFrameworks`,
and `simulator-server` has the old path compiled in, so every stream fails with
"simulator-server exited before announcing stream_ready". `DEVELOPER_DIR` does
not steer it, and Maestro 2.10.0's binary is byte-identical to 2.8.0's. The fix
is a symlink:

```sh
sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks
sudo ln -s /Applications/Xcode.app/Contents/SharedFrameworks/SimulatorKit.framework \
           /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/
```

An App Store Xcode update removes it again; `bin/wall.sh status` checks for this
and prints both commands.

Verified with three simulators streaming (`/api/devices` lists all three `live`;
one stream returned 462 KB in four seconds) while the XCUITest drivers on 22087
and 22089 kept their pids and kept answering `/deviceInfo`. Ten tests cover the
MJPEG framer (including a boundary split across two reads) and the booted-device
list.

---

## 66. The wall's tiles say which handset, not what is being driven — **DONE**

**What.** With several simulators on the wall, handset names alone do not say
which agent is driving which device or which project it belongs to.

**Why.** On a shared Mac, the wall cannot be used to tell devices apart or to
find who set up a device.

**Done.** A label is a file, `$RDIR/labels/<udid>`, written over the existing SSH
connection; the wall reads it on each 5-second scan and stays read-only over
HTTP, since its port is reachable on the network. One file per device so writers
never collide and clearing is `rm`. `key=value` lines, not JSON, because they are
written by a shell heredoc through ssh. The file's mtime is the label's age; the
page greys a label untouched for an hour.

    ./bin/wall.sh label [<udid>] <name> [--group <g>]
    ./bin/wall.sh unlabel [<udid>]

With no udid it uses `DEV`. `bin/drivers.sh up` writes a default (`PROFILE` or
`APP_ID` for the name, the project directory for the group) without overwriting
a hand-set name; `down` and `down-all` clear labels. The page groups tiles under a
heading per group, ungrouped last with no heading.

Each label records its writer in a `by=` field: the colour from
`CLAUDE_SESSION_COLOUR` plus seven characters of `CLAUDE_CODE_SESSION_ID`, falling
back to `user@host` outside Claude Code. The page shows it under the name with
the age. A label without the field reads as blank.

Verified across three simulators (two named and grouped, one bare, `unlabel`
restoring a tile). Ten tests cover the label parser, age, staleness and the `by`
field.

---

## 67. A wall label outlives its session — nothing clears it, and the next session will not replace it — **DONE**

**What.** A simulator label on the wall was removed only by `bin/wall.sh unlabel`,
`bin/drivers.sh down <udid>` or `bin/drivers.sh down-all`, all typed by hand.
`STALE_AFTER = 3600` in `remote/wall.py` only greys the name; the label file is
untouched. And `_label_default` in `bin/drivers.sh` writes a label only into a
blank file, so it cannot tell a name set by hand from one left by a Claude Code
session that has ended. Both halves are one missing fact: whether the session
in `by=` is still alive.

**Why.** Any ending other than an explicit `drivers.sh down` — closed terminal,
exhausted context, crash — left the label and its driver up indefinitely. A new
session bringing a driver up on that simulator inherited the dead session's
name, `by=` and mtime, so the wall named the wrong work and its age kept
climbing. The label is the visible half of a stale driver.

**Done.** The wall stays read-only; whoever wrote a label removes it. Four
pieces:

1. **`SessionEnd` hook.** `hooks/rig-down-on-end.sh` runs `rig down` (item 76)
   for what this session booted, detached so it cannot hold the terminal, and
   always exits 0. `rig down` both clears the label and stops the driver, and a
   session that ends mid-journey is treated the same as one that ends cleanly.
   `install.sh` registers the hook; `reference/setup.md § 5` documents its
   settings block beside `gate-journey-first.sh`'s.
2. **Reclaiming a dead session's label.** `drivers.sh rig` renames
   unconditionally any device it has just booted (`_rig_rename`), since a device
   that was shut down cannot carry a hand-set name. Elsewhere `_label_default`
   reclaims a label only when all three hold: it names a different session; the
   device has no live driver; and the label is untouched for
   `LABEL_STALE_AFTER` (default 3600s, the threshold `wall.py` greys at). A
   session-id mismatch alone is not enough, because two live sessions share a
   Mac (item 80); and no-live-driver alone is not enough, because Maestro tears
   a driver down on every CLI or MCP run. Six tests, including a peer with a
   live driver and a peer whose driver was torn down a minute ago; the remote
   shell was also run on a real Mac against scratch files (blank→WROTE,
   ours→KEPT, peer fresh→KEPT, peer 113060s old→WROTE, peer with live
   driver→KEPT).
3. **`SKILL.md`.** The rig step says to run `rig down` when driving is finished
   and points at the hook for untidy endings.
4. **What a stale label looks like.** `remote/wall.py`'s `read_label` returns
   `{}` when the label's mtime falls on an earlier local calendar day, so the
   tile shows the handset and no name. Nothing is deleted: the file stays and
   `drivers.sh rig status` still prints `by=`. The one-hour greying is
   unchanged. Six tests, including a three-hour-old same-day label kept and
   greyed, and a one-hour-old label from before midnight hidden.

A simulator nobody has touched since its session ended is a boot problem, not a
label problem: item 88.

---

## 68. The wall's tiles were sized for a phone, so an iPad overflowed its card — **DONE**

**What.** In `PAGE` in `src/remote/wall.py`, `.sim` was capped at
`max-width:340px` while `.sim img` was `height:70vh; width:auto`, so nothing
capped the image's width. At 70vh of a 1080px window an iPhone 16 is 349px
wide (9px over), a portrait iPad Pro 11" 528px (188px over), and a landscape one
1082px (742px over). `.sim .err { max-width:280px }` repeated the hardcode.

**Why.** An iPad tile runs out of its card, and a phone overflows by a few
pixels unnoticed.

**Done.** In `src/remote/wall.py`:
- `.sim img { display:block; width:auto; height:auto;
  max-height:var(--tile-h, 70vh); max-width:46vw; }` — capped both ways, so a
  portrait iPad is height-bound and a landscape one width-bound.
- `.sim`'s `max-width:340px` is removed; the card takes its width from the
  image. `width:0; min-width:100%` on `h3`, `.sub`, `.who` and `.err` keeps text
  out of the intrinsic-width calculation, so a long label ellipsises instead of
  stretching the card.
- `tick()` sets `--tile-h` from the device count: 70vh up to two, 46vh up to
  four, 34vh beyond, so three tiles share a 1440px row.
- `min-width:260px` applies only to `.sim:not(:has(img))`, the error tile.

Verified by rendering the deployed `PAGE` with four fake devices (iPhone
393x852, iPad portrait 834x1194, iPad landscape 1194x834, an error tile with a
long message) in headless Chrome on the Mac at 1440x1080 and 900x900: no
overflow, three live tiles on one row at 1440, two rows with no horizontal
scroll at 900, labels ellipsised, error tile readable. Existing tests do not
touch `PAGE`.

**Not done.** A possible reflow when an MJPEG stream's first frame arrives (the
image has no intrinsic size before it) was not observed with static images and
was left alone.

---

## 69. `driver.sh swipe` posts `/swipe`; the driver's live route is `/swipeV2` — **DONE**

**What.** `bin/driver.sh` posted `/swipe` for the `swipe` CLI verb, the journey
`swipe` verb and `_scrollto`. Maestro itself posts `/swipeV2` (seen in its
`xctest_runner_*.log` for a working `scrollUntilVisible`), and the driver ships a
`SwipeRouteHandlerV2` test class, so `/swipe` is a v1 leftover. Same payload
shape, same app-space coordinates.

**Why.** On an iPad Pro 11-inch in `landscapeLeft`, `/swipe` answered 200 and
did nothing: fourteen swipes at durations 0.4–1.0s, absolute and normalised
coordinates, produced fourteen identical hierarchies, and `scrollto` reported
`not found after 6 swipes down` with the list unmoved. A silently inert swipe
reads as an app that will not scroll.

The cause is rotation. `/swipe` does not rotate its coordinates and `/swipeV2`
does. Measured in Settings (so no app framework involved) on the iPad, the same
payload to each route, relaunching to a fresh scroll position before each trial:

| device orientation | app frame | `/swipe` | `/swipeV2` |
| --- | --- | --- | --- |
| `landscapeLeft` | 1210x834 | no change, 2 trials | moved, 2 trials |
| `portrait` | 834x1210 | moved, 2 trials | moved, 2 trials |

In landscape the app node is 1210x834 while the status bar is 24x1210. `/swipe`
sends the point through unturned, it lands off the view, and the driver answers
200 because the request was well-formed. On a portrait iPhone the two routes are
indistinguishable across springboard paging, a UIKit list and a Flutter list.
This is a third instance of rule 3's subject, after the resolver and the raw-tap
rule: anything sending a raw coordinate must know whether it is in app space or
device space.

**Done.** All three call sites in `bin/driver.sh` post `swipeV2`, with a test
asserting exactly three `_post swipeV2` calls and one asserting
`reference/driver-api.md` documents `swipeV2`. `reference/driver-api.md` now
lists `swipeV2` as the live route and `swipe` as v1 and unrotated, correct only
while the app frame is portrait.

Not done here: `flow.sh`/the MCP server and `drivers.sh up` evict each other's
XCUITest runner, and the evicted side's next run spends ~35s reinstalling and
can end inside its own timeout without a single swipe. No note or warning for
this was added to `reference/driving.md` or `flow.sh`.

---

## 70. Nothing watches a device for a change over time — **DONE**

**What.** `expect` and `expect-cmd` (`src/bin/driver.sh`) poll once a second, in
the foreground, on one device, against a timeout, for a present/absent answer.
Nothing reports whether a set of rows changed, when, and from what to what,
across devices, for hours.

**Why.** Hand-rolled watchers fail in four ways: a fixed deadline expires before
the event; two watchers on one device write every change twice; a watcher
believed to be running never started, with no way to ask; and the log omits the
filter in force, so it cannot show which view was watched. Rule 5's ban on
`sleep` after a driver call does not cover these poll loops.

**Done.** `bin/watch.py` and the `driver.sh watch` verb:
`watch <pattern> [--context <pat>] [--interval n] [--cycles n]`, plus
`watch status` and `watch stop`. It samples through `driver.sh rows --json`
(item 72).
- No deadline: `--cycles 0`, the default, runs until stopped.
- A failed read logs `ERR` and never updates the baseline; a test checks that an
  identical sample after an `ERR` produces no `CHANGE`.
- `--context` is recorded on every line.
- One watcher per device; a second refuses and names the first.
- `watch status` prints `NOT watching` when nothing runs.
- The diff counts occurrences rather than testing set membership, because a list
  can hold the same text more than once.

Liveness is a claim file plus the log's mtime, and stopping is a file the
watcher polls for. A pid file does not work: each Bash call has its own PID
namespace, so `kill -0` fails on a live process. That fact is recorded in
`reference/connection.md` beside the `nohup` rule.

Nine tests. Verified on an iPhone 16 Pro Max: started under
`run_in_background`, `watch status` answered from a separate call, a second
start was refused, paging the home screen from another call logged `n=4 -> n=6`
with a `CHANGE` line, and `watch stop` ended it and cleared the claim (11
samples, 0 failed reads, 1 change).

Depends on items 71 and 72.

---

## 71. Three facts about detached work, none of them in the skill — **DONE**

**What.**
- (a) `nohup … &` from the agent's side dies with the Bash call: a
  `nohup` loop writes one tick and is gone by the next call.
- (b) The harness's `run_in_background: true` is the mechanism that survives,
  and nothing named it.
- (c) `sleep N; <read the log>` is refused by the harness, which points at
  `Monitor` with an until-loop.
- (d) A detached helper cannot find the project conf: `src/bin/config.sh`
  searches `$MAESTRO_MAC_CONF`, then upwards from `$PWD`, then `~/`, and a process
  started from `$TMPDIR` fails with `not configured for this project`.

**Why.** Watchers die silently, waits are rejected, and every detached helper
needs `MAESTRO_MAC_CONF` passed by hand. Item 70 depends on all four.

**Done.**
- `reference/connection.md` gains "What to use instead, when something genuinely
  has to outlive the call": `nohup` dies, `run_in_background: true` survives,
  `Monitor` with an until-loop is the wait, and anything detached must carry
  `MAESTRO_MAC_CONF`.
- `SKILL.md` rule 9 carries the same facts in four lines.
- `bin/config.sh` step 4: an upward-search hit is written to `$LDIR/conf-path`
  and used as the last resort when the upward search fails. It is only written
  from an upward-search hit, re-checked for readability before use, and the
  refusal message names the detached case and prints the cached path.
- `test/run-tests.sh` gains six cases (upward search, remembering, detached
  fallback, no cache refuses, refusal names the detached case, stale entry not
  trusted) and exports `TMPDIR` into its own scratch so tests never write the
  cache into the real scratch directory.

---

## 72. Nothing extracts a list of rows from the hierarchy — **DONE**

**What.** `driver.sh nodes` dumps every node, `bin/tree.py` renders a tree and
`bin/resolve.py` finds one element. Nothing returns every row matching a
pattern, in draw order, with its frame.

**Why.** The same thirty-line recursive walk of `axElement` was rewritten inline
in heredocs, untested, each copy differing (prefixes, zero-height handling,
sorting), so two logs of the same screen were not comparable.

**Done.**
- `bin/resolve.py` gains `--rows` and `--json` and a `_rows` printer: draw order
  (sorted by y then x), one fixed-column line per row with no diagnostics mixed
  in, and an empty list exits 0 with `n=0` rather than `no visible node matches`.
  Visibility is one of `vis`, `off`, `kbd`, `zero`.
- `bin/driver.sh` gains `rows <pattern> [--json] [--include-hidden]`.
- `SKILL.md`: `find` diagnoses one element, `rows` reads the list.
- Eight tests (draw order, `n=` agrees with rows printed, no match exits 0,
  `--point` still fails on no match, `kbd` marking, token set, `--json` shape and
  count).

Verified on an iPhone 16 Pro Max: 35 rows read off the springboard home screen,
the adjacent page's icons marked `off` at negative x.

---

## 73. `drivers.sh up` with no udid reshuffles every device's ports — **DONE**

**What.** Ports were assigned by walking the booted simulators, so a bare
`drivers.sh up` renumbered devices it was not given, and the relay port
moved with the driver port.

**Why.** A cached port then points at a different simulator: a hardcoded relay
port sent 22 swipes to another agent's iPhone after a restart moved the iPad to
the next port, and an iPad's driver came back on the iPhone's 22087. Drivers were
restarted needlessly, each costing an xcodebuild.

**Done.** Ports are sticky per device, remembered on the Mac.
- `bin/lib.sh` gains `PORTS_MAP` (`$RDIR/ports.map`) with `_ports_read`,
  `_ports_remember` and `_ports_forget`.
- `bin/drivers.sh` replaces `_free_port` with `_port_for <udid> <live> <ports>`:
  the remembered port if nothing live sits on it, else the lowest port no live
  driver and no other device's entry uses, then recorded. A running driver's
  port is recorded as is. The first device still gets 22087, the port Maestro's
  own client requires.
- `drivers.sh ports [list|adopt|forget [<udid>]]`; `adopt` records the running
  drivers' ports without touching them.
- Bare `up` names the devices labelled by another writer on the wall before
  walking them, and warns rather than refuses.
- `adopt` reads its list with `mapfile` before the loop, because `_ssh` passes
  stdin to the remote command and swallowed the rest of a process substitution.
- Nine tests, including a device remembered on 22088 while 22087 is freed by a
  dead driver, which the old rule would have reassigned.

Verified on a Mac with seven simulators booted: `ports adopt` recorded four live
drivers (22087, 22088, 22089, 22092) and restarted nothing; the iPad Pro 11-inch
keeps 22092 / relay 9106.

**Still open.** The relay port is derived from the driver port (`_dport_for`).
Nothing coordinates numbering across Macs or a rebuilt `$RDIR`; a Mac reboot
clears the map and the drivers together (item 79).

Related: items 24, 80.

---

## 74. What loads the Mac is booting simulators, not having them — **DONE**

**What.** Five simultaneous simulator boots with drivers and the wall running
showed 508 CoreSimulator processes and load average 735, and four drivers and a
simulator died. A device budget was proposed.

**Why.** Measurement shows process count is not the constraint:

| state | booted | runtime processes | 1-min load |
| --- | --- | --- | --- |
| steady, wall up | 7 | ~1,470 | **6** |
| 6s into one more boot | 8 | 1,554 | 13 |
| 18s | 8 | 1,633 | **102** |
| 36s | 8 | 1,630 | **123** |
| 60s | 8 | 1,659 | 105, falling |
| after shutting that one down | 7 | 1,467 | falling |

One boot takes the machine from load 6 to about 122 in 36 seconds and decays
once it settles. Simultaneous boots are a transient boot storm, and a driver
started into one is the one that dies. The wall costs one `simulator-server`
per booted device, started unconditionally by `scan_forever` in
`src/remote/wall.py`, and does not move the load.

**Done.**
- `bin/lib.sh` gains `_mac_load`, with the measurement in its comment.
- `bin/drivers.sh up` reads the load first and, above `${LOAD_WARN:-40}`, warns
  that a driver started during a boot is the one that dies, then proceeds.
- `SKILL.md`'s wall step carries the numbers and the rule: boot one at a time,
  wait for each to settle, do not start drivers during a boot.
- Item 76's `rig up` must serialise boots. The number of concurrent boots that
  causes outright failure is not measured; serialising makes it moot.

---

## 75. A wedged simulator answers every tap with success — **DONE**

**What.** After a load spike, touch injection can die while `/viewHierarchy`
still answers: taps and `text` report ok and nothing reaches the app.

**Why.** Every read looks healthy and every write is discarded, which is
indistinguishable from an app ignoring input — and "the app is broken" is
exactly the claim under test when reproducing a bug. This differs from rule 6,
which covers a tap that resolved to the wrong place.

**Done.** No driver route reports touch health, so it is inferred.
- `_wedge_check` in `bin/driver.sh`: an action verb that leaves the hierarchy
  byte-for-byte identical twice running prints a warning naming `probe`. A
  changed screen resets the count.
- `driver.sh probe` taps the blank point the resolver computes for `dismiss` and
  reports whether the tree moved. No change is reported as inconclusive, with how
  to tell the cases apart, and notes that restarting the driver does not fix a
  wedged simulator.
- Five tests.

---

## 76. There is no rig — bring-up, state and teardown of several devices is hand-assembled — **DONE**

**What.** Booting N simulators, starting a driver per device, labelling each on
the wall, and tearing it all down afterwards had no command. Only `build.sh --all`
existed.

**Why.** Each bring-up costs tens of minutes of hand-assembly, and a hand-built
teardown risks shutting down simulators the operator did not boot.

**Done.** `drivers.sh rig up|down|status`.
- `rig up [<udid>...]`, or `RIG_DEVICES` in the conf; refuses when given
  neither. Boots each device and waits it out (`simctl bootstatus`, then the load
  falling back under `LOAD_WARN`) before the next, and only then starts a driver
  per device and labels it. Serialising is item 74's requirement.
- It does not build or install; `build.sh --all` stays a separate, prompted step.
- `rig down` takes down only the devices this Claude Code session booted,
  recorded in `$RDIR/rig/<session>` on the Mac. A device already up, and a driver
  started on a device it did not boot, are left alone.
- `rig status` prints every booted device with driver port, relay port,
  ownership, and the wall label's `by=`.
- `_rig_rename` writes the wall label unconditionally for devices the rig booted,
  because `_label_default` never overwrites and cannot tell a hand-set name from
  one left by an ended session.
- `_rig_status` reads every label in one round trip before its loop, because
  `_ssh` inside a `while read` loop consumes the rest of the pipe.
- Ten tests.

Verified on a Mac with seven simulators and four other drivers: `rig up` booted
a spare iPhone 16e, settled at load 8.84, brought its driver up on 22090 / relay
9104; `rig down` removed only that device; a second `rig up` returned it to
22090 / 9104 (item 73's sticky ports across a full cycle).

---

## 77. Journey edits are blind string replacement, and units cannot be composed without a temp file — **DONE**

**What.** (a) Journeys were edited with inline `s = s.replace(old, new)`; a
replace that does not match rewrites the file unchanged and reports nothing.
(b) `SKILL.md` says to recompose units on the command line, but `script` took
file names only.

**Why.** (a) A failed edit reads as an edit that did not help. (b) Composing
units meant writing scratch `.journey` files into `$TMPDIR` that hold only
`include` lines, untested and invisible to the project.

**Done.** (b): `script --steps 'tapon "^X$"; expect "^Y$"'` runs a sequence with
no file; `;` or a newline separates steps, blanks are dropped, and the temporary
journey is removed afterwards. Three tests. (a) was done as item 83:
`bin/journey.sh edit <file> --replace-once <old> <new> [--dry]`, which exits
non-zero when the old text is not found.

Related: items 49, 60, 83.

---

## 78. `app-notes.md` grew without limit and nothing measured it — **DONE**

**What.** A project's `maestro/app-notes.md` reached 169,005 bytes over 1,302
lines. `SKILL.md` says the notes are read at the start of every run and must stay
short, but `notes.sh` (`init`, `add`, `path`, `promote`) and `preflight.sh` had
no size check.

**Why.** The notes are loaded at the start of every run, so an oversized file
buries the entries about driving the app under ones that are not.

**Done.**
- `bin/preflight.sh` prints `app-notes.md  <lines> · <KB>` and, past
  `${NOTES_WARN_LINES:-400}`, warns and names the archive command.
- `bin/notes.sh archive` opens a dated `app-notes-archive.md` beside the notes
  and lists entries that look superseded by keyword. It moves nothing itself,
  enforced by a test, because only a person can tell a superseded measurement
  from a current one.
- Three tests.

---

## 79. `/tmp/maestro-mac/` does not survive a Mac reboot — **DONE**

**What.** The toolkit's Mac state (`$RDIR`, under `/tmp/maestro-mac/`) is wiped
by a reboot, including the XCUITest runner build.

**Why.** Every driver rebuilds at about 30 s each, which presents as an
unexplained first run, and any hand-patched file there is lost.

**Done.** `reference/connection.md` names what lives in `$RDIR` and goes with a
reboot — the runner build, the copied helper scripts, the wall labels, the
per-device port map (item 73) and the rig claim files (item 76) — and states
that nothing worth keeping across a reboot belongs there.

---

## 80. Two agents driving one Mac have no protocol — **DONE**

**What.** Two agents driving the same Mac at once had no documented rules for
device ownership, port ownership (item 73), or restarting a driver another agent
depends on. Item 24 covers concurrent branch reviews, not this.

**Why.** Without a protocol, one agent's `drivers.sh up` or driver restart lands
on the other's devices, and shared test data lets one agent's actions corrupt the
other's evidence.

**Done.** A "Two sessions on one Mac" section in `reference/driving.md`: claim
devices by labelling them on the wall, never run bare `drivers.sh up`, read the
relay port on every call, announce a driver restart before making it, split test
data by account so neither run poisons the other's evidence, and share a toolkit
finding with the other agent at once.

Related: items 24, 66, 73.

---

## 81. Nothing says to establish whether a timed state can be forced before waiting for it — **DONE**

**What.** `SKILL.md` had no step telling a driver to ask, before waiting for a
timed state (a TTL expiring, a list shedding rows), whether that state can be
reached another way. Item 58 covers fudging a timer in the app source; this is
about not asking the question at all.

**Why.** Waiting for request TTLs to expire took hours. Cancelling the requests
produced the same list shed in forty-two seconds. Any state reached by waiting
is usually also reachable by a backend action, a config override, or an
equivalent user action with the same effect on the thing under test.

**Done.** Rule 10 in `SKILL.md`, ahead of "Test before you report a capability
impossible" (now rule 11): name the event, then name the three routes to it —
wait, backend action, config override — and say which is being taken and why,
before the waiting starts. Where the project has an API client, the backend
action is usually already there. Item 58's warning is cross-referenced on the
config-override route. `reference/app-notes-template.md` gains a **Forcing a
state** heading, so the route is written down the first time it is worked out.

---

## 82. A request to drive the app starts `flutter-hot-reload-mac` instead — **DONE**

**What.** A request to drive an already-installed app's UI can be routed to the
sister skill `flutter-hot-reload-mac`, which builds and launches from source.

**Why.** Hot reload starts a source build when the app is already installed and
only needed driving.

**Done.** Owned by `flutter-hot-reload-mac` item 16; nothing to change here. The
fix there is a `PreToolUse` hook on that skill's entry points that checks whether
the app is already installed on the target simulator and, if so, names this
skill and stops. The worked precedent for such a hook is
`skill/hooks/gate-journey-first.sh`, and hooks are registered by `install.sh`.

---

## 83. A journey edit is a blind string replacement — a no-match rewrites the file unchanged and says nothing — **DONE**

**What.** Item 77 gave `script --steps` for composing units inline, but editing a
journey file was still `s.replace(old, new)` against a multi-line block, typed
into a heredoc. Item 49's "repair the journey in place" rule had no other
mechanism.

**Why.** A replace whose `old` does not match rewrites the file byte-identical
and reports success. A failed edit is indistinguishable from an edit that did
not help, and the next re-run of the journey is read as a fact about the app.

**Done.** New `bin/journey.sh`:

```sh
journey.sh edit <file> --replace-once '<old>' '<new>' [--dry]
journey.sh edit <file> --replace-once --old-file <f> --new-file <f> [--dry]
journey.sh show <file>
```

`--replace-once` is the only mode. `old` absent → exit 3, nothing written, and
the closest line in the file is printed delimited and unstripped, with "They
differ only in whitespace" when that is the difference. `old` matching more than
once → exit 4, nothing written. A single match prints the unified diff and
writes. `--dry` prints the diff and writes nothing. A bare name resolves in
`$JOURNEY_DIR`, as `driver.sh script` does. Nine tests; a no-match test needs
text that is genuinely absent, since a substring (`dismis` in `dismiss`)
matches. Reads with items 49 and 77.

---

## 84. An `_ssh` inside a loop reading from stdin eats the loop's input — **DONE**

**What.** `_ssh` passes stdin to the remote command by design. A `while read`
loop fed by a pipe or a redirect loses every unread line the moment an ssh call
runs inside it. `_journey` already read on its own fd for this reason (item 36),
and `drivers.sh up` carried a comment about it, but new code still repeated the
defect.

**Why.** The loop runs once, silently, and exits 0. `drivers.sh ports adopt`
reported 1 live driver where 4 were up; `_rig_status` printed 1 booted device
of 7; `bin/device.sh list` would list only the first registered phone. Comments
in the file did not prevent it, which is item 51's argument for a check over
more guidance.

**Done.** `bin/lint-stdin.py` walks each `while read` loop fed by a pipe or
redirect and flags an `_ssh`, `scp` or `ssh` in its body. It does not flag three
correct shapes:

- `read -u <fd>` — an explicit descriptor, item 36's fix in `_journey`
- a one-line `while ... done < <(...)`, where the ssh feeds the loop rather than
  sitting in its body
- a call that closes its own stdin with `</dev/null`

It runs in `test/run-tests.sh` over the whole source, so a release cannot be
cut with a hit. `bin/device.sh list` is fixed with `mapfile` before the loop.
Six tests, one for each shape that must not be flagged.

---

## 85. SSH and network setup is seven manual steps across three files that must all agree — **DONE**

**What.** `reference/setup.md` describes the SSH and network setup, and it was
done by hand. It spans files that must agree: a new address for the Mac goes
in `~/.ssh/config` (a `Host` block), `/etc/hosts` (the `.local` name) and
`~/.claude/settings.json` `sandbox.network.allowedDomains`. Two out of three
produces a failure that looks like something else. The steps were:

1. Key creation. Every script passes `BatchMode=yes`, so a key with a
   passphrase fails at once with no explanation; the key must be made with
   `-N ''`. The documented `ssh-keygen` command had not been followed for the
   key actually in use.
2. Copying the key to the Mac. `ssh-copy-id -i <key>.pub <user>@<addr>`
   authenticates with the Mac's login password, so it must run in the
   foreground, uncaptured and without `BatchMode=yes`. Once per machine:
   `authorized_keys` is one file whatever address reaches it. Connection
   refused on 22 means Remote Login is off; a timeout means the wrong address
   or network.
3. `~/.ssh/config`. One `Host` block per network, identical but for
   `Hostname`, each with the socat `ProxyCommand` through the sandbox proxy
   (`%s` doubled, because ssh_config expands `%`). `_probe` in `bin/lib.sh`
   puts its own `ConnectTimeout` on the command line, which beats the file. A
   duplicate stanza is silently shadowed, because ssh takes the first value for
   each keyword.
4. `/etc/hosts`. One line per network mapping `<mac>.local` to that network's
   address. The resolver returns all of them and the client tries each in
   file order, so the most-used network goes first. Needs root.
5. `allowedDomains`. The name and every address. Without it the proxy refuses
   and the Mac reads as switched off while SSH works. Must be a union with
   existing entries.
6. Per project: `.maestro-drive.conf` (handled by `bin/init.sh`) and the
   `Bash(ssh …)` / `Bash(scp …)` permission allows, which nothing wrote or
   checked, so every `ssh` and `scp` waited for a permission prompt.
7. Optional, Mac side: `/usr/local/bin/network-change.sh` driven by
   `/Library/LaunchDaemons/networkChange.plist` (label
   `com.you.networkchange`, `WatchPaths` over `/var/run/resolv.conf`,
   `NetworkInterfaces.plist` and `com.apple.airport.preferences.plist`, plus
   `RunAtLoad`). It applies a per-SSID static IPv4 profile to the Wi-Fi service
   and is idempotent, because `WatchPaths` fires two or three times per real
   change. A router with DHCP reservations gives the same result.

**Why.** The instructions were correct and still done wrong, because they are
read once, at a moment they cannot be acted on (the argument of items 51 and
56). Items 18 and 48 are symptoms of the same gap.

**Done.** `skill/setup/wizard.sh`, installed with the skill so it can be
re-run without the repository. `install.sh` offers it when the phase A marker
`~/.local/share/maestro-drive/phase-a-done` is absent. There is no state file:
the `Host` blocks, `/etc/hosts` lines and `allowedDomains` entries are the
record.

- **Phase A, once per machine.** Asks the Mac's username and `.local` name
  (adding the `.local` suffix when absent, and challenging a name that differs
  from the configured one), and an existing key or a new `ed25519` one. Runs
  `ssh-copy-id` in the foreground and verifies with `BatchMode=yes`; the
  marker is written only after that verification returns 0. The key path is
  read back from `IdentityFile` in an existing block. A re-run prints the
  username, `.local` name and key with the file each came from, offers to
  change them, and asks which `Host` blocks a change reaches. `--edit` runs
  this alone.
- **Phase B, once per network, one network per run.** Asks the place name and
  address. Writes `allowedDomains` first, because the sandbox proxy carries
  only what that list names (an unlisted address gets `Bad Gateway`), so a
  probe of a new network cannot pass before it. Then probes, then writes the
  `Host` block, updating an existing alias in place and dropping a replaced
  address from `allowedDomains`. Every probe passes `PROXY_CMD` with `-o`,
  because a raw `$user@$address` has no `Host` block and so no
  `ProxyCommand`.
- **Phase C, optional, offered after a new phase B.** Discovers the Wi-Fi
  device, preferred SSIDs (`networksetup -listpreferredwirelessnetworks`),
  mask, gateway and DNS (`networksetup -getinfo`, `netstat -rn`) live on the
  Mac, keeping DNS order with the gateway first. The static address defaults
  to the current address with the last octet `250`, is prompted for rather than
  assumed, and is refused if it answers `ping`. `splice_profile` and
  `drop_profile` add or replace one SSID arm in the Mac's own script, anchored
  with `^` and `re.M` so a commented-out arm is not matched, and the result is
  checked with `bash -n`. The five `sudo` install commands are run over
  `ssh -tt` (the one call exempt from item 84's `-n` rule, capped by a test)
  or printed to be run by hand. `/usr/local/bin` is created with
  `[ -d ] || install -d` because it does not exist on a fresh Mac and BSD
  `install -d` rewrites an existing directory's mode and owner. Wi-Fi is then
  cycled by a detached
  `nohup /bin/sh -c "sleep 2; networksetup -setairportpower en0 off; sleep 5; networksetup -setairportpower en0 on"`
  (no `sudo` needed), and the poll waits for the connection to drop before
  waiting for it to recover, since a poll started at once succeeds on the
  connection about to be lost.
- **`/etc/hosts`, written last**, once the address is final. One question,
  after the diff. Both `sudo cp` calls are checked, and a failure names which
  files were written and which were not. The "network to try first" default
  is the alias that answers a probe.
- **Modes.** `--status` writes nothing and prints the account each alias
  connects as; `--hosts` re-runs the `/etc/hosts` step; `--dry-run` asks and
  reads everything and writes nothing; `--list` prints which of the three
  files knows each network; `--remove [<alias>]` reverses phase B (Host block,
  then its `allowedDomains` address, then `write_etc_hosts`) and with no alias
  offers the list. `--remove` refuses the last network, a `Host` line naming
  several aliases, an unknown alias (exit 2, listing what is configured) and
  an address another alias still uses. It leaves the key, the marker and the
  Mac's profile alone.
- **Robustness.** `mac_run` always succeeds and prints nothing when the Mac is
  unreachable, so `set -euo pipefail` no longer kills the script mid-phase;
  `phase_c` and `write_etc_hosts` failures are reported and the run carries
  on. Every `ssh` except `ssh-copy-id` and the `-tt` install passes `-n`,
  because ssh otherwise swallows the answers queued on stdin. Variables are
  initialised under `set -u` for a machine with no `Host` block. Diagnosis
  keeps all of stderr, not `tail -1`, so the proxy's `Bad Gateway` is not lost
  behind `kex_exchange_identification`. A same-subnet address with no ARP
  reply is named as access-point client isolation, not a fault on the Mac.
  OpenSSH 9.8's per-source penalties (`min:15`, `max:600`) are named, and the
  retry says to wait. Declining the `settings.json` write explains that the
  `.local` name for `/etc/hosts` is read from it.
- **Per-project allows, in `bin/config.sh`.** After the conf check, it reads
  `permissions.allow` from `~/.claude/settings.json` and the project's
  `.claude/settings.local.json`, and glob-matches them against `ssh <host>`
  and `scp <host>` for every alias in `MAC_HOST`. It prints what is uncovered
  once per Claude Code session (marked in `$LDIR`), blocks nothing, and
  suggests the longest common prefix of the aliases (`mac-a mac-b` gives
  `Bash(ssh mac-*:*)`). A shell script cannot write either settings file, so
  Claude writes the chosen one. Not a hook, which could not write the file
  either and would run on every Bash call. The suffix strip is manual, because
  `python3` 3.8 lacks `str.removesuffix`.
- **Vendored Mac files.** `skill/setup/network-change.sh` (one example SSID on
  `192.0.2.0/24`, a header explaining each value; the misspelt
  `ipconfig sertverbose 0` in `current_ssid()` fixed) and
  `skill/setup/networkChange.plist` verbatim. The real SSID table stays on the
  Mac.

Verified live against a real Mac for phases A, B and C: phase B's probe and
write on a new network, phase C's install and Wi-Fi cycle with the daemon
firing on reassociation, and a `--remove` and re-add round trip on the real
files. Covered by 144 package cases: decisions written against copies in
`$TMP`, the fresh-machine path, `sudo` stubbed to fail and succeed, the
re-run path, each diagnosis arm, and the add/remove round trip leaving
`ssh_config` and `/etc/hosts` byte-identical and `allowedDomains` identical in
value. The harnesses stub `ssh`, and the suite unsets `grpc_proxy`, so it does
not touch the network. Not exercised: phase C applying a new static address,
as opposed to confirming one already held.

---

## 86. Ten test cases fail between midnight and 02:00 — **DONE**

**What.** The wall section of `skill/test/run-tests.sh` failed ten cases when run
between 00:00 and 02:00, with no code change. One assertion was date-sensitive.
The other nine were collateral from the harness shape.

The `label-stale` case backdates a label's mtime by two hours and expects
`read_label` (`skill/remote/wall.py`) to report it stale. With
`HIDE_FROM_PREVIOUS_DAY` on, `read_label` returns `{}` for a label whose mtime
falls on a different calendar day. Between 00:00 and 02:00, two hours ago is
yesterday, so `["stale"]` raised `KeyError`.

The wall section is one `python3` heredoc printing a named result per line,
checked by name in a shell loop. One exception meant every later name printed
nothing and was reported as "no result": `label-empty-file`, `label-by`,
`label-no-by`, `day-today-fresh`, `day-today-not-stale`, `day-today-old-kept`,
`day-today-old-greyed`, `day-yesterday-hidden`, `day-crossed-midnight-hidden`.

**Why.** `test/run-tests.sh` is the release gate (item 17). A gate that fails on
the clock gets overridden, and that lets a real failure through. The harness
also reported nine unrelated cases as failures, so the output named the wrong
behaviour as broken.

**Done.** Both halves fixed.

- The staleness case sets `w.HIDE_FROM_PREVIOUS_DAY = False` around itself and
  restores it afterwards. Staleness and day-hiding are separate behaviours;
  day-hiding has its own cases.
- Each case runs through a `check(name, fn)` helper that catches its own
  exception and prints `<name> False <ExcType>: <msg>`. Twenty-eight cases
  converted. An injected `KeyError` in `label-stale` now fails that case alone
  and names the cause.
- 367 passed in the skill's suite; 52 passed in the package's.

Left as is: `day-today-old-kept` and `day-today-old-greyed` print `True` without
testing anything when the run starts within three hours of midnight. They need
a same-day mtime, so suppressing day-hiding would defeat them.

## 88. A simulator booted by a session that has ended stays booted for ever — **DONE**

**What.** Labels have a reclaim path (item 67) and boots did not.
`bin/drivers.sh` calls `_rig_claim` only on the branch that boots a device; a
device that is `already booted (leaving it alone)` is not recorded, and
`rig down` and the `SessionEnd` hook take down only what is claimed. That
scoping is deliberate (item 74): taking a peer's simulator down mid-run is
worse than leaving one behind.

**Why.** Measured: seven simulators booted on the Mac with an empty claim
ledger (`/tmp/maestro-mac/rig`), so `rig down` and the hook were no-ops on all
seven. Five had not written app data for two days, and three of those still had
a live XCUITest driver nothing had run against. The only way to stop them was
`xcrun simctl shutdown` by hand. Idle simulators are cheap on load (item 74:
seven booted with the wall up sits at load 6; booting one more took the Mac to
122 within 36 seconds), but tiles nobody has touched for days make the shared
wall unreadable.

**Done.** `drivers.sh rig reap` applies the label reclaim's three tests to the
boot: no session claims it, no driver is live on it, and nothing has written to
it since a previous calendar day. It lists and stops; `rig reap --shutdown` is a
separate command that shuts them down and clears their labels. The threshold is
the calendar day, as for wall names; `LABEL_STALE_AFTER`'s hour is far too short
for a boot. Freshness is read one level inside each app container
(`Documents/`, `Library/`), because a container directory's own mtime only
moves when its immediate contents change. Seven cases with the Mac calls
stubbed: each of the three tests keeps a device on its own, and one fixes the
calendar-day rule against an hour count with a last use at 23:00 the previous
day. Not built: showing an unclaimed, driverless, previous-day simulator as such
on the wall.

## 89. `wall.sh label` swallows every flag it does not know, including `--help` — **DONE**

**What.** `bin/wall.sh`'s label parser ended with
`*) name="${name:+$name }$1"`, so any argument that was not a udid or `--group`
became label text. `wall.sh label --help` set the label to `--help`; a mistyped
`--groupp <name>` set it to `--groupp <name>`. Both exited 0 and printed the
label as though it were what was asked for. `--group` with no value took
`${2:-}` and then `shift 2` on a single argument.

**Why.** With no udid the label goes to whatever `_dev` resolves to, which on a
shared Mac can be a peer's device. A `--help` call overwrote the only record of
what another session had been driving on that device. Item 67's subject is that
a label is evidence of who is driving what.

**Done.** `-h|--help` prints the usage and exits 0. `--group` with nothing after
it is refused. Any other `-*` is refused with the usage and the `--` escape. A
label that starts with a dash still works after `--`. Every refusal happens
before `_dev` is consulted, so none reaches a device. Six cases, including one
asserting `label --help` never connects. `bin/drivers.sh` and `bin/notes.sh`
were checked for the same shape; neither has a catch-all that turns an argument
into something written to a shared machine.

---

## 91. A live driver stopped protecting another Claude Code session's simulator label — **DONE**

**What.** The live-driver guard in the label reclaim (`_wall_label`, now
`_label_default` in `bin/drivers.sh`) is a `$( )` inside a double-quoted
`_ssh` string, so the local shell expands it and the `awk` runs locally. Its
field references were escaped as `\$1` and `\$2`, as though it ran on the Mac.
`awk` died with `awk: backslash not last character on line`, the substitution
came back empty, and the test was always false.

**Why.** A label is reclaimed only when it names a different session, that
device has no live driver, and the label is older than `LABEL_STALE_AFTER`.
With the driver guard dead, only the age check stood: a label older than
`LABEL_STALE_AFTER` on a device another live session was driving would have
been renamed, which is the failure item 67 added the guard to prevent. The
tests missed it because they reimplemented the reclaim in shell, and because a
recent label is kept by the age check whether or not this guard fires.

**Done.** The `awk` field references are unescaped so the local `awk` parses
them. A new test reads the shipped string from the file rather than
reimplementing it.

---

## 92. Three wrong-shell mistakes across the SSH boundary — **DONE**

**What.** Item 91 belonged to a family of defects where code runs in a
different shell from the one it was written for. A search found three shapes:

- a local `$( )` escaped as though it ran on the Mac — item 91 was the only
  instance;
- a POSIX helper run by the shell ssh hands over on the Mac, which is zsh;
- a pipe that discards the exit status of the command before it.

**Why.** `remote/gitstate.sh` used two constructs zsh does not share — zsh
neither word-splits an unquoted expansion nor globs an unquoted `case`
pattern — so it reported every lock file as uncommitted work.
`remote/appcheck.sh` had the same shape and worked by chance. On the remote
side, `sh module inspect … | tail -1` returned `tail`'s status, so an exit 2
arrived as success. `bin/flow.sh` ran `maestro test | grep | tail`, so every
flow reported success.

**Done.** `remote/gitstate.sh` and `remote/appcheck.sh` are executed with
`sh … --run`, so zsh is out of the path. The `tail -1` and `bin/flow.sh` pipes
keep the real exit status. `bin/flow.sh` no longer ends on
`if [ -n "$SHOT" ]`, whose false condition exited 0. The tests now read the
shipped files rather than modelling their intent.

---

## 94. Every verb goes over SSH, even when the device is on the same machine — **DONE**

**What.** The package assumed a Linux host driving a remote Mac.
`bin/config.sh` refused to load without `MAC_HOST` and `MAC_FQDN`, so a
simulator or emulator on the machine running the package could not be driven.
84 `_ssh "<script>"` calls across 21 files go through one function in
`bin/lib.sh`; 16 raw `ssh`/`scp` calls across 12 files do not.

**Why.** Without a local path the package cannot be used on a Mac with its own
simulator or a Linux machine with its own emulator. The six boundary pieces —
`relay.py`/`publish.sh`, `$grpc_proxy`, base64 file round trips, host picking,
`MACIP`/`MAC_FQDN`, and separate `$RDIR`/`$LDIR` — are not merely unneeded
locally; several break: a proxy refuses loopback, a self-copy truncates the
checkout, `ipconfig getifaddr en0` fails on Linux.

**Done.** A `TRANSPORT` setting and a local branch through the stack, with the
ssh path unchanged at every step and the 84 `_ssh` call sites untouched. The
runner modules needed no change: they already run on the device machine as
`sh <module> <verb>`.

- **Stage 1 — the switch (`config.sh`, `init.sh`).**
  - `TRANSPORT` in `.maestro-drive.conf`, default `ssh`, exported; an unknown
    value such as `sssh` is refused by name with exit 1. Explicit rather than
    inferred from an empty `MAC_HOST`, so a misspelt `MAC_HOST` still fails as a
    broken remote conf instead of hunting for a local device.
  - Required settings per transport: local needs `APP_ID` alone. Two separate
    unconfigured-project messages; the ssh one is byte-identical to before.
  - The `permissions.allow` check for `ssh <host>`/`scp <host>` is skipped
    locally (an empty alias list already printed nothing; the guard stops that
    depending on `MAC_HOST` having no default).
  - `bin/init.sh --local --detect` reports this machine's toolchains, devices,
    AVDs and checkout; `--local --app <id> --write` writes `TRANSPORT`,
    `APP_ID` and a detected `PLATFORM` (`adb` only → `android`, `xcrun` only →
    `ios`, both → refused asking for `--platform ios|android`, neither →
    refused naming the missing SDK), with the evidence written above the
    setting. `RUNNER` is detected locally by running the module's `claim` out
    of `$RUNNERS`. `--local --host` and a missing `--app` exit 2.
  - AVDs are split into those Maestro can drive (API 29, 30, 31, 33, 34, per
    the mirrored Maestro 2.8.0 docs) and unsupported, reading the level from
    each AVD's `config.ini` `image.sysdir.1`; an unreadable level shows `(?)`
    and counts as unsupported.
- **Stage 2 — `_ssh` runs the script here.**
  - Local branch: `sh -c`, no `_pick_host`, `_probe_host` or `SSH_OPTS`, no
    retry or re-pick (a local 124 is the command itself), still bounded by
    `$TMO`. `LOCAL_ENV` adds to `PATH` instead of replacing it as `REMOTE_ENV`
    does, which would drop an Android SDK on a non-standard path and make every
    android verb fail as `command not found`.
  - `$RDIR` split: it keeps the scratch; code is `RMODS` and `RHELP`
    (`$RDIR/runners` and `$RDIR` across ssh; the checkout's `runners/` and
    `remote/` locally).
  - `bin/install.sh` pushes nothing locally: `$RHELP`/`$RMODS` are the
    checkout, its `cat > dst < src` would truncate every helper and module, and
    its `chmod +x` would leave mode changes in `git status`. It still makes
    `$RDIR` and `$RDIR/flows`.
- **Stage 3 — the 16 raw calls.**
  - `_push` (eleven sites): adds the host across ssh, copies locally, and
    treats source equal to destination as a no-op, because `cp a a` exits 1
    with *are the same file* and every caller ends `|| exit 1`.
  - `_pull`: `scp` across ssh, `cp` locally. `$RDIR` and `$LDIR` stay distinct:
    `$RDIR` holds machine-wide state (`PORTS_MAP`, driver labels, the rig
    record) and `$LDIR` is per-run `$TMPDIR`. `shot.sh` folds the fetch into the
    screenshot `_ssh` across ssh and uses `_pull` locally; `flow.sh` and
    `docs-refresh.sh` use `_pull`; `img.sh`'s `mac` backend is refused locally,
    naming the missing image tool.
  - `bin/mcp.sh` `exec`s `maestro mcp` locally. It cannot use `_ssh`, whose
    `timeout $TMO` would kill a stdio server three minutes in.
  - `bench.sh` reports no round trip locally; `publish.sh` uses `127.0.0.1`
    without `ssh -G`.
  - `_where` prints the narrowed alias across ssh and `this machine` locally,
    in eleven messages that printed `no booted device on  (platform: android)`.
- **Stage 4 — the boundary pieces leave the local path.**
  - Relay: `_urlhost` and `_driver_base` give `127.0.0.1` with the service's
    own port (22087 for the driver, not the relay's 9101); a host-only
    substitution would have built a URL for a port nothing listens on.
    `driver.sh` drops the `lsof` check; `driver.sh stop`, `viewer.sh stop` and
    `publish.sh stop` report that there is no relay to stop; the viewer's
    blank-picture note prints only across ssh.
  - `$grpc_proxy` is emptied and exported in local transport (`curl -x ""`), so
    `publish.sh`, `net.sh` and `runners/flutter/framework.sh` all go direct. It
    now defaults to empty in both transports, fixing a `set -u` abort when unset
    outside the sandbox.
  - Wall: `wall.sh:_url` uses `_urlhost`; `wall.py` binds `127.0.0.1` locally
    and `0.0.0.0` across ssh or when `WALL_URL` is set. `_check_simulatorkit`
    is gated on `PLATFORM=ios`; it had blocked every Android wall.
  - `_macip` is refused locally with a message that there is no Mac and URLs use
    `127.0.0.1`; `bin/macip.sh` exits 1.
- **Stage 5 — proof and docs.**
  - The suite runs both transports with no Mac: conf shapes, `init.sh --local`,
    `_ssh`, `_push`/`_pull` including self-copy, `install.sh` checked by md5 of
    `remote/` and `runners/`, and `mcp.sh` with a poisoned `ssh` on `PATH`.
  - `runners/android` was exercised verb by verb against `Pixel_6_Pro_API_34`
    (API 34, Maestro 2.10.0) through item 96's bridge. Fixes: both platform
    modules had `container)` twice, so `data-container` answered *unknown verb*,
    and carried a stray `data-installed-info`; `runners/ios-device` gained
    `uninstall` (from `devicectl`, unmeasured), which `driver.sh clearstate`
    calls; android `install` sends adb's output to stderr; `locked` is
    implemented from `mIsShowing` under `KeyguardStateMonitor`, not `mAwake`,
    which tracks the screen (1 asleep, 1 awake, 2 for an unattached serial).
    `container`, `orientations` (needs `aapt2 dump xmltree` and the APK) and
    `last-used` refuse with the reason; the driver trio is item 87's 4.4.
  - Docs: `setup.md` has a table of which of the ten setup steps apply locally;
    `SKILL.md` states once that "on the Mac" means the machine with the device
    and `TRANSPORT` decides which; the frontmatter description covers a
    simulator or emulator, remote or local. All three state that the live run
    went through the bridge and that no local iOS simulator has been driven.
  - Name: `maestro-drive`, matching the skill's main trigger phrase. The conf
    file becomes `.maestro-drive.conf` with no fallback read of the old name;
    `flutter-hot-reload-mac` reads the same file and moves with it. Carried out
    in item 98. The MCP entry `maestro-mac` is left to item 97: renaming it
    changes the tool names to `mcp__maestro-drive__*`, and `uninstall.sh` knows
    only the current name, so `manifest.sh` needs a legacy-names sweep first.

Verified: 555 passed in the skill's suite and 150 in the package's, including
guards that no platform module carries a duplicate case label and that
`runners/ios`, `runners/ios-device` and `runners/android` each answer every
contract verb (exit 2 counts, *unknown verb* does not). Live results are in
item 96.

## 95. `JAVA_HOME` and Maestro's directory were one installer's paths, hardcoded — **DONE**

**What.** `lib.sh` set `JAVA_HOME=$HOME/.sdkman/candidates/java/current` in
`REMOTE_ENV`, and `LOCAL_ENV` copied it as a fallback. `REMOTE_ENV` also put
only `$HOME/.maestro/bin` on `PATH`, which is where Maestro's installer puts it
and nowhere else.

**Why.** A machine using jenv, mise, asdf, jabba, a Homebrew JDK or an apt JDK
got a `JAVA_HOME` naming a directory that does not exist. Maestro's CLI is a
Gradle start script, which uses `$JAVA_HOME/bin/java` whenever `JAVA_HOME` is
set, so a set-and-wrong value aborts it where an unset one would let it find a
JDK. A Maestro installed elsewhere and exported from `~/.bashrc` is invisible to
the non-interactive shell running the package, so no flow can run.

**Done.**

- **`remote/javahome.sh` asks the machine, in four rungs:**
  1. `$SHELL -ic 'printf %s "$JAVA_HOME"'`, stdin closed: whatever any version
     manager's shell init set.
  2. `/usr/libexec/java_home`: macOS's registry, for an Apple or `.pkg` JDK.
  3. The login shell's `java`, resolved through its symlinks, rejecting
     `/usr/bin/java` (a stub on macOS).
  4. `java -XshowSettings:properties -version`, reading `java.home`. This
     covers shim managers (jenv without its `export` plugin, mise or asdf via
     shims), where rung 3 resolves to the shim's directory. Last because it
     starts a JVM, about 0.2s.

  On a Mac with SDKMAN only rung 1 answers: rung 2 prints `Unable to locate a
  Java Runtime` and rung 3 returns `/usr`.
- **Detected once, at setup, recorded as `RJAVA`.** `bin/init.sh --detect`
  prints it and `--write` records it, in both transports. Per-command discovery
  was rejected: an interactive shell with no tty hangs (one run in three took
  the full 60s), which `$TMO` would turn into a three-minute stall inside
  `_ssh`.
- **A recorded `RJAVA` is checked on the far side before export.** If the
  directory is gone it names the path and falls back.
- **No `RJAVA`:** `lib.sh` tries rungs 2 and 3 per command, never an
  interactive shell, and when neither answers prints the `init.sh --detect ...
  --write` command to run. An existing conf loses `JAVA_HOME` until that is run.
- **Maestro's directory.** `remote/whereis.sh` asks the login shell where an
  executable lives; `bin/init.sh` records it as `RMAESTRO` only when it differs
  from `$HOME/.maestro/bin`, and the env prefix appends it to `PATH` rather
  than replacing the default, so older confs keep working.

Verified: `java -version` over `_ssh` against a Mac returns Temurin 21 with
`JAVA_HOME` from `RJAVA`; `init.sh --host <alias> --detect` prints the path and
version. 503 passed in the skill's suite, 145 in the package's, eleven new: a
JDK known only to a fake shell init, one reachable only through a shim, a stale
`RJAVA` falling back and naming the missing path, the fallback never opening an
interactive shell, and no JDK at all (skipped rather than failed when the
machine has no JDK on any rung). The suite keeps `REAL_HOME` before redirecting
`HOME`, so rung 1 can read the real shell init. Rung 2 against an Apple or
Temurin `.pkg`, and Homebrew's keg-only `openjdk` via rung 3, are reasoned but
not run.

---

## 96. A device on a sandboxed Linux host is unreachable from the Bash tool — **DONE**

**What.** Local transport (item 94) runs `_ssh` scripts through `sh -c` on the
same machine. Inside Claude Code's Linux sandbox that machine is the sandbox:
`/dev/kvm` absent, its own PID namespace (4 processes), its own network
namespace (`lo` only), and writes limited to the working directory and
`$TMPDIR`. An x86 emulator cannot start there. The SSH transport works only
because the Mac is outside the sandbox doing the work.

**Why.** A local conf on a sandboxed Linux host cannot boot or reach an
emulator at all. An MCP server spawned by Claude Code runs outside the sandbox
(`/dev/kvm` present and openable, the AVD directory writable, the host's
processes and interfaces), and the scratch directory under `/tmp` is a real
host directory both sides see. A FIFO made in the sandbox and written by a host
process delivers its bytes. That is the channel. On macOS none of this
applies: seatbelt has no PID or network namespace, so local transport reaches a
simulator directly.

**Done.** A third transport, `TRANSPORT=bridge`: a generic channel carrying the
same script `_ssh` already carries, rather than per-script or per-verb MCP
tools, which would add a second way to drive kept in step per platform and
transport. It carries arbitrary shell to the host outside the sandbox, with no
review of the traffic. The controls: it is started explicitly, every script it
runs is logged, and it stops at SessionEnd.

| | ssh | local | bridge |
| --- | --- | --- | --- |
| a shell script reaches the device host | `ssh` | `sh -c` | the channel |
| a file reaches it | `scp` | `cp` | `cp` |
| an HTTP client here reaches a port there | relay + proxy + `$MAC_FQDN` | `127.0.0.1` | relay + proxy + `BRIDGE_HOST` |

- **`remote/bridge.sh`, the host-side helper.** One directory per run under the
  shared scratch, with a random component in its name; a directory owned by
  another uid is refused. A control FIFO carries a request id; each request has
  its own `<id>.cmd`, `<id>.in`, `<id>.out`, `<id>.err`, `<id>.rc`, so
  concurrent calls cannot collide. `out` and `err` are FIFOs the client makes,
  so output streams as produced (the first line of `echo first; sleep 2; echo
  second` arrives in under a second). Every script is appended to a log beside
  the directory. Running it detached from the Bash tool is refused by the
  harness as *Containment Escape*; started and stopped inside one call it is
  permitted, which is how the suite runs it.
- **`_ssh` bridge branch.** `_payload` assembles the environment prefix,
  `cd $REPO` and the caller's script once for all three transports; local and
  bridge produce byte-identical text. ssh differs deliberately: `REMOTE_ENV`
  replaces `PATH`, `LOCAL_ENV` adds to it. Stdin is a FIFO fed by a background
  writer, not drained to a file up front (that stalled every call whose caller
  left stdin open); the writer names the call's stdin through fd 9, because a
  background command in a non-interactive shell otherwise gets `/dev/null`.
- **Failure rules.** No helper serving: say so, run nothing, return 1, no retry
  (half of what goes through `_ssh` taps a screen). A command that outruns
  `$TMO` is ended by the far side's `timeout` and 124 comes back once; the log
  shows one invocation. No `.rc` file after the channels close is reported, not
  read as 0.
- **Two predicates replace about thirty transport tests in `bin/`.**
  `_fs_shared` (ssh no, local yes, bridge yes) governs `_push`, `_pull`,
  `$RHELP`, `$RMODS`, `mcp.sh` and `install.sh`, so a push is a copy onto
  itself. `_ports_here` (ssh no, local yes, bridge no) governs `_urlhost`,
  `_driver_base` and `$grpc_proxy`, because under the bridge the driver binds
  the host's loopback, which the sandbox cannot reach, so it is read through
  `relay.py` as the Mac's is. `_macip` returns the conf's `BRIDGE_HOST`. The
  four stub `lib.sh` files in `test/run-tests.sh` carry the predicates.
- **`bin/bridge-mcp.py`.** One tool, `bridge`, with one argument, an enum of
  `start|stop|status`; it can run nothing but `remote/bridge.sh`. Booting a
  device is `platform.sh boot` sent over the bridge like any other script.
  `start` prints the three conf lines to paste (`TRANSPORT`, `BRIDGE_DIR`,
  `BRIDGE_HOST`, the last from `hostname -I`) and the log path; an empty
  `hostname -I` is reported as the server having been spawned inside the
  sandbox. It also answers `--start`, `--stop` and `--status` on the command
  line for hooks.
- **Teardown.** `rig-down-on-end.sh`, the SessionEnd hook, takes the rig down
  first and then stops the helper, in one detached subshell: under the bridge
  `rig down` travels through the helper. The log is left behind.
- **Installer.** `install.sh` asks `[Y/n]` before registering the
  `maestro-bridge` MCP server. `--with-bridge` and `--no-bridge` answer in
  advance; `--yes` or no terminal registers nothing and prints the flag. An
  existing registration is kept and never re-asked, so `update.sh` and
  `--no-bridge` never remove it. `uninstall.sh` removes both MCP entries.
- **`mcp.sh` execs the Maestro MCP server directly under the bridge**: it is
  spawned by Claude Code and is already outside the sandbox.
- **Faults found by the live run.** `platform.sh boot` used `nohup`, which
  leaves the emulator in the caller's process group; every bridge request runs
  under `timeout`, which signals its group, so the emulator shut down after the
  call. It now uses `setsid`. `bin/flow.sh` resolved the device before reading
  its flow, so `_dev`'s round trip consumed the heredoc and Maestro reported
  *Commands Section Required*; the flow is read first now (latent on ssh too).
  Maestro missing from the far side's `PATH` is item 95.

Verified: 544 passed in the skill's suite, 34 bridge cases among them with the
helper started in-process (no Mac, no device), and 150 in the package's. Live
against `Pixel_6_Pro_API_34` on a Linux host through the bridge: `platform.sh
boot` gives `emulator-5554`; `devices --booted`; `install.sh` copies nothing
and makes `/tmp/maestro-mac`; `shot.sh` pulls back PNGs; `prefs.sh` reads the
app's shared preferences; `net.sh` correctly finds no VM service for an app not
under `flutter run`; `flow.sh` completes a `launchApp` and returns the
hierarchy and a screenshot. The far side had `/dev/kvm`, 8 CPUs and Java 17
from `$RJAVA`. `drivers.sh rig up` not run: `driver-up` is item 87's 4.4.

**To do.** `install.sh` decides whether to ask with `[ -t 0 ]` and reads with a
plain `read`, while `update.sh` and `uninstall.sh` read from `/dev/tty`. Under
`curl … | bash` stdin is a pipe, so `install.sh` skips the bridge question and
its wizard prompt. Both prompts should read from `/dev/tty` when there is one.

---

## 98. `maestro-remote-mac` is the wrong name — **DONE**

**What.** The package was renamed to `maestro-drive`, as decided in item 94's
5.5: the repository slug, the installed skill directory, the
`~/.local/share/` lib directory, the message prefixes, and the per-project
conf, which becomes `.maestro-drive.conf` with the override
`$MAESTRO_DRIVE_CONF`. The MCP entry `maestro-mac` is item 97's.

**Why.** A rename is not a search and replace. An upgrade that writes the new
directories and leaves the old ones leaves a second copy of the skill with its
own hooks registered in `settings.json` — two gates on every Bash call, and a
`SessionEnd` hook pointing at a directory nothing updates. `GITHUB_SLUG` is
pinned in installed copies of `update.sh` and `lib/update-check.sh`, and every
copy installed before the rename downloads `maestro-remote-mac.tar.gz`; a
missing asset is a 404, so those installs would stop updating. `SKILL.md`'s
`name:` and its directory must change together or the skill stops loading.
There is deliberately no compatibility read of `.maestro-mac.conf`, so an
unrenamed conf leaves a project unconfigured, and a renamed conf matches none
of an old `.gitignore`'s patterns — and the conf carries `APP_PIN`.

**Done.** The conf, override, installer, uninstaller, update path, manifest,
release workflow, skill frontmatter and directory, hooks, wizard, both suites
and docs use `maestro-drive`.

- `manifest.sh` carries `LEGACY_OWNS`, `LEGACY_SKILL_DIRS` and
  `LEGACY_LIB_DIRS`; `install.sh` migrates from and `uninstall.sh` sweeps every
  name the package has had. The jq predicate binds `. as $n` before the pipe;
  `any($names[]; $c | contains(.))` rebinds `.`, is always true, and stripped
  other packages' hooks — the suite covers it.
- `.github/workflows/release.yml` also uploads a byte-for-byte copy of the
  tarball as `maestro-remote-mac.tar.gz` for pre-rename installs. `update.sh`
  extracts with `--strip-components=1`, so the prefix inside the tarball does
  not matter. The second asset can be removed once no pre-rename install
  remains.
- The GitHub repository is renamed, so `GITHUB_SLUG` names a slug that exists
  rather than one kept alive by a redirect.
- `.claude/skills/release/SKILL.md` uses `maestro-drive` in its description,
  title and `git tag -m` template.
- `flutter-hot-reload-mac` reads `.maestro-drive.conf`: its `bin/lib.sh`
  searches upward from `$PWD` then `~/.maestro-drive.conf`, and its `SKILL.md`
  frontmatter names it.
- Existing `.maestro-mac.conf` files were renamed by hand, with each
  `.gitignore` gaining `.maestro-drive.conf` and `.maestro-drive.conf.*` before
  the rename, so the credential was never untracked and unignored.

First released in v2.1.0.

## 99. Two phones at once, and a phone with no cable — **DONE**

**What.** Physical-device support had only been run with one phone on one
cable. Two things were untried. Several phones at once had one defect:
`bin/device.sh` used a fixed port, `port=${3:-$DEVICE_PORT_BASE}` (22187), with
no free-port search. A phone over wifi was unknown: `iproxy.py` speaks to
`/var/run/usbmuxd`, which may not list a network-paired phone.

**Why.** Bringing a second phone up without naming a port found `/status`
already answering on 22187, printed `already up on 22187`, started nothing,
and `_register` wrote the second UDID onto the first phone's port.
`DEV=<second-udid> bin/driver.sh tapon …` then tapped the first phone and
reported success. Over wifi, with no cable, nothing could reach the driver.

**Done.**

- **Two phones over USB.** `_device_port` in `bin/device.sh` walks up from
  22187 past every port another phone holds, in `DEVICE_MAP` and in the live
  forwarders from `platform.sh driver-scan`. A phone keeps its port across
  restarts, and a requested port owned by another phone is refused. Seven
  offline tests. `deviceup.sh` writes one log per phone,
  `~/devdrv-<udid>.log`, because a shared `~/devdrv.log` was truncated by the
  second phone's bring-up while the first phone's `xcodebuild` was writing to
  it. Verified on two phones: each came up on its own port (22187, 22188) and
  drove only its own phone; 30 rounds of parallel tree reads all succeeded at
  0.9–1.5 s; parallel taps landed on both.
- **One phone over wifi.** With the cable out, usbmuxd lists nothing, but
  CoreDevice reaches the phone over `transportType: localNetwork` through a
  point-to-point tunnel (phone at `<prefix>::1`, Mac at `::2` on a `utun`).
  The prebuilt driver listens only on the phone's `127.0.0.1`
  (`XCTestHTTPServer.swift`), and `devicectl` has no port forward.
  `runners/ios-device/driver/bind-address.patch` takes the listen address from
  `TEST_RUNNER_BIND`, falling back to `127.0.0.1`; `driver/build.sh` builds it
  from the `cli-2.8.0` tag (Xcode 27 needs deployment target 15.0) and
  `driver/sign.sh` signs it with the same wildcard profile. Signing must run
  in Terminal on the Mac: over ssh `codesign` fails with
  `errSecInternalComponent`. The driver listens on the tunnel address only, so
  nothing else on the Wi-Fi can drive the phone. `deviceup.sh` asks
  `devicectl` for the transport; over wifi it uses the newest signed build,
  reads the tunnel address after the tunnel wake (read before it, the driver
  fails with `Bind(49): Can't assign requested address`), starts
  `iproxy.py --tunnel <address>` so everything downstream still uses
  127.0.0.1:port, and runs only `testHttpServer`. `device.sh up <udid>` is the
  same command for either transport.

Verified on a physical iPhone over wifi: `/status` 200 in 7 s,
`/viewHierarchy` (91 KB) in 1.0 s, `/touch` in 0.46 s. XCTest sessions over
wifi died within 30–100 s (`The connection was invalidated`, CoreDevice
Mercury error 1001) until `remoted` was restarted on the Mac (item 46); after
that, three consecutive wifi sessions were each alive at 600 s with an
unchanged tunnel address. Defects found along the way are items 101–104.

---

## 101. A forwarder that outlives a reconnect sends to a dead connection — **DONE**

**What.** `iproxy.py` looked up the phone's usbmux device id once, at start. A
phone that reconnects (re-cabled, or reconnected by the OS) gets a new id, and
the forwarder kept sending to the old one. `deviceup.sh` keeps a running
forwarder for that phone and port (`pgrep -f "iproxy.py $UDID $PORT"`), so
item 46's automatic restart replaced the driver and never the forwarder.

**Why.** The on-device driver logged `starting server 127.0.0.1:22187` while
every connection from the Mac got `Connection reset by peer`. Only
`device.sh down` then `up` recovered it.

**Done.** `iproxy.py` keeps the id it found at start and, when a `Connect` to
it fails, lists the devices again; if the phone has a new id it logs
`device id <old> -> <new> (reconnected)` and retries once. A healthy
connection costs nothing extra. Over wifi the forwarder is replaced on every
bring-up anyway (item 99). `USBMUXD_SOCKET` can point the forwarder at another
usbmuxd, as a path or as `host:port`; the tests use a TCP fake that lists the
phone as id 5 and then as 8. Two tests, both failing against the old logic.
Verified on a physical iPhone over USB: with the cable pulled for about five
seconds and replaced, `/status` returned 200 at the next read and the
forwarder logged the new id, with no restart.

---

## 102. The 1/3-scale correction is applied to anything that looks like a marker — **DONE**

**What.** `resolve.py` treated any node whose frame is the screen size divided
by some factor as a coordinate-space marker and rescaled its siblings, and the
factor could be below 1. A native Calendar screen has a 1242×2688 node at
−414,−896 — the phone's size in pixels. `resolve.py` read it as a marker
("marker 1242x2688 at -414,-896 -> scale 0.3333 offset +138,+298.67") and moved
a Continue button from y=781 to y=559.

**Why.** `tapon` returned rc=0 for a tap that hit nothing. The correction
exists for one Flutter bug on iOS, where frames come back at 1/3 scale (item
100); applied to a native app it is a guess.

**Done.** `refute_marker` in `bin/resolve.py` runs before any transform, and a
candidate that fails is not applied; `--explain` prints
`refused marker <size> at <origin>: <why>`.

- A candidate larger than the screen in points (k < 1) is refused. Every
  genuine marker is the screen divided by 3, or the screen itself with an
  offset.
- Under a scaling marker (k > 1), every sibling must lie inside the marker's
  frame; one outside is already in screen points.
- The existing off-screen and under-the-keyboard refusals still apply. A check
  that the result lands inside a visible node was not built.

Pixel sizes are not passed to `resolve.py`; comparing against the screen in
points is enough. Fixtures `test/fixtures/marker-calendar-pixel-node.json`,
`marker-flutter-third-scale.json` and `marker-home-paged-scroll.json`, rebuilt
from recorded frames (noted in each `_note`). Six tests: Calendar's Continue
resolves to (207, 781), and the Flutter 1/3 space, the overlay offset and the
home screen's paged scroll view still resolve through their markers.

---

## 103. An install failure is reported as the XCTest session dying — **DONE**

**What.** When Xcode failed to install the driver on a phone (`Installing
built products … Finished with error: Connection with the remote side was
unexpectedly closed`, `IXRemoteErrorDomain` code 6, `CoreDeviceError` 3002, or
`CoreDeviceError` 4000 "The device disconnected immediately after
connecting"), `deviceup.sh` printed item 46's message about the on-device
XCTest session dying and advised a retry.

**Why.** Retrying does nothing for an install failure; restarting the phone
clears it. The message sent the reader to the wrong layer. 3002 can also come
from a second process using the phone's tunnel (item 46's `lockState`
keep-alive).

**Done.** `_why` in `runners/ios-device/deviceup.sh` reads the driver's log on
both failure paths — a failed start and no answer within 120 s — and prints
one of four explanations, in this order:

- an install failure (`Installing built products … Finished with error`, or
  `Failed to install the app`), naming the `CoreDeviceError` and IXRemote
  codes it finds and that restarting the phone cleared it;
- a tunnel address gone before the driver listened (`Bind(49)`), which a retry
  fixes because the address is read again (item 99);
- the face-up crash on the prebuilt driver (item 50);
- otherwise item 46's session death, with measured lifetimes (60–104 s on a
  cable, 30–100 s over wifi).

Five tests feed it the log lines each failure writes. Not tried live.

---

## 104. `driver.sh app` always answers springboard on a phone — **DONE**

**What.** `driver.sh app` returned `com.apple.springboard` with Settings or
Calendar in front. Maestro's `runningApp` route takes a list of bundle ids and
returns whichever of them is in front, or `com.apple.springboard` when none
is; `driver.sh` passed only the configured `APP_ID`. This happens on any
device, not only phones. `reference/driver-api.md` described the route as
returning the foreground bundle id.

**Why.** The verb could not confirm which app was in front, and could not tell
two phones apart.

**Done.** `driver.sh app` prints two lines: `in front: <name>`, from the
screen tree's application node, and whether the configured app is in front,
from `runningApp`. The name is the display name (Settings), because the tree
carries no bundle id. `reference/driver-api.md` is corrected. Two offline
tests with a stubbed tree and route answer; not run on a phone.

---

## 105. `settle` waits its full timeout on a screen that never reports static — **DONE**

**What.** On a physical iPhone, the driver's `/isScreenStatic` answers `false`
on still screens: 19 of 20 reads on a still Settings screen, 17 of 20 on the
home screen. Every action verb that settles afterwards waited the full 20 s
and printed `settle: screen still moving after 20s`, while `/status` was 200.

**Why.** Three `driver.sh tap` calls took about 60 s. The message was also
what a crashed driver printed first, so a moving screen and a dead driver
(item 50) were indistinguishable.

**Done.** `_settle` in `bin/driver.sh`:

- stops after three empty answers from `/isScreenStatic` in a row and prints
  "the driver stopped answering after the last action — not a moving screen",
  in about 1 s;
- on a real timeout, asks `/status` and prints either "the driver is up, so
  the screen itself keeps changing" with `SETTLE=0` as the way past it, or
  "the driver is not answering now";
- after 2 s of "moving", also reads the screen tree, and two identical parsed
  trees in a row count as settled — unless the tree holds an activity or
  progress indicator (element types 36 and 35), because a spinner can turn
  without changing the tree. Parsed trees are compared, because the raw JSON
  differs between reads of an unchanged screen.

On the same measurements the parsed tree matched the previous read 18 of 19
times on Settings and 19 of 19 on the home screen. Verified on a physical
iPhone: `settle` on Settings returned 0 in 7–9 s, three of three. Six offline
tests. Not covered: a Flutter spinner that does not expose itself as an
activity or progress indicator is taken as settled.

---

## 106. The test suites fail in a shell that has sourced a project conf, and two tests are flaky — **DONE**

**What.** Two causes of failures that disappeared on a rerun.

- Sourcing `bin/lib.sh` loads a project's conf (`DEV`, `APP_ID`, `MAC_HOST`,
  `LDIR`, `RDIR`, `SCREEN_W` and the rest) into the shell. The conf sets values
  as `: "${APP_ID:=…}"`, so a value already in the environment wins, and tests
  that rely on their own defaults got the project's. Nine skill-suite tests
  failed this way (the `notes.sh` cases, the local-conf cases, the upward conf
  search and the detached-cwd fallback), and one packaging test that runs the
  skill suite from the installed path.
- Assertions written as `printf '%s' "$d" | grep -q …` under `pipefail`. Bash's
  `printf` writes one line per `write(2)`. `grep -q` exits at its first match,
  so if it runs between two of the writer's writes, the next write dies of
  SIGPIPE and `pipefail` fails the pipeline on text that matched. This hit
  `same subnet with no ARP reply is named as the access point, not the Mac`
  and `watch: an emptied list is a change, not silence`, each about one run in
  five on a loaded machine and never on an idle one.

**Why.** A suite that is red only in some shells, or only some of the time,
reads as a regression in the change under test.

**Done.** Both `run-tests.sh` files re-run themselves once under `env -i`,
keeping only `PATH`, `HOME` (redirected straight after, the real one kept for
the login-shell cases), `TMPDIR`, `TERM` and the locale. 122 assertions now use
a here-string (`grep -q … <<< "$d"`), and the 26 that pipe a command use
`drain_grep`, which greps and then reads the rest of its input so the writer is
never cut off. A test makes the race certain — a writer that pauses between a
matching first line and a second — and checks that plain `grep -q` fails it
and `drain_grep` does not. Verified with ten consecutive runs of both suites
(skill 598 passed, packaging 158 passed, 0 failed each time), and with a
project conf sourced.

---

## 108. Android `boot` gave up on a second emulator that was still coming up — **DONE**

**What.** `runners/android/platform.sh boot` had two wait loops of 180 polls
each, and both were wrong.

- The first counted a new serial only once it read `device`. Booting
  `Small_Phone` straight after `Pixel_6_Pro_API_34` (8 cores, 31 GB) left
  `emulator-5556` at `offline` past 180 s, its log ending at
  `Loading snapshot 'default_boot'...`. `boot` exited 1 with "no new device
  appeared within 180s", and the emulator booted shortly afterwards.
- The second polled `sys.boot_completed`, and when it ran out it printed the
  serial and exited 0 whether or not boot had finished.

**Why.** A slow boot was reported as a failure with no serial while the
emulator kept running. An unfinished boot was reported as a success.

**Done.**
- One deadline now covers the whole boot: `BOOT_TMO`, default 420 s.
- A new serial counts in any state, and the baseline is every serial in any
  state.
- `adb wait-for-device` is gone. It had no timeout of its own, and the
  `sys.boot_completed` poll covers it.
- Running out exits 1. The message names the serial if one appeared, and
  otherwise the emulator's process ID and `kill <pid>`.
- `drivers.sh rig up` passes `BOOT_TMO` through and gives its transport 30 s
  more than it.

Measured on this machine:
- Three emulators booted back to back took 79 s, 167 s and 226 s, all exit 0,
  with load 18 at the end. The third would have failed under the old 180 s.
- `BOOT_TMO=20` on a fourth failed after 21 s with nothing on stdout. That
  emulator went on to take `emulator-5560`, which is why the message now gives
  its process ID.

Two offline tests: a serial that is `offline` before it boots is waited out,
and a boot that never completes fails naming the serial.

---
