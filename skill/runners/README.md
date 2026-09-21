# Runners — the seam where the framework and the platform plug in

BACKLOG item 87. This file is the contract. `TEMPLATE/` is the empty module to
copy; `flutter/` and `ios/` are written against today's code and are worked
examples of the contract rather than the code paths in use — nothing calls a
runner yet, and every Flutter and iOS line named below is still in the file it
has always been in.

`react-native/` and `android/` are **stubs, and nothing in them has been run.**
Both say so at the top and mark each verb as documented-not-measured or
unanswered. Six verbs across the two are deliberately left unanswered, because
each hides a question the contract does not yet answer — they are listed under
"What the stubs found" below, and they are the useful part of writing them.

## Two modules, not one

Two questions are being answered and they are independent.

**The framework** decides how the app is built and how you see inside it while
it runs. Flutter, React Native, a plain Xcode project, a plain Gradle project.

**The platform** decides how the app is installed, listed, booted, captured and
driven. iOS simulator, iOS device, Android emulator, Android device.

They cross. React Native on Android is a real combination, and so is Flutter on
Android — which is the reason a single `RUNNER=flutter|react-native|android|ios`
setting cannot work: it would make `flutter` and `android` alternatives to each
other when they are in fact both true at once.

So the four modules asked for split across the two axes:

```
                    framework                        platform
  flutter           runners/flutter          worked   —
  react-native      runners/react-native     stub     —
  ios               —                                 runners/ios         worked
  ios-device        —                                 runners/ios-device  worked
  android           —                                 runners/android     stub
```

`runners/ios` and `runners/android` also answer the framework questions for a
project with no framework above the platform — a plain Xcode or Gradle app. A
module may therefore carry `framework.sh`, `platform.sh`, or both; `runners/ios`
here carries only `platform.sh` because the Flutter side is still in
`remote/build.sh`.

## What does not move

Everything Maestro-shaped already generalises and stays where it is:
`driver.sh`, `drivers.sh`, `flow.sh`, `journey.sh`, `img.sh`, `wall.sh`,
`resolve.py`, `typed.py`, `tree.py`, `watch.py`, the rig lifecycle, the label
reclaim, `relay.py`, `notes.sh`, `secrets.sh`, and the whole SSH and
network side. A tap is a tap.

`remote/appcheck.sh` stays too: comparing an installed bundle's timestamp with
the newest commit, and grepping it for `BUILD_MARKER`, is the same arithmetic
whatever built it. Only the two inputs come from runners — the container path
from the platform, the residue list from the framework.

## The framework runner

One executable, `runners/<name>/framework.sh`, dispatching on its first
argument. Exit status is the answer wherever the verb is a question.

Two of them run in the sandbox and the rest run on the Mac. That split is not
cosmetic: the Mac-side ones are pushed to `$RDIR/runners/<name>/` by
`bin/install.sh` alongside `hier.py` and `vmservice.sh`, and the sandbox-side
ones talk to the Mac through `$grpc_proxy` and must never be sent.

| verb | runs | answers | today |
| --- | --- | --- | --- |
| `claim <repo>` | Mac | is this checkout mine? exit 0 and print the evidence | nothing — the framework is assumed |
| `describe <repo> [app-id]` | Mac | the `build.sh --detect` report: toolchain, version, variant, entrypoint, last build | `remote/build.sh` lines 144-182 |
| `variants <repo> [--platform <p>]` | Mac | one buildable variant name per line; `--platform` is optional and ignored by a framework whose variants span both | `_flavours` |
| `variant-for-appid <repo> <app-id> [--platform <p>]` | Mac | the variants that produce that app id, one per line | `_flavour_for_appid` |
| `build <repo> --platform <p> --mode <m> [--variant <v>] [--target <t>]` | Mac | builds, and prints `artifact <path>` as its last line | `remote/build.sh` lines 264-292 |
| `version <repo>` | Mac | `<version>+<build>` a build from this checkout would produce — what a device is compared against, having no install time | nothing; the check did not exist |
| `residue` | either | one glob per line; a tracked path matching one is build residue | `_gs_residue` in `remote/gitstate.sh` |
| `devsession` | Mac | is a hot-reload session live? print the processes, exit 0; exit 1 with the consequence when not | `pgrep -fl flutter_tools` in `bin/preflight.sh` |
| `inspect <device> <cache>` | Mac | print `<base-uri> <session-id>` for the app's live debug endpoint, or exit 1 with the reason | `remote/vmservice.sh` |
| `traffic-arm <base> <session>` | either | turn HTTP capture on; print `<was> <now>`, each `on`, `off` or `unknown` | `ext.dart.io.httpEnableTimelineLogging` in `bin/publish.sh` |
| `traffic-list <base> <session>` | either | one request per line: id, method, status, uri | `bin/net.sh` + `remote/net.py list` |
| `traffic-one <base> <session> <id>` | either | one request in full: headers, both bodies | `bin/net.sh` + `remote/net.py one` |
| `prefs-prefix` | either | the key prefix the framework's preferences API writes, or nothing | the `flutter` default in `bin/prefs.sh` |

**Exit 2 means "this framework does not have that".** It is not a failure. A
plain Xcode app has no `inspect` and no `traffic-*`, and the caller must say
"native apps have no traffic endpoint" rather than "the relay is broken" — the
same distinction `vmservice.sh` already draws between "no VM service" and "not
in debug", which cost one session six minutes when it was missing.

**`build` stops at the artefact and does not install.** That was the one real
change to today's shape, and it is **applied**: `remote/build.sh` now prints
`artifact <path>` on a successful build whether or not an install follows, and
`--build-only` stops there. On the simulator path the install is `_install_sim`,
a named unit `runners/ios/platform.sh install` mirrors line for line; on the
physical-device path, where the build and the `devicectl` install were welded
together inside one script handed to the Mac's GUI session, `--build-only`
emits the build half alone. Existing callers are unaffected — without the flag
it builds and installs exactly as before — and five tests hold the split.

**`inspect` is discovery, not publishing.** `relay.py` forwards a loopback port
on the Mac to its LAN interface and does not care what is on the other end, so
`publish.sh` keeps it. What the framework owns is finding the endpoint and
arming the capture.

## The platform runner

One executable, `runners/<name>/platform.sh`. All of it runs on the Mac except
`claim`, which is a string test.

| verb | answers | today |
| --- | --- | --- |
| `claim <device-id>` | is this device id mine? | the UUID-shape test in `bin/build.sh` that tells a simulator from a phone |
| `devices [--booted]` | one per line: `<id>` TAB `<state>` TAB `<name>` | `xcrun simctl list devices booted` in `lib.sh`, `drivers.sh`, `wall.py` |
| `boot <id>` / `shutdown <id>` | boot or shut down, wait for it to settle; `boot` prints **the id it booted** as its last line | `drivers.sh rig up` / `rig down` |
| `install <id> <artifact> [app-id]` | install, then confirm the app id is resident; non-zero if not | `simctl install` + `get_app_container`, `devicectl device install app` |
| `installed-info <id> <app-id>` | `key=value` lines for the installed app: `version`, `build`, and `epoch`/`container` where the platform has them. An absent key means "cannot tell" | the `get_app_container` + plist reads in `remote/appcheck.sh` |
| `container <id> <app-id>` | the installed bundle path, for `appcheck` | `xcrun simctl get_app_container` |
| `data-container <id> <app-id>` | the app's data container, for `prefs.sh` | `get_app_container … data` |
| `prefs-read [--raw] <id> <app-id>` | the preferences store on stdout, readable or as it sits on disk | the plist read in `bin/prefs.sh` |
| `prefs-flush <id> <app-id>` | background the app so preferences reach disk | the `notifyutil` line in `bin/prefs.sh` |
| `orientations <container>` | the orientations the installed bundle supports | the `Info.plist` block in `bin/preflight.sh` |
| `screenshot <id> <path>` | write a screenshot on the Mac at that path | `xcrun simctl io … screenshot` in `bin/shot.sh` |
| `driver-up <id> <port>` | start a Maestro driver for that device on that port | `remote/driverup.sh`, `remote/deviceup.sh` |
| `driver-down <id>` | stop it | `drivers.sh down` |
| `driver-scan` | the live map: `<id> <port> <pid>` per line | `_driver_scan` in `bin/lib.sh` |
| `uninstall <id> <app-id>` | remove the app and its data; already-absent is not a failure | `simctl uninstall` in `bin/driver.sh` |
| `locked <id>` | 0 locked, 1 not, 2 the question does not apply | the `devicectl lockState` check in `bin/driver.sh` |
| `last-used` | `<id>\|<yyyymmdd>\|<human>\|<today>` per booted device, in one call, for `rig reap` | the CoreSimulator container walk in `bin/drivers.sh` |
| `capture-cmd <id>` | the command line for the wall's per-device capture process | `simulator-server ios --id <udid>` in `remote/wall.py` |

`driver-up` and `driver-scan` are the two that carry the most iOS in them —
`xcodebuild test-without-building`, the `TEST_RUNNER_PORT` convention, the
`maestro-driver-iosUITests-Runner` process name. None of that survives to
Android, and all of it is already in files of its own, which is why the
platform axis is the cheaper of the two to cut.

## Choosing a runner

`bin/config.sh` gains two settings, both defaulting to what the code does
today, so every existing `.maestro-drive.conf` keeps working unchanged:

```sh
: "${RUNNER:=flutter}"     # the framework module
: "${PLATFORM:=ios}"       # the platform module
```

`bin/runner.sh` resolves them to a path and execs the verb. `RUNNER=auto` runs
every `framework.sh claim` against `$REPO` on the Mac and takes the single one
that answers; more than one, or none, is refused with the candidates listed
rather than guessed at — the same standard `remote/build.sh` already holds
itself to when two flavours build one bundle id.

`bin/init.sh --detect` gains the same call, so the written conf names the
runner it found instead of leaving the next session to discover it.

## The call sites that change

Seven, and each is a handful of lines. The shape of the change, not the change
itself — none of this is applied yet.

1. **`remote/gitstate.sh`** — `_gs_residue`'s `case` becomes a match against a
   newline-separated list in `$RESIDUE_GLOBS`, defaulting to today's five
   patterns. *Applied: the list is a parameter now, with the Flutter default
   still in the file.*
2. **`bin/preflight.sh`** — the `flutter run active?` block becomes
   `framework.sh devsession`, with the heading and the "what you lose" text
   coming from the runner. *Applied: the pattern, the heading and the
   consequence are variables now, still set to the Flutter ones.*
3. **`bin/build.sh`** — splits into `framework.sh build` then
   `platform.sh install`, and the physical-device branch becomes
   `PLATFORM=ios-device` rather than a UUID-shape test inside the script.
   ***Applied.*** `remote/build.sh` separates the two, `--build-only` stops
   after the build, and `bin/build.sh` now makes two SSH calls through
   `runner.sh rpath` — `framework.sh build`, then `platform.sh install`. The
   UUID-shape test that decided simulator-or-phone is `platform.sh claim`, the
   `--all` device list is `platform.sh devices --booted`, and `--detect` is
   `framework.sh describe`. `--install-only <path>` is new.

   **Two calls, with the artefact path returned between them.**
   `_ssh framework build`, parse its `artifact <path>` line, then one
   `_ssh platform install` that loops over the target devices on the Mac. That
   is one more round trip than concatenating the two verbs into a single remote
   command — 0.35 s against an SSH connect of 0.30-0.44 s, on a 36 s
   incremental build, so about 1 %.

   What the 1 % buys is the artefact path on this side, which means a *second*
   install skips the build entirely. That is not only the several-simulators
   case: `--all` already builds once and installs to every booted simulator in
   one remote call, so devices present at build time cost the same either way.
   It is any install of an artefact already built — a simulator booted after
   the build (item 24's concurrent reviews), a reinstall after `simctl erase`,
   an uninstall to test first launch, a device lost and replaced mid-session.

   **A no-op build is 21-22 s**, measured 18 Sep 2026: three consecutive
   `bin/build.sh --no-install` runs against an unchanged tree gave 34 s (19.6 s
   Xcode), 22 s (13.2 s), 21 s (12.4 s). Xcode re-runs Flutter's script phase
   every build whatever the staleness of its outputs, and ~9 s goes on `pub get`
   before Xcode starts, so rebuilding an unchanged tree is never cheap.

   One install of a build already made therefore saves 21 s, and pays for sixty
   builds' worth of the saving the single-call form offers.

   Not settled by this: the physical-device path polls a GUI-session build for
   up to 1200 s and keeps its own `TMO`, so the two paths do not share a
   timeout rule.
4. **`bin/publish.sh`** — `_ssh vmservice.sh` becomes `framework.sh inspect`;
   `_profiling` and `_profiling_on` become `framework.sh traffic-arm`. The relay
   start and the state file stay.
5. **`bin/net.sh`** — the two `ext.dart.io.*` URLs and the `net.py` calls become
   `framework.sh traffic-list` and `traffic-one`. The fast-path/SSH-fallback
   choice and the "empty means one of two things" explanation stay.
6. **`bin/prefs.sh`** — the container lookup and the plist read become
   `platform.sh data-container` / `prefs-read` / `prefs-flush`; the default
   filter becomes `framework.sh prefs-prefix`.
7. **`bin/lib.sh` `_dev` and `_driver_scan`, `bin/drivers.sh`, `bin/shot.sh`,
   `remote/wall.py`** — every `xcrun simctl` becomes a `platform.sh` verb. This
   is the largest of the seven by line count and the least interesting: it is
   one command substituted for another, over and over.

## What the stubs found

Six verbs in `react-native/` and `android/` are left unanswered, and each one is
a hole in the contract above rather than work somebody merely has not done yet.

**`android boot` — an AVD name and an emulator serial are not the same id.**
An iOS simulator has one UDID whether it is booted or not, so every verb takes
the same argument and the contract was written assuming that. An Android
emulator has an AVD name while it is off and a serial (`emulator-5554`) once it
is up, assigned by the port it lands on. Either the contract gains a
`resolve <name> -> <id>` verb, or `boot` returns the id it booted.

**`android container` — `appcheck` has no Android form.** `container` exists so
`remote/appcheck.sh` can compare the installed executable's timestamp with the
newest commit, which is the check two separate sessions worked out from scratch
and which caught a build from another branch both times. Android has neither an
executable path nor an `Info.plist`; `dumpsys package <id>` gives
`versionName`, `versionCode` and `lastUpdateTime`, which is probably the shape
the Android answer takes. Until that is settled, the single most valuable check
in `preflight.sh` does not cross to Android.

**`android driver-up`, `driver-down`, `driver-scan` — a different driver
entirely.** Maestro's Android driver is an instrumented APK reached through
`adb forward`, not an `xcodebuild test-without-building` run, so nothing about
`TEST_RUNNER_PORT` or the `maestro-driver-iosUITests-Runner` process scan
survives. The open question is the one this package cares most about: whether
the port can be chosen per device at all. `bin/drivers.sh` exists because
Maestro's iOS client hardcodes 22087; if the Android client does the same, the
several-devices-at-once property does not cross either.

**`react-native variants` — two lists, not one.** iOS schemes live in
`ios/*.xcodeproj`, Android product flavours in `android/app/build.gradle`, and
they need not share names. `variants <repo>` returns one list, so it probably
has to take the platform as a second argument — which makes it the one verb
where the two axes are not independent after all.

**`react-native traffic-*` — the honest answer is "there is none".** Flutter has
traffic capture because `dart:io` routes every HTTP call through one runtime
that can be asked to record them. React Native's `fetch` goes to `NSURLSession`
on iOS and `OkHttp` on Android, neither of which reports to the JS runtime, and
Hermes does not implement the CDP Network domain. Reading traffic there means a
proxy the app is pointed at before it starts — configured, not armed at
runtime. That is a different verb, and whoever needs it should add one rather
than make these three lie.

One more that is answered but worth knowing: `react-native devsession` must
**not** copy Flutter's wording. A debug React Native build loads its JS bundle
from Metro, so no Metro means the app does not start — the opposite of the
Flutter case, where driving is unaffected and only the traffic reads are lost.

## Writing a runner

Copy `TEMPLATE/`, rename it, and fill in the verbs. Leave the ones the
framework or platform genuinely lacks exiting 2 — the stub already does, with
the message the caller should print.

Three rules the existing code earned the hard way and a runner must keep:

- **Refuse rather than guess.** Two variants that both build the requested app
  id is a refusal with both named, not a coin toss. Building the wrong one
  installs a different app id and leaves the app under test untouched, and
  nothing reports it.
- **Say which of two failures it was.** "No debug endpoint" and "an endpoint
  that has no live session" are different problems with different fixes, and a
  message covering both sends the reader to the wrong one.
- **Never hardcode a discovered port or session id.** They change on every
  launch, install and hot restart. Cache them in the file the caller passes and
  re-validate before use.
