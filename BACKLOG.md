# maestro-remote-mac — backlog

**Four items are open: 87, 90, 93 and 94**, and none of them is gated on
another. **17 is done** — the package has a git repo, a version, a manifest, an
installer and an update path. That releases **28**, which waited on it.

**87 is mostly built.** The seam exists, `runners/flutter`, `runners/ios` and
`runners/ios-device` are complete with every verb verified against real devices,
and `RUNNER` and `PLATFORM` change what nine scripts say. What is left of it is
blocked on hardware that is not on that Mac — there is no Android SDK and no
React Native checkout — so `runners/android` and `runners/react-native` are
stubs that say so rather than code nobody has run.

**90, 93 and 94 came out of building it.** 90 is the wall not showing a physical
device, 93 is the sister skill carrying its own Flutter answers and disagreeing
with this package's from the same conf file, and 94 is running against a
simulator on this machine with no SSH at all.

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

**85 is done, on 18 Sep, and has moved to `BACKLOG-DONE.md`.** It was the first item about setting the skill up
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
rather than how it works, and most of it was built the same day. Its own entry
carries the stage-by-stage state and the seven bugs that only running it found.

**91 and 92 are done and were not planned.** Both came out of 87 — a live driver
had never protected a peer's wall label, and an audit of the SSH boundary for
the same family of mistake found two more — and both are in `BACKLOG-DONE.md`
with 85.

**Next item number: 95.** Items 1–94 are allocated; new items start from 95.

**Two commits on `backlog/87-runner-modules` carry the wrong item number.** They
say `BACKLOG 88` and `BACKLOG 89`, and both of those were already allocated and
done — 88 is the rig-reap item, 89 is `wall.sh label` swallowing its flags. The
work in them is real and is now filed as **91** and **92** below. The commit
messages are left alone rather than rewriting the branch's history for a label.

---

## 94. Everything goes over SSH, including when the device is on this machine — **OPEN, raised 18 Sep**

The package is named for the case it was built for: a Linux box driving a Mac.
A developer whose simulator or emulator is on the machine they are sitting at
cannot use it at all — `bin/config.sh` refuses to load without `MAC_HOST` and
`MAC_FQDN`, and there is no host to give it.

**It is a smaller job than the shape suggests.** Counted 18 Sep:

```
84  _ssh "<script>"   across 21 files   ONE function in bin/lib.sh
16  raw ssh / scp     across 12 files   individual, mostly file copies
```

The 84 do not change. They already pass a shell script and read its output, and
`_ssh` is free to run that with `sh -c` instead of handing it to ssh. The 16 raw
calls are the ones needing attention one at a time.

**Six things are not simplified locally — they become unnecessary.** Each exists
only because there is a boundary:

| piece | why it exists | locally |
| --- | --- | --- |
| `remote/relay.py`, `bin/publish.sh` | republishes the Mac's loopback-bound debug endpoint on its LAN interface | read `127.0.0.1` |
| `$grpc_proxy` on every curl | the sandbox's egress proxy | no proxy |
| base64 round-trips in `shot.sh`, `flow.sh`, `img.sh` | getting a PNG back over SSH | the file is already there |
| `_pick_host`, `_probe_host`, `MAC_HOST` as a list | the Mac moves between networks | no host to pick |
| `MACIP`, `MAC_FQDN` | building URLs the sandbox can reach | `127.0.0.1` |
| `$RDIR` vs `$LDIR` | two machines, two scratch directories | one |

**Three parts need thought rather than a branch.**

**`config.sh`'s required settings.** It refuses without `MAC_HOST` and
`MAC_FQDN`. Local mode is a different required-settings shape, not an exemption
bolted onto the existing one — and the message it prints when a project is not
configured is one of the more useful things this package does, so it has to stay
that good for both.

**`$RDIR` and `$LDIR` collapsing to one directory.** Code that copies between
them would copy a file onto itself. `bin/shot.sh` and `bin/install.sh` both do.
This is the part that looks trivial and is not: every `scp` and every
`base64 | base64 -d` pair is a copy between two names for what would become one
place.

**The wall.** It binds the Mac's LAN interface and publishes a URL built from
`MAC_FQDN`. Locally that is `127.0.0.1:9990` — but `WALL_URL` already exists as
the override for exactly this, so it may cost nothing. Check before assuming it
does.

**The runner modules are unaffected**, which is worth saying because it is the
same argument item 87 rests on, one layer down. Every platform and framework
verb already runs on the machine that has the device and is invoked as
`sh <module> <verb>`. Whether that machine is reached by ssh or IS this one is
`_ssh`'s business and none of theirs.

**Naming.** If this lands, `maestro-remote-mac` is the wrong name for what the
package does. Not a reason to avoid it, but it is a rename, an installed skill
directory, an MCP server entry and a repo — so decide it deliberately rather
than discovering it at the end.

**Gated on:** nothing. Item 87 touches `_ssh` only as a caller.

## 93. `flutter-hot-reload-mac` carries its own Flutter answers, and they are worse — **OPEN, raised 18 Sep**

Split out of item 87's Stage 5, where it was 5.3. **The work is in the
`flutter-hot-reload-mac` repo, not this one** — it is raised here because this
is where the seam it should plug into lives.

The sister skill installs alongside this one, reads **the same
`.maestro-mac.conf`**, and does the half this package deliberately does not:
build from source, launch under `flutter run`, push local edits as hot reloads.

**It defaults where this package discovers, from the same conf file.**

```
flutter-hot-reload-mac                    runners/flutter
bin/lib.sh:46  FLUTTER_BIN               build.sh  _flutter(), eight candidates
   := .fvm/flutter/bin/flutter                     in preference order, the
                                                   pinned SDK first
bin/lib.sh:48  TARGET                    build.sh  derived from the flavour,
   := lib/main_dev.dart                            which is derived from APP_ID
remote/frun.py:34  FRUN_FLUTTER          build.sh  the same discovery
   := .fvm/flutter/bin/flutter
remote/frun.py:55  --flavor FLAVOR       build.sh  _flavour_for_appid, which
                                                   REFUSES rather than guessing
```

`lib/main_dev.dart` is hardcoded as the entrypoint. This package works it out
from the bundle id under test and refuses when two flavours build the same one,
because building the wrong flavour installs a different app and leaves the one
under test untouched — which nothing reports. So a project that is not
`dev`-flavoured gets the right answer from one skill and the wrong one from the
other, **reading the same file**.

**And it has the sharper problem item 24 recorded:** `bin/start.sh` runs
`git checkout` on the single shared `$REPO`, so pointing it at a review branch
silently clobbers uncommitted work in whatever else is using that checkout. That
is a safety requirement for concurrent reviews, not a tidiness one.

**What it should consume.** `describe`, `build` and `inspect` are already the
verbs it needs. `inspect` especially: it has its own VM Service discovery in
`frun.py` reading `/tmp/frun.log`, which is the SECOND log file
`runners/flutter/vmservice.sh` already checks by name — the two were written
against each other by hand rather than sharing one answer.

**The payoff is not tidiness.** It is that "hot reload a React Native app"
becomes a module rather than a second skill, and that two skills reading one
conf stop being able to disagree about which flavour a project builds.

**Gated on:** item 87 landing, so there is a stable contract to plug into.

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

## 87. Flutter and iOS are wired in, not plugged in — **OPEN, raised 18 Sep; the seam is built, three modules are complete and verified, and what remains is blocked on hardware**

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

**4.1 DONE 18 Sep — `boot` prints the id it booted, as its last line.** Not a
second `resolve` verb: the caller always has to act on the booted device
afterwards, so returning the id costs one line on a platform where it does not
change and saves every caller a round trip on one where it does. `runners/ios`
echoes its argument.

The consequence for `devices` is recorded with it: on a platform like that, the
id column means "the id you use to act on this device IN ITS CURRENT STATE", so
a shut-down emulator lists under its AVD name and a running one under its
serial. Inherent to the platform, not a wrinkle in the contract.

**4.2 DONE 18 Sep — `variants` and `variant-for-appid` take an optional
`--platform <p>`.** A framework whose variants span both platforms accepts it
and answers the same: one Flutter `--flavor uat` builds the iOS app and the
Android one, so ignoring it is the right answer rather than an omission, and a
caller can pass it unconditionally. React Native's do not span, and it needs
telling which list.

An optional argument rather than a second verb, because the caller always knows
its platform already — `bin/build.sh` has `PLATFORM` in hand — so passing it is
free and a framework that does not care is not made to care.

`variant-for-appid` takes it for the same reason: an app id is itself
per-platform, a bundle id on iOS and an applicationId on Android.

**4.3 SUPERSEDED 18 Sep.** It asked for an Android `container`, and the answer
turned out to be that `appcheck` should stop needing one. `platform.sh
installed-info` reports what a platform CAN say and `appcheck` reasons from
whatever arrives, so an absent key is a fact rather than a failure. Android
answers `version`, `build` AND a timestamp through `dumpsys package`, which is
more than a phone gives — so `container` being unanswerable there costs the
check nothing. Written and unmeasured, like the rest of that module.

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

**5.3 is now item 93** and left this one. It is work in another repo, and
keeping it inside 87 made 87 look unfinished when what remains is a separate
package's to do.

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
