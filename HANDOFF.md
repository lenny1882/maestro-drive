# Where this stands — 12–13 Aug 2026

## The live thing

**Develop in `src/`. Ship with `./ship.sh`. Never edit `build/`.**

**Never run `./ship.sh --yes` unless the user asks for it in that message.**
Bare `./ship.sh` only reports what would change — run it freely, say the work is
ready, and stop there. Publishing is his decision every single time, and
approval for one change does not carry to the next. This was got wrong twice:
once on 11 Aug, and again on 12 Aug when the credentials mechanism was published
on the assistant's own initiative, so that when he asked for it shipped there
was nothing left to ship.

`build/maestro-remote-mac/` is the *published* copy — symlinked from
`~/.claude/skills/maestro-remote-mac`, so whatever is in it is what every other
Claude session loads, immediately. `src/` is the development tree. `./ship.sh`
shows what would change and publishes only with `--yes`, refusing anything that
does not parse.

This was the arrangement asked for on 11 Aug and it inverted almost at once:
the working copy fell behind, the build became the only current one, and this
file was then written to say "edit the build" — after which a whole session's
changes went live with no review. What was left of that first working copy has
since been checked and removed: `bin-STALE-pre-skill/`, `flows-STALE-pre-skill/`
and `journeys-STALE-pre-skill/` were deleted on 12 Aug, after confirming file by
file that no check, subcommand, function or measurement existed only in them.
`remote-STALE-pre-skill/` is still here — it holds no project data, so there was
no reason to remove it — and `RULES-STALE-pre-skill.md` is the pre-skill rules
document, banner-marked and superseded by `src/reference/`.

`~/.claude/skills` is read-only from inside the sandbox — the symlink had to be
created by the user. Ask; do not try to write there.

## What a reader coming to this cold would get wrong

Carried in from `~/claude-sandbox/HANDOFF-2026-08-STALE.md` on 20 August 2026, which is where
this list was written and where it no longer belongs. Develop-in-`src` is above;
that `bin/img.sh` needs no PIL is at `## Done 12 Aug`.

- **The development checkout's filesystem is not read-only.** Those paths — on
  this machine, under `/mnt/sda` — are writable and owned by the user. The
  sandbox allows writes only to the working directory and `$TMPDIR`, so a write
  outside them is refused and the refusal surfaces as `EROFS`, which reads as
  "Read-only file system". Never suggest a remount. The way in is the user
  running the copy themselves. Also in the machine's own reference file.
- **`RULES-STALE-pre-skill.md` reads like current guidance and is wrong in two
  places** — it offers "the device pixel ratio applied twice" for the 1/3 scale
  when the ×3 is in fact missing, and says `bin/driver.sh` only works while an
  MCP session holds a driver open, which stopped being true on 12 Aug. The
  banner says so; the 1413 lines below it do not.
- **The `maestro-mac` MCP server cannot address a specific device.** Maestro's
  client compiles the driver port in as a literal 22087, so the server answers
  about whatever device is on that port whichever `device_id` it is given.
  Worse, naming a device to the Maestro CLI destroys that device's driver. Use
  `bin/drivers.sh up` and `DEV=<udid>`.
- **The MCP tools do not just read the wrong device — they destroy the driver
  layout.** On 13 Aug one `mcp__maestro-mac__run` call killed the iPad's driver
  and the next four `driver.sh` calls failed with `no driver for <udid>`, which
  reads as a dead relay rather than as something the previous call did. It cost
  ten minutes, most of them spent suspecting the app. Item 15, now done:
  `drivers.sh` records which driver it started, so a driver that has vanished is
  reported as taken rather than as never having existed.
- **`driver.sh` does not use SSH.** It talks to the relay over HTTP using
  `MAC_FQDN`, which the sandbox proxy resolves and which therefore follows the
  Mac between networks. Only `mac.sh`, `preflight.sh`, `drivers.sh` and the
  build helpers use `MAC_HOST`. That is why a wrong SSH alias presents as some
  things working and others not, and it is why a `driver.sh` call is no proof
  that the alias fallback works.
- **The seven-file journey chain named in the old notes does not exist** —
  `reset`, `01-store`, `pin`, `02-setup`, `03-search`, `03-search-again`,
  `04-add`. No files by those names are anywhere on disk and no session
  transcript mentions them. The 48-second measurement attributed to them is
  real; the files are not. The project's eight `.journey` files are the current
  set, and the journey names in `reference/` are the worked example against the
  fictional app, which is deliberate.
- **`staging/` no longer exists.** It was used twice to hand files to the user
  for copying into the brandco checkout, and deleted each time once the copy
  was verified — the second time because it held a copy of the PIN.
- **The iPad is usable, and the note that said otherwise was wrong.** Its
  navigation rail carries no frames in the accessibility hierarchy, so no
  selector can reach it — but it taps fine by coordinate, and the numbers are
  measured and verified in the project's `app-notes.md`. The device must be in
  `landscapeLeft` or `landscapeRight` for them; in `portrait` the safe-area
  inset moves and the top item is missed. This is item 26.

## What it does

Drives an iOS simulator app through the XCUITest driver's own HTTP API, relayed
onto the LAN, with element resolution that corrects wrong reported bounds.
Settings come from a per-project `.maestro-mac.conf`; journeys and app notes
live in the project's `maestro/`.

Numbers that matter, all measured rather than estimated:

- Full request journey, signed out to a populated basket: **34 steps, ~48 s, one
  call.** Six runs inside a 2.4 s spread. By hand the day before: 15.4 minutes.
- The same 34 actions as 42 separate processes: 55.3 s. So batching saves 7.5 s
  of process startup; the other fourteen and a half minutes was the model
  deciding between steps. **That is why journeys exist.**
- Hierarchy read 0.28 s, tap 0.46 s, screenshot 0.27 s, against 7.7 s for
  `maestro hierarchy` over SSH.

## Done on 11 Aug, after the first handoff

- **`reference/setup.md`** — installing on a new machine: Mac prerequisites, the
  SSH key, `~/.ssh/config` with the `socat` `ProxyCommand` explained line by
  line, `/etc/hosts`, the sandbox `allowedDomains`, project permissions, the MCP
  registration, the symlink, then `init.sh`. Ends with an ordered verification
  and a symptom-to-cause table.
- **A wrong claim corrected.** SSH *does* go through the sandbox proxy — each
  alias carries a `ProxyCommand` that tunnels through `localhost:3128` with
  `socat`. What fails about `<mac>.local` is that it matches no `Host` block, so
  it gets no `ProxyCommand`. Fixed in `connection.md`, `config.sh` and the
  comment `init.sh` writes into every generated conf.
- **`SKILL.md` step 5** — nothing here builds, installs or launches the app. If
  no `flutter run` is active there is no VM service, so `net.sh` and
  `publish.sh` come back empty; say so and **ask** before starting one.
- **`preflight.sh` bug fixed.** `pgrep ... | head -2 || echo none` never printed
  `none`, because the pipeline's status comes from `head`. Both branches now
  verified against the Mac.
- **The whole skill is now agnostic, `reference/apps/` included** (12 Aug). No hostname, IP, Mac
  username, key name or absolute path; no app labels, test PINs, store numbers
  or client name; no claims phrased as being about one app. Placeholders are
  `<alias>`, `<mac>.local`, `<mac-ip>`, `<mac-user>`, `<key>`, `<java-home>`,
  `<bundle-id>`, `<checkout>`, defined in a table at the top of `setup.md`.
- **Five scripts pointed at `RULES.md §N`**, which does not exist inside the
  skill. Now they point at the `reference/` files.
- The code was already app-agnostic — screen size comes from `/deviceInfo` at
  runtime, the marker rule is derived from the tree, keyboard detection uses iOS
  class names. Only comments and examples were app-specific.

## The 1/3 scale — where it stands

Source read of the app on the Mac, 11 Aug: no scaling package, no `MediaQuery(`
override, no `devicePixelRatio` reference, no `Transform`, the only `FittedBox`
is off-route, `buildTheme(1.0)` only scales font sizes, transitions are
`fadeIn`, and the dropdown is a stock Material `DropdownMenu`.

The direction of the error is the opposite of the old guess. Flutter's root view
transform is `Matrix4.diagonal3Values(dpr, dpr, 1)`
(`rendering/view.dart`), and iOS divides by the same ratio on the way out.
Frames at 1/3 mean that multiply is **missing** on the subtree, not applied
twice. Recorded in the project's own `maestro/app-notes.md` (it was in the
skill's `reference/apps/brandco-runner.md` until 12 Aug).

**Both checks are done, 11 Aug 2026.**

1. **Maestro is a faithful pass-through.** `driver.sh tree` and `inspect_screen`
   were read against the same screen in three states — normal, the overlay's
   offset space, and the 1/3 state. They agreed element for element. The wrong
   frames are already in the accessibility tree the driver reads, so there is no
   Maestro conversion bug to file.
2. **A stock `DropdownMenu` does not reproduce it.** A bare app on the same
   pinned SDK and simulator reported correct absolute frames closed, open, after
   selecting and with the keyboard up. Not filable as a Flutter bug; the cause is
   in the app or its dependencies. The `dimensions` package was read and only
   reads `MediaQuery`.

**What the checks turned up instead:** on the PIN entry screen the 1/3 is
controlled by whether the dropdown overlay is open. Open, everything reads at
true absolute; closed, the whole screen reads at 1/3.

**Then it was found.** Growing the bare probe towards the real app one step at
a time, with a **cold launch per variant**, the cause is `MaterialApp.router`.
An app built with it reports its whole accessibility tree at 1/dpr once a
`DropdownMenu` has been opened and closed. The same app built with
`MaterialApp(home:)` stays correct. It needs no third-party packages at all —
not auto_route, not `provider`, not `easy_localization` — and not the
declarative `Navigator(pages:)` API either. 60 lines reproduce it.

`flutter-router-dropdown-repro/` holds the reproduction, the measured frames
and the bisection table, plus `UPSTREAM.md` (what is already on the tracker)
and `DRAFT-ISSUE.md` (a report written for it).

The root cause is known upstream — flutter/flutter#100946, open at P2 since
2022, with an unmerged fix in flutter/flutter#189686 whose description carries
these exact numbers. What is new here is the trigger: every existing report
needs a `ReorderableListView` and a drag; this needs only `MaterialApp.router`
and a dropdown, and it affects the whole tree. **Nothing has been posted to any
tracker, and posting needs the user's approval of the exact text.**

**One trap worth remembering.** Hot restart is not a clean slate for this —
it carries the flipped state over, and a Dart compile error makes `kill -USR2`
fail silently so the old code keeps running and every later reading is stale.
Cold-launch each variant and confirm `Flutter run key commands` in the log
before trusting a reading.

**Building on that Mac needs three things in the environment**, none of which a
non-interactive SSH shell has: `/Users/<user>/.fvm/versions/<ver>/bin/flutter`
(there is no `flutter` on `PATH`), `GEM_HOME=$HOME/.gem`, and `$GEM_HOME/bin`
on `PATH` for CocoaPods. Without the last two the build fails with "CocoaPods
not installed or not in valid state".

## Done 12 Aug — several simulators at once

`bin/drivers.sh` starts one XCUITest driver per booted simulator, each on its
own port, and `DEV=<udid>` now selects the device for every `driver.sh`
command. This removes the worst time sink the session review found.

The mechanism: Maestro's client side compiles the driver port in as a literal
22087 (`MaestroSessionManager`, `McpMaestroSessionManager`) with no override,
which is why the MCP server returns **whatever device is on 22087** whichever
`device_id` you give it. The driver has no such limit — `XCTestHTTPServer.swift`
reads `PORT`, and `xcodebuild test-without-building` injects it as
`TEST_RUNNER_PORT`. So `drivers.sh` launches Maestro's own build products with
the port chosen.

Verified on the Mac, not assumed: two devices driven at once with a `launchApp`
on one leaving the other untouched; one simulator holds only one driver, so
starting a second replaces the first; the device-to-port map is readable from
the runner processes, so nothing is tracked in a state file. ~30 s cold per
device, ~12 s warm. Full detail in `reference/driver-api.md`.

Files: `remote/driverup.sh` and `bin/drivers.sh` are new; `bin/lib.sh`,
`bin/config.sh` and `bin/driver.sh` changed; `SKILL.md` step 4 rewritten;
`preflight.sh`, `hier.sh`, `flow.sh` and `shot.sh` headers corrected.

## Done 12 Aug — network capture actually captures

`publish.sh` now turns dart:io HTTP profiling on (it is off by default, which
made `bin/net.sh` come back empty in a way that reads as "the app made no
calls"), and prints a labelled block with the base URI, isolate, profiling
state and the path to `published.state`. `net.sh` explains an empty list rather
than printing nothing.

While verifying it, a second cause turned up: `remote/vmservice.sh` accepted
dead isolates, because a collected one returns `{"type":"Sentinel"}` and its
check only looked for `"type"`. After any hot restart it handed back an isolate
that no longer existed. Both faults fire together on a restart, which is why
this looked intermittent.

Verified against a throwaway Flutter app on the iPad, since the alternative was
rebuilding the app under test. Probe removed afterwards and the app relaunched.

## Done 12 Aug — the app notes moved out to the project

The skill no longer carries anything about one app. `reference/apps/brandco-runner.md`
and the two flow YAMLs held the only real values left in it — bundle id, store
numbers, a login PIN, product barcodes, a Mac username — and they have gone to
the checkout they describe:

| was, in the skill | is now, in `brandco-flutter-runner/maestro/` |
| --- | --- |
| `reference/apps/brandco-runner.md` | merged into `app-notes.md`, which the project already had |
| — | `app-notes-2026-08-11-original.md`, the pre-merge original, kept for provenance |
| `reference/apps/setup.yaml` | `flows/setup.yaml` |
| `reference/apps/search-product.yaml` | `flows/search-product.yaml` |

The merge was not a concatenation. The project's file was newer on three points
and won each time: the submit failure has a known cause there (`type:""`), the
journey files the skill's copy named no longer exist, and the skill's copy
contradicted itself on the 1/3 scale — "cause unidentified", then
"`MaterialApp.router`", then "the pixel ratio applied twice". The merged text
keeps `MaterialApp.router` and the ×3 being **missing**, and says what it
replaced. The original is kept beside it in case a resolution turns out wrong.

Two claims already in the project's notes were corrected in place, dated, because
the drivers work made them wrong: that switching simulator means killing the
driver and reconnecting MCP, and that `bin/driver.sh` only works while an MCP
session holds a driver open. Neither has been true since 12 Aug.

In place of the removed example the skill has `reference/apps/example-app.md` —
the same measurements against the fictional retail app that
`reference/journeys.md` already used, so the two read together. `SKILL.md` and
`reference/driving.md` cite it.

## Done 12 Aug — a credential has somewhere to live

The conf is the one file a project keeps out of version control; the journeys,
the flows and the app notes are all committed. So anything named `APP_*` in
`.maestro-mac.conf` is now exported, which means a journey can say `${APP_PIN}`
and the value exists in exactly one gitignored place. Substitution happens in a
child `python3` reading `os.environ`, so a plain shell variable set by the conf
never reached it — that is why the PIN used to be typed on the command line.

`APP_ID` and `APP_NOTES` are reserved: ordinary settings, safe to commit, not
treated as secrets. They predate the convention and renaming them would break
every conf already written.

| file | what it does now |
| --- | --- |
| `bin/config.sh` | exports `APP_*`, and provides `_app_vars` to the other two |
| `bin/flow.sh` | passes them to Maestro as `-e`; an explicit `-e` still wins |
| `bin/notes.sh add` | refuses text containing a value, names the variable, writes nothing |
| `bin/init.sh` | every new conf gets the commented block explaining it |
| `bin/secrets.sh` | new — `check` and `list` |

`secrets.sh check` searches everything `git add -A` would take
(`ls-files --cached --others --exclude-standard`), not just tracked files: a
brand new file holding the value is the most likely way one gets committed, and
`maestro/app-notes.md` was exactly that until 12 Aug. Matching is whole-word,
because a five-digit PIN is a substring of half the hashes in a lock file —
that false positive appeared on the first real run, against `pubspec.lock`. The
cost is that `PIN12345`, with no separator, is not reported.

Applied to brandco-flutter-runner the same day: `APP_PIN` in its conf, and the
literal gone from `00-login.journey`, `flows/setup.yaml`, `app-notes.md`,
`HANDOFF-PROJ-1789.md` and the preserved original — 8 places before, 0 after.
The preserved original's banner used to claim nothing below it had been edited;
it now says the PIN was replaced and nothing else was.

**Scope is credentials only, on the user's decision.** Store numbers, barcodes,
user names, locations and request IDs stay in the project's committed files.
The mechanism takes any number of values, so widening it later is a conf edit.

## Done 13 Aug — five backlog items, shipped in one go

The morning fixed the iPad coordinate spaces (item 8) and the SSH alias list
(18). The afternoon did four more and published all of it at about 14:56. Ninety-three
tests pass from the live path. Read the entries in `BACKLOG.md` for the detail;
what follows is what a cold reader would otherwise get wrong.

**Screenshots (11).** `driver.sh shot` now delivers the picture upright and
croppable in app-space points — the same numbers `driver.sh point` gives — with
`--on <pattern>` to cut it to one element, `--crop x,y,w,h`, `--scale`, and
`--raw` to opt out. `bin/img.sh` does the pixels using ImageMagick, or local
`sips`, or `sips` on the Mac; `IMG_BACKEND` pins the choice so the Mac path can
be tested from a machine that has ImageMagick. **The backlog said ImageMagick
was absent from this machine. It is not** — 6.9.10 at `/usr/bin/convert`,
0.15 s for a crop of a six-megapixel image. Only PIL is missing. A pure-Python
PNG crop was considered and dropped: unfiltering a 3-megapixel scanline at a
time in Python is tens of seconds.

The rotation is 270° clockwise when the status bar sits down the right edge and
90° when it sits down the left, both measured by rotating the simulator each way
and looking at the result. That reading is `resolve.py --space`, the same
status-bar test that separates system space from app space, so there is one
detection and not two that could drift apart. The hierarchy is only fetched when
the picture disagrees with the screen, so an upright iPhone shot costs nothing
extra: 0.6 s against 1.2 s for the iPad.

**Is the app the code under test (6).** `preflight.sh` gained a block comparing
the installed build's timestamp with the newest commit in the Mac's checkout.
`remote/appcheck.sh` is a file rather than more lines inside the SSH string so
it can be run off a Mac and tested; it is sent base64-encoded as part of the
command, so preflight is still one round trip. `BUILD_MARKER` in the conf greps
the bundle for a string only the build under test contains — deliberately not
named `APP_*`, because those are exported as project values and `secrets.sh`
hunts for them as credentials.

Be careful with the wording it prints, which is deliberate: a build **older**
than the newest commit cannot contain it and is called STALE; a build **newer**
is not proof it came from that branch, because a checkout can move after a
build. Two bugs the tests caught before this went anywhere, both silent:
`stat -f` exists on GNU as well as BSD and means *file system status* there, so
it succeeds and prints a block count that was about to be compared against a
commit date; and reading a plist value from the line after its key returns the
*next* key's value when both sit on one line.

**Journey lines, and a leak (14, part 1).** Journey lines are now split into
words first and `${VAR}` expanded inside each word afterwards (`bin/jtok.py`).
The other order is why `text ${USER}` with `USER="Test User"` typed only
`Test`. Splitting first means a variable is one argument however many spaces it
holds, can sit inside a quoted pattern, and a `#` in a value is not a comment.
`text` and `type` also take the rest of the line now, in journeys and from the
command line, where `type` had been silently ignoring everything after its third
argument. A consequence worth knowing: **the step log echoes the line as
written, and it used to echo the expanded one — `${APP_PIN}` was printed in full
on every step that used it.** It now prints as `${APP_PIN}`.

**The dropdown, diagnosed (14, part 2) — and it is the app's.** Reproduced on a
clean install of the iPhone 16 (uninstall, reinstall from a copy of the bundle,
first-run permission dialog, login journey). **The backlog's explanation was
wrong: the text does reach the field.** On the same screen, same build, same
session, typing `Test User` into the user field filters the list to one row,
and typing `LOC1` into the location field beside it — the same widget — filters
nothing at all, seven entries in and seven still showing. With the list
unfiltered, `key return` takes the first entry, which is `4001`. That is the
whole reported failure and nothing this toolkit does can change it.

Three notes that were being relied on are also wrong, all measured that day:
`key return` dismisses the keyboard, commits nothing and leaves the list open;
tapping the row commits every time; and rows past the menu's viewport report
`0,0 0x0` and **stay** that way after the keyboard is dismissed, so they need a
swipe — the keyboard was never what hid them. A dropdown left open also survived
four further `driver.sh` invocations including two `tree` reads, which the notes
said was impossible.

What shipped is `type` reading back what landed (`bin/typed.py`), failing if the
text is not on screen, with one exemption: a secure field never shows its
contents, so a PIN step is not failed on evidence that cannot exist.
`TYPE_VERIFY=0` turns it off. **It would not have caught the dropdown failure** —
`LOC1` was in the field — and the documentation says so rather than implying a
guarantee. What catches that is an `expect` on the committed value, which
`reference/journeys.md` now tells authors to put after any step that commits.

**Notes now say how well they are known (16).** `bin/notes.sh add` requires
`--measured`, `--once` or `--inferred` and refuses to write without one. There
is no default on purpose: a default would make every note claim the same
confidence, which is the state being fixed. An unmarked note predates the
convention and reads as `seen once`, which puts all five of the known-wrong ones
in the weakest class without anyone editing them. Correcting is specified rather
than implied — mark the original wrong, add the correction with its measurement,
leave the wrong version visible.

Two of those five wrong notes were in `reference/apps/example-app.md`, which
ships inside the skill as the example a new project copies from, and they taught
filter-then-return as a verified method. Corrected in place. **`SKILL.md` never
taught it** — the item claimed it did, and that was wrong; the example notes did,
which is worse, because that is what gets copied.

The other half of 16 was left out deliberately and is now **item 19**: two of the
five were contradicted by another note in the same file on the same day and
nobody cross-read them. Catching that means reading a notes file and reporting
pairs that disagree, which is hard to do without crying wolf — and a checker that
cries wolf gets switched off and takes the confidence marker with it. Item 19
says not to start it until 16 has been used for a while.

## Done 13 Aug, after the ship — item 7, and its premise was half wrong

Shipped 16:47, with items 5, 7, 9, 10, 12 and 15 together.

The item said exploration cost two round trips per step and that the sleeps on
top of them were redundant, because `tapon`, `tap`, `type` and `swipe` all
already waited for the screen. **That was true of the journey verbs and false of
the command-line ones**, where only `tapon` and `type` waited. Counting what
each of the 190 sleeps across the four sessions actually followed: 112 came
after a verb that had already waited, 42 after one that had not, and 36 were
nothing to do with `driver.sh`. So the one-line rule the item asked for would
have been wrong as written, and the gap had to be closed first.

Three changes, and the order matters if you are re-reading this:

1. The command-line action verbs now settle — `tap`, `text`, `key`, `button`,
   `erase`, `swipe`, `launch`, `orient`. A settle timeout warns on stderr and
   leaves the exit status alone, because the action did happen and the caller is
   testing the action. Journeys keep the stricter rule where a timeout fails the
   step. `SETTLE=0` used to mean *fail immediately* — the loop ran zero times
   and fell through to the error — and now means *do not wait*, which is the
   escape hatch for a screen that never stops moving.
2. `--tree` / `--nodes` on every action verb, **directly after the verb**. Not
   at the end: `type` takes the rest of the line as the text to type, so a flag
   there is typed rather than obeyed, and the tests hold that both ways round.
   The screen prints even when the action failed, which is when it is most worth
   seeing.
3. `SKILL.md` rule 5 was *"`settle`, not `sleep`"*, which a model can satisfy
   while still sleeping after every `tapon`. It now names every verb and says
   never add one. Same in `reference/driving.md`, `reference/driver-api.md` and
   `reference/journeys.md`.

Three things a cold reader would otherwise get wrong:

- **`--tree` is not a speed feature.** Measured live: 2.29 s combined against
  2.61 s as two calls. The 0.3 s is process startup and beside the point. What
  it removes is the model stopping to decide between an action and the read that
  says what the action did — the same argument as journeys.
- **The inline tree printer moved to `bin/tree.py`.** Verified byte-identical
  against all three fixtures in both modes before the old copy was deleted, so a
  difference in tree output now is a real regression, not the move.
- **`driver.sh` is under test for the first time.** It binds to a driver on the
  Mac at load, so nothing in the suite had ever run it. The test now builds it a
  fake device: a stub `curl` that is always up, always still and always serves a
  fixture, plus a stub `lib.sh`. That is what makes the flag parsing and the
  settle rule checkable offline, and it is reusable for anything else in
  `driver.sh` that needs testing. 93 cases became 105.

Live check on the iPhone 16, using `erase 0` because it deletes nothing:
`driver.sh erase --tree 0` returned the screen in 2.3 s. The app had logged
itself out in the meantime — "Logged out due to inactivity", both dropdowns
empty again — so the state described further down under *The Mac* no longer
holds.

## Done 13 Aug, after the ship — item 9, the refusal shows its working

Shipped 16:47, with items 5, 7, 9, 10, 12 and 15 together.

Session A's failure was not a wrong refusal. It was a correct one that read like
a guess: the model overrode it, tapped anyway and typed a stray `f` into a store
field, because on the screenshot the dropdown looked as though it sat above the
keyboard. So the message now carries the arithmetic — which edge, how far past
it, and where the edge came from.

The awkward part, and the thing to understand before touching this again:
naming the covering containers means printing their frames, and their
**positions** arrive in the device's own space. That is exactly what made the
guard wrong in both directions until 12 Aug — position-based, it refused every
element on the iPad and nothing at all on the iPhone. A message quoting a
position beside an app-space edge would invite the same mistake it exists to
prevent. So it prints the sizes, and says in the message why only the size is
usable.

`keyboard_band` was split into `keyboard_geometry`, returning the edge, the
thickness and the containers behind them; `keyboard_band` stays as a wrapper so
its existing test and contract are untouched.

The off-screen refusal got the same treatment — which way and how far past the
edge, rather than "scroll it into view" — plus the warning that a node reported
`0,0 0x0` is off a scrolling container's viewport and that dismissing the
keyboard does not bring it back.

**What the message must never say again.** The item originally asked for the
refusal to point at filter-then-return. It must not: item 14 measured that the
list does not always filter and that `key return` can commit the first row
rather than the one typed. The advice is now tap it, then `expect` what it did.
One of the nine new tests fails if the words "filter" or "press return" ever
appear in that message again.

Verified live on the iPhone 16, on session A's own situation: a dropdown row
whose centre sits 14.7 points below the keyboard edge — marginal enough that a
screenshot would make it look clear, which is the whole point. 105 tests became
114.

## Done 13 Aug, after the ship — item 15, a driver that was taken

Shipped 16:47, with items 5, 7, 9, 10, 12 and 15 together.

Running Maestro against a device — the MCP server, `hier.sh`, `flow.sh`,
`shot.sh` — destroys that device's driver. The failure then lands one call
later, on whatever tries to use the device next, and `no driver for <udid>`
reads as though there had never been one. That is what cost about ten minutes
on 12 Aug, most of it spent suspecting the app.

**Re-measured 13 Aug with three drivers up**, because the item's wording implied
port 22087 changes hands and that is not what happens. iPad 22087, iPhone 16 Pro
22088, iPhone 16 22089; `maestro --device <iPhone 16 Pro> hierarchy` left the
iPhone 16 Pro with no driver, and the other two kept their ports. The run after
it, which succeeded, did the same. So it is the **named device** that loses its
driver, it happens on the way out whether the command worked or not, and nothing
else is affected.

`reference/driver-api.md` and `SKILL.md` already had this right from 12 Aug. The
headers of `hier.sh`, `flow.sh` and `shot.sh` did not — "starts a driver on
22087 for that device, replacing whatever was there" — and nor did the backlog
item. All four are corrected.

`drivers.sh up` now records what it started in `$LDIR/drivers.owned`; `down` and
`down-all` clear it. `driver.sh` uses it to tell "taken" from "never there", and
`drivers.sh list` shows `was 22088 / GONE`.

Two things to keep straight if you touch this:

- **The registry is not a port map.** The live scan of the Mac's processes stays
  the source of truth for which driver is on which port, and needs no state file
  because the runner's command line carries the UDID. `drivers.owned` answers
  only "did we put one there", which the scan cannot.
- **A device nobody started gets the old plain message.** There is nothing to
  explain, and inventing a cause would be worse than saying less.

Verified live: the failure was reproduced on the real Mac, the note was watched
appearing, and the driver was brought back with `drivers.sh up` — the layout is
back to three. 114 tests became 126.

## Done 13 Aug, after the ship — item 5, building on the Mac

Shipped 16:47, with items 5, 7, 9, 10, 12 and 15 together.

`bin/build.sh` (local) and `remote/build.sh` (on the Mac), one round trip.
Session B spent 4.5 minutes working out three things and then wrote them to a
project memory file, where the next app on the same Mac cannot see them. All
three are now worked out from the repo instead:

- **The SDK**, pinned first — `$REPO/.fvm/flutter/bin/flutter` before anything
  on `PATH`. That order is deliberate: the pinned SDK is the version the project
  expects, so a different one on `PATH` is a worse answer, not a fallback.
- **CocoaPods**, only when `pod` is genuinely missing from the PATH the build
  will have. Setting `GEM_HOME` when it is not needed breaks a working install
  just as easily as not setting it when it is.
- **The flavour, from the bundle id.** Xcode names each build configuration
  `Debug-<flavour>` and each carries its own `PRODUCT_BUNDLE_IDENTIFIER`, so
  `APP_ID` traces back to the flavour that produces it. On the real project that
  picked `dev` out of six candidates from the project file, not from the name
  happening to match.

Two rules in there are worth keeping if this is ever rewritten:

- **A flavour counts only if both halves exist** — an Xcode scheme of that name
  *and* a `lib/main_<flavour>.dart`. That single rule discards the template
  entrypoint `main_env.tpl.dart`, the analytics extension's own scheme, and
  either half on its own, without the script knowing about any of them by name.
- **If the bundle id is not decisive it refuses and lists.** Building the wrong
  flavour installs a different bundle id and leaves the app under test exactly
  as it was, and nothing anywhere reports that. `BUILD_FLAVOR` in the conf is
  the override.

`--detect` reads and reports without building, and is what to run before asking
the user anything. `SKILL.md`'s rule that nothing builds unprompted is restated
rather than weakened — the script existing is not permission to run it.

Verified with a real build: 36 s end to end onto the iPhone 16, 22 s of that
Xcode, then confirmed by item 6's preflight check, which now reads "installed
2026-08-13 16:20, newer than the newest commit". 126 tests became 144, the new
ones running against a fake repo built to the same shape as the real one.

Deliberately not built: session B also moved a branch to the Mac with `git
bundle` over `scp`, because the Mac has no Bitbucket key. That is a git problem
rather than a build one and it has not recurred.

## Done 13 Aug, after the ship — items 10 and 12, both about the Mac's checkout

Shipped 16:47, with items 5, 7, 9, 10, 12 and 15 together.

**10 — finding the checkout.** `init.sh --host <alias> --detect` now lists the
git checkouts under the Mac's home directory in the same call that already
reports simulators and installed apps, and marks the right one. Two decisions
in that:

- It matches on the **remote**, not the directory name. Two repositories can be
  spelt the same and only one of them is yours. `git@host:org/thing.git` and
  `https://host/org/thing` both reduce to `host/org/thing`, which is enough to
  match the two forms without pretending to parse URLs properly. A name-only
  match is still shown, labelled as one rather than treated as the answer.
- It **prunes the caches**. Unpruned the answer is a screenful of `.pub-cache`
  clones: 4.3 s and mostly noise, against 3.3 s and twelve real checkouts.

Verified on the real Mac: twelve checkouts, the right one first and marked
`<- same origin`. The whole `--detect` call is 5.1 s.

**12 — build residue.** `remote/gitstate.sh` replaces preflight's
`git status --short | head -5` and splits tracked changes into residue and real
edits, with the discard command printed and **not run** — a `Podfile.lock`
change can be a genuine dependency update and only whoever made it knows which
it was. Untracked files are counted rather than listed, because they do not
block a branch switch, which is the actual question.

**The bug in that worth remembering.** The read loop was
`while read -r st path`. The Mac's login shell is zsh, where `path` is tied to
`PATH`, so reading a filename into it emptied `PATH` for everything that ran
afterwards inside the same command — the next two sections of preflight failed
with `command not found: tail` and `command not found: appcheck`, which reads
as a broken Mac rather than a shell variable. It is `_p` now, and a test fails
if `path` comes back.

Verified against exactly the state session A hit: the two lock files still
modified from a build the day before, now named as residue with the command to
clear them. 144 tests became 162.

## Re-read of the sessions, 13 Aug evening — three more items

The first backlog review looked at four sessions. **Eight** had driven the Mac.
Reading the other four raised items 21, 22 and 23, corrected item 5, and
produced one item (20) that was raised and struck the same day.

The one that matters is `2712fef3` — call it **session E**, 13 Aug 13:03–14:25,
a GSD execute-phase that went on to verify on the device. It made 61 `driver.sh`
calls, 28 of them bare `nodes` reads, took five screenshots in a row, and
re-derived the login by hand.

Part of the reason is that `maestro/` was empty: it was committed to
`development` on 12 Aug (`1fb99db`) and the branch in use was cut before that,
which is ordinary git. `git show 1fb99db:maestro/app-notes.md` reads any of it
without touching the branch. This was raised as item 20 and struck the same
day — a merge brings the files back and it needs no tooling.

The keyboard guard refused a tap eleven times in that session, every refusal
correct, and there was no verb that dismisses the keyboard. That is item 21 —
but the diagnosis written here from the transcript was wrong on both of its
factual claims, and the section on it below says how. Read that one, not this
paragraph.

Bitbucket on the Mac is item 22, and it corrects this file as well as the
backlog: **the Mac does have a Bitbucket key.** It is `~/.ssh/bitbucket`, there
is no `Host bitbucket.org` block, and a non-interactive session has no agent, so
a plain `git fetch` fails with `Permission denied (publickey)` and reads as no
access at all. Naming the key in `GIT_SSH_COMMAND` works first time. Session B
worked around this with `git bundle` over `scp`; session E solved it in eighty
seconds and nobody wrote it down.

Item 23 came out of checking item 20 rather than out of a session.
`bin/secrets.sh check` skips the conf by design and searches only what git
tracks; both are sensible alone, and together they mean the file that holds the
credential is the one file never examined, with its protection resting on a
`.gitignore` line the check never looks at. It reports `clean` either way. One
`git check-ignore -q` before it says so closes it.

**A note on tone, because it is a correction worth keeping.** Item 20 was
written up as a serious defect — a branch switch "silently deleting" the
project's journeys and notes — and the maintainer struck it: a feature branch not having
files committed to `development` after it was cut is ordinary git, and a merge
brings them back. He was right, and the same overstatement had crept into 23,
which was trimmed to the actual defect. Measure the thing, then say what it
costs; do not dress a routine situation as a hazard.

Session `99462431` (10 Aug) is the origin session — where "can you remote
control a mac" was first asked. It hit items 5 and 10 before either existed
(`REPO NOT FOUND`, `flutter not found`, `pod not found`), so both now have two
sessions behind them rather than one. It raises nothing new. The two short
sessions barely touched the Mac.

## Done 13 Aug, evening — item 21, and a session that diagnosed it wrong

`driver.sh dismiss` puts the keyboard away. `driver.sh blank` prints the point
it would tap. `dismiss` is a journey verb too, and takes `--tree` like the rest.
Nine files changed, eight tests added, 162 to 170.

**The route question is settled, not guessed at.** `XCTestDriverClient.class`
was read out of `maestro-ios-driver.jar` on the Mac again and names eighteen
routes; not one of them hides the keyboard, because iOS exposes no API for it.
Maestro's own `hideKeyboard` is `IOSDriver.hideKeyboard` in `maestro-client.jar`
— Kotlin, in the client, swiping from the middle of the screen and then checking
`isKeyboardHidden`. Upstream documents that as flaky and recommends tapping a
non-interactive area instead. One find worth keeping: the client also names a
`keyboardInfo` route, which this driver answers **404**. If a later Maestro
ships a driver that serves it, the keyboard's geometry would come from the
device instead of being inferred from its size.

**The item's premise was wrong, and the way it was wrong is the useful part.**
It said `key return` does not dismiss this keyboard, citing session E. Session E
made three checks and every one of them ran `tapon` on the field again — raising
the keyboard — before reading the state back. It was measuring a keyboard it had
just put up. `key return` had worked each time.

So the methods were measured properly, on the same screen, with each reading in
a call that did nothing else:

| method | result |
| --- | --- |
| tap the emptiest point on the screen | keyboard still up |
| five more taps on other blank areas | still up, all five |
| swipe from the middle (Maestro's method) | still up |
| tap the keyboard's own `done` key | still up |
| `key return` | down, every time |

**The advice upstream gives does not work on this app, and the thing it warns
about does.** A tap on a blank area only unfocuses if the app was written to do
it; a Flutter app usually is not. That is a property of the app, so neither
method can be assumed and `dismiss` does both:

1. Tap the blankest point. It cannot do anything else, so it goes first.
2. `key return`, if the keyboard is still up. This submits whatever had focus,
   so when it is the method that worked, `dismiss` says so — on a dropdown with
   its list open the app may have committed a row, which is the exact silent
   wrong answer the day-4 note in `reference/apps/example-app.md` describes.
   `--no-key` stops before it.

The keyboard is read back after each, and a keyboard that will not go is
reported as still up rather than as dismissed.

**Finding the blank point** is `resolve.py --blank`. It builds a list of
rectangles a tap must miss — anything carrying text, anything whose element type
reacts to a tap, anything iOS drew, and the keyboard's own band — and takes the
grid point furthest from all of them. Two things in it are load-bearing and not
obvious. Full-screen nodes are excluded, because every app has a stack of them
and they are the background being looked for; without that, the sign-in screen's
`402x810` scroll view rules out most of the screen. And the screen's own edges
count towards the distance, or every answer comes back in a corner two points
from the edge, which is where iOS puts its own gestures.

It cannot see a tap target the accessibility tree does not report — a Flutter
gesture detector with no semantics node, an invisible scrim — which is why the
verb checks the keyboard afterwards rather than assuming. On a screen the app
fills edge to edge with tappable rows there is no blank point at all, and it
says so rather than tapping something anyway.

**One bug worth naming.** `_kb_gone` and `_kb_up` answer opposite questions, and
the first version of `_kb_gone` returned the inverse of what its callers tested.
`dismiss` reported failure on a screen where `key return` had just worked, one
second before a separate read showed the keyboard gone. Only running it against
the device caught it; the stub tests were written afterwards and now cover it.

Verified end to end against the live iPhone 16 Pro, on the screen the item came
from: `point "^Select Language$"` refused for being under the keyboard, one
`dismiss`, the same call resolving `201 640.2`. About six seconds, most of it
the blank tap failing before the fallback.

## What has actually been exercised (audit, 12 Aug)

Every changed path was run against the Mac except two, and one documented claim
turned out to be wrong:

- **Verified:** per-device bring-up (cold and warm), `up` for one device and
  for all, `down`, `down-all`, idempotent `up`; `DEV` selecting the device;
  one-driver-and-no-`DEV`; refusal with several drivers and no `DEV`; an unknown
  `DEV`; a pinned `DRIVER_PORT`; `driver.sh stop` and its automatic restart;
  journeys by bare name with `${VAR}` and `include`; reads and writes reaching
  the right device with the other untouched; profiling off→on, both empty-list
  branches, and a stale isolate being rejected after a hot restart.
- **Not exercised:** `publish.sh status` on a *reachable* service (it needs a
  live debug session; the unreachable branch was run), and `_rebind` in
  `driver.sh`.
- **Corrected:** `SKILL.md` claimed `driver.sh` "notices, re-reads the map and
  carries on" when a device's driver moves port. It does not, because that case
  does not arise: naming a device to the MCP server or the CLI **destroys that
  device's driver** and then answers about whichever device is on 22087.
  Measured — `maestro --device <iphone> hierarchy` killed the iPhone's driver
  and returned the iPad's hierarchy. The docs now say that; `_rebind` is kept
  but marked unverified in the code.

## Backlog

`BACKLOG.md` — raised 12 Aug from a review of four real sessions (`c286da8d`,
`b4184377`, `379d06ed`, `1d33fec2` in the brandco-flutter-runner project
directory), each item carrying the sessions and timestamps that produced it.
Twenty-three items now. **Eighteen are done, four are open (17, 19, 22, 23) and
20 was raised and struck the same day.** 21 was done on the evening of 13 Aug. 21, 22 and 23 came late on 13 Aug
from re-reading the sessions: the first review covered four, and eight had
actually driven the Mac. The numbering is the original ordering by measured time
cost and no longer reflects what is left — read the status on every heading
before starting anything.

Three items had their premises corrected on 13 Aug and must be re-read rather
than taken as written. **7** and **9** are both now done, and in each case the
correction is the reason the work was bigger than the item said — see the two
sections above. **12** was mostly about restoring the Mac and the devices to a
prior state; the maintainer: *"I don't need them returned to a state — the testing should
be rebuilt from scratch every time."* What survives is narrow — build residue in
the Mac's checkout blocking a branch switch, which is a git problem.

**17** picked up a third strand on 13 Aug. `ship.sh` is right about
`__pycache__` and never publishes compiled files; what the afternoon exposed is
that "the published copy matches `src`" is unanswerable, because nothing states
what the published tree is supposed to contain. Five items went live across
nineteen files and the only check they arrived intact was running the tests and
two commands by hand. The maintainer has said 17 is to be left until very last.

## Deferred, with the user's agreement

1. ~~Move `reference/apps/brandco-runner.md` (and the two flows) into a project
   of its own~~ — done 12 Aug. It was the last file holding real values (bundle
   id, store numbers, a login PIN, product barcodes). Its content is merged into
   `maestro/app-notes.md` in the brandco-flutter-runner checkout, the two flows
   are `maestro/flows/` there, and the pre-merge original is kept alongside as
   `app-notes-2026-08-11-original.md`. The skill keeps a worked example at
   `reference/apps/example-app.md` with real measurements and invented names,
   which is what `SKILL.md` and `reference/driving.md` now cite.
2. ~~Merge this directory's `bin/` into the build~~ — settled 12 Aug: it is
   `bin-STALE-pre-skill/` now, kept as history, with `src/` as the development
   tree.

## Still open, and not ours to close

Submitting a request fails on a missing property. App defect; the journey stops
one step short of end-to-end until it is fixed.

On `unit/PROJ-1788-automated-logout-phase` in the brandco repo,
`.maestro-mac.conf` is untracked **and** not ignored: the `.gitignore` line that
covers it was added on `development` after that branch was cut, so `git status`
lists it. The file holds `APP_PIN`. The maintainer was told on 13 Aug and it is his repo
to change — **do not edit his `.gitignore`**. This is the situation item 23 is
about, and it is why `secrets.sh check` answering `clean` there is misleading
rather than wrong.

## Measured and rejected

Carried in from `~/claude-sandbox/HANDOFF-2026-08-STALE.md` on 20 August 2026. The decisions
themselves are in the dated sections above; what was only there is the
alternatives that were tried and thrown out, each with the measurement that
killed it.

- **The minimal keyboard fix** — switch the guard off whenever its width does
  not match the screen — instead of transforming system frames into app space.
  Measured wrong: the iPad keyboard's widest node comes back as 1255 against a
  1194 screen, inside any sane tolerance, so the test would have passed and the
  guard stayed broken.
- **Deriving the keyboard band from the keyboard's position** rather than its
  size. Position is the half that arrives in the wrong coordinate space, and it
  had already produced a false positive on iPad and a false negative on iPhone.
- **Detecting the transposed space by comparing the root frame's aspect against
  `/deviceInfo`**, which is what the backlog item proposed. It cannot work:
  `/deviceInfo` returns 1194x834, identical to the app root, so there is nothing
  to compare. The status bar is the only element whose true position is knowable.
- **A cheap TCP probe to pick the SSH host.** Measured impossible: from inside
  the sandbox `/dev/tcp` fails against both addresses, including the live one.
  The host is selected with a real SSH attempt.
- **`MAC_HOSTS` as a second variable**, and auto-discovering `mac-*` aliases
  from `~/.ssh/config`. Predictable beats clever, and the sandbox only permits
  specific hosts anyway. `MAC_HOST` takes a space-separated list instead.
- **Retrying on any non-zero exit** rather than on ssh 255 and timeout 124 only.
  It would re-run remote commands that had already succeeded, and half of what
  goes through `_ssh` taps a screen.
- **A blank-area tap alone for `dismiss`**, which is what upstream recommends
  and what the backlog item asked for. Measured: it never works on this app.
  And `key return` alone, which always works here but submits the focused field
  and can commit the wrong dropdown row silently.
- **Taking the backlog's word that a driver route might hide the keyboard.**
  The jar's eighteen routes were read again; none hides it, and Maestro's own
  `hideKeyboard` is client-side Kotlin.
- **A `MAESTRO_VARS` list in the conf, and a blanket `set -a`**, for exporting
  project values. The user chose the `APP_*` prefix.
- **`notes.sh` warning about a credential rather than refusing.** A warning in
  an agent workflow gets read and ignored.
- **Redacting `RULES.md`'s 51 hits across 1413 lines.** It would leave the file
  neither an accurate record nor current guidance. Renamed with a banner
  instead; deleting it is the eventual answer, once `README.md` stops citing it.
- **Deleting `remote-STALE-pre-skill/`** on redundancy grounds. Withdrawn — it
  holds no project data, so it was never part of the credentials question.
- **Adding a `Host bitbucket.org` block to the Mac's `~/.ssh`** for item 22.
  The Mac's ssh config is the user's; the toolkit can say what it wants and let
  him write it.

## If something looks broken

- **`no driver for <udid>`** — that device has no driver. `bin/drivers.sh up
  <udid>`, about 30 s.
- **A read or tap answered about the wrong simulator** — something named a
  device to the MCP server or the Maestro CLI. That destroys the named device's
  driver and answers about whichever device is on 22087. `bin/drivers.sh` shows
  the truth; bring the missing one back up.
- **`N drivers are running and DEV is not set`** — intended. Set `DEV`.
- **A tap that lands somewhere odd** — `driver.sh find <pattern> --explain`
  prints the markers it applied, and now also names the system-space step when
  one was used. **Backlog item 8 was fixed on 13 Aug: do not convert by hand
  any more.** Earlier text here told you to, with
  `device_x = <short side> − app_y`. `bin/resolve.py` does it, and only for
  what iOS draws — the status bar, alerts and the keyboard. The app's own
  controls never needed converting, which is the part the old advice had
  wrong.
- **`tapon` refuses everything while the keyboard is up** — fixed 13 Aug and
  covered by tests. If it comes back, the keyboard band is being read from the
  keyboard's position rather than its size.
- **`notes.sh add` exits 2 saying nothing was written** — it wants
  `--measured`, `--once` or `--inferred` as a fourth argument since 13 Aug.
  Intended; there is no default.
- **A journey step fails with "typed X but nothing on screen shows it"** — the
  tap missed the field or only part of the text arrived. `TYPE_VERIFY=0`
  suppresses the check for a field the app rewrites as you type.
- **A screenshot comes back sideways** — `--raw` was passed, or the status bar
  could not be read. Without `--raw`, `driver.sh shot` turns it upright.
- **`bin/net.sh` empty** — it now says why. If it mentions profiling, repeat the
  action and read again. After any restart, re-run `bin/publish.sh` first.

## The Mac, as left on 13 Aug

**It is in the office, not at home.** `~/.ssh/config` has both `mac-a`
(10.0.0.10) and `mac-b` (192.168.1.10), and a project conf pinned to the
wrong one fails with `Connection timed out during banner exchange`, which reads
as the machine being asleep. Since 13 Aug `MAC_HOST` accepts a space-separated
list and picks the one that answers — but a conf naming a single stale alias
still dead-ends, so that is the first thing to check when nothing responds.

Drivers up on three simulators — iPad `22087`/relay `9101`, iPhone 16 Pro
`22088`/relay `9102`, iPhone 16 `22089`/relay `9103` — and the viewer relay on
`9999`, which has nothing behind it: Maestro Viewer is not running, so
`viewer.sh` reports that nothing answered.

The iPad is on the TASKS tab, orientation `landscapeLeft` — it was rotated to
`landscapeRight` during the afternoon to measure the screenshot rotation both
ways, and put back. **The iPhone 16 was wiped and reinstalled twice** to
reproduce the dropdown failure. It was left signed into store 4001 with Test
Runner and LOC1 chosen but not submitted; by the time item 7 was checked against
it a couple of hours later the app had logged itself out on its own inactivity
timer, so that screen is now the logged-out one with both dropdowns empty. A
copy of its bundle sits
at `/tmp/maestro-mac/app-copy/Runner.app` on the Mac, which is what makes the
reset a one-minute job (`simctl uninstall`, `install` from the copy, `launch`,
then the login journey). The maintainer has said state does not need restoring — testing
is rebuilt from scratch each time. No `flutter run` active.

Later on 13 Aug the iPhone 16 got a **fresh dev build installed at 16:20** by
`bin/build.sh` while item 5 was being verified — an incremental build, 36 s end
to end. That is the newest thing on any of the three simulators, and preflight
confirms it against the Mac's newest commit. The iPhone 16 Pro's driver was
deliberately destroyed at about 15:51 to measure item 15 and restarted with
`drivers.sh up`; all three drivers were up and correct at the end.

On the evening of 13 Aug the iPhone 16 Pro was driven for item 21: the keyboard
was raised and dropped about a dozen times on the sign-in screen and a few taps
landed on blank areas, none of which the app reacts to. It was left where it
started — logged out, both dropdowns empty, keyboard down. The two directories
the Maestro jars were extracted into, `/tmp/kbprobe` and `/tmp/kb2`, are
deleted.

Something on the Mac that a session did and nobody recorded: on 13 Aug at 13:55
session E ran `git config core.sshCommand "ssh -i $HOME/.ssh/bitbucket -o
IdentitiesOnly=yes"` in the brandco checkout, as **local** git config, and it
persisted. That is why `git fetch` works there now and fails everywhere else on
the Mac. It is a change to the maintainer's repository made without asking; it works and
undoing it would break the fetch, so it stays, but it is his to keep or drop and
it is the reason item 22 no longer reproduces on that one checkout.

The Mac's own checkout moved branch during the session, from `proj1787-review`
to `unit/PROJ-1788-automated-logout-phase`, with `ios/Podfile.lock` and
`pubspec.lock` modified by an earlier build. Neither matches whatever is checked
out locally, which is exactly what preflight's new block is for.
`/tmp/maestro-mac` holds the shared driver build products (26 MB); the extracted
jars and derived data from the investigation were deleted. `bin/drivers.sh
down-all` clears the drivers.

There is no `.maestro-mac.conf` in this working directory; point
`$MAESTRO_MAC_CONF` at one (host `mac-a mac-b`, fqdn
`dev-mac.local`, the brandco dev bundle id). The brandco project's conf
was updated on 13 Aug — by the maintainer, from commands handed over, because
that checkout is not writable from inside the sandbox — to list both aliases and to
explain what the `DEV` pin and `REPO` actually do. `DEV` there pins the iPhone
16 Pro, so **anything not setting `DEV` drives that one and never the iPad**.

## Next

**Item 21 is built and tested but not published.** `./ship.sh` lists nine files
— `bin/driver.sh`, `bin/resolve.py`, `test/run-tests.sh`, `SKILL.md` and five
under `reference/` — and 170 tests pass from `src/`. Publish only when the maintainer
asks in that message; he has not.

Items **5, 7, 9, 10, 12 and 15** went live together at 16:47 — five new files
(`bin/tree.py`, `bin/build.sh`, `remote/build.sh`, `remote/gitstate.sh`,
`remote/findrepo.sh`) and sixteen changed — and were smoke-tested through the
installed symlink afterwards. Everything since then is item 21 plus this file
and `BACKLOG.md`, neither of which lives under `src/`.

One housekeeping thing to watch for: a `.claude/.cc-writes` directory appears
inside `src/` whenever a command runs with its working directory there, and
`ship.sh` then lists it as new. It is a harness artefact, not part of the skill.
Delete it before shipping.

Ranked by what it costs when it bites, times how often it does:

**22 next**, and the maintainer said on 13 Aug he would pick it up the following day. The
reading is done and one premise has changed, so read the item before writing
anything: `~/.ssh/bitbucket` exists, there is still no `Host bitbucket.org`
block, `ssh -T git@bitbucket.org` still fails because only the default `id_*`
names are offered and none exist — **but `git fetch` in the brandco checkout
now works**, because of the `core.sshCommand` session E left behind. So the
symptom is per-repository: fixed for that one clone and unchanged for every
other repo on the Mac. The doc should say that, name the config that is already
set so nobody re-diagnoses it, and leave the durable fix — a `Host
bitbucket.org` block with `IdentityFile ~/.ssh/bitbucket` — as the maintainer's to apply,
because the Mac's ssh config is his.

**23 with it** — `secrets.sh check` reports clean without checking that the conf
is gitignored, so it answers a narrower question than the one being asked. One
`git check-ignore -q` before it says clean. An hour with tests, and it pairs
naturally with 22 as a short sitting.

**19 is not ready.** It says to leave it until item 16's confidence markers have
been used for a while, and 16 shipped on 13 Aug. Two notes were written against
them that evening, in `reference/apps/example-app.md`, which is a start and not
yet a sample.

**17 is last**, by the maintainer's standing instruction. That deferral is not a
judgement about its size: no version, no manifest, no installer and no git
remains the biggest structural risk here, and six items going live in one ship
with no history to review them against is exactly the situation it describes.
