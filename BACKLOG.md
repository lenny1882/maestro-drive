# maestro-drive — backlog

- **100.** Journeys are not Maestro tests — gated on Flutter 3.49 stable for the setup screens.
- **97.** The MCP server dies when the Mac is on another network.
- **93.** `flutter-hot-reload-mac` carries its own Flutter answers, and they are worse — gated on item 87.
- **90.** The wall shows simulators only, and a phone is a device too — gated on finding a way to stream a physical device's screen.
- **87.** Flutter and iOS are wired in, not plugged in.
- **107.** The `MaterialApp.router` dropdown report has not been sent upstream — re-test against Flutter 3.49 first.
- **109.** `wall.sh label <name> <udid>` labels the wrong device and reports success.
- **110.** `script --steps '…' file.journey` swallows the file name into the last step.
- **111.** The ambiguity refusal says "pass --index", and `tapon` refuses `--index`.
- **112.** Nothing stops a second session launching onto a device another session has labelled.
- **113.** The ssh transport only reaches a Mac; a remote Linux box with an Android emulator cannot be driven.
- **114.** `lib/update-check.sh` is installed and nothing runs it.
- **115.** `remote-STALE-pre-skill/` is still tracked.
- **120.** `flow.sh -f` cannot run a flow that `runFlow`s a file beside it.
- **121.** `drivers.sh rig up` on Android announces a driver it will not start.
- **122.** `prefs-read` on Android runs every `shared_prefs` file together, unnamed.

Next item number: 123.

Finished items are in `BACKLOG-DONE.md`.

---

## 100. Journeys are not Maestro tests — **OPEN**

**What.** The default driving path does not use Maestro. `driver.sh` talks
straight to the XCUITest runner's HTTP API on 22087 (`skill/SKILL.md:28-46`). A
journey is this toolkit's own step language, interpreted line by line in
`bin/driver.sh:818-925`, with `resolve.py` turning each pattern into a point.
The only part of Maestro in the loop is the runner binary.

The step language is not the difference. Almost every verb has a one-line
Maestro equivalent: `tapon` → `tapOn`, `text` → `inputText`, `key return` →
`pressKey: Enter`, `expect X 15` → `extendedWaitUntil`, `include-if` →
`runFlow` with `when: visible`. What differs:

- **Who picks the point.** `resolve.py` corrects frames it knows are wrong,
  including the 1/3 scale. Maestro taps the centre of the frame as reported,
  after settling and re-resolving the element in a fresh tree
  (`Maestro.kt:216-255` in `mobile-dev-inc/maestro`).
- **Where it runs.** A journey runs only through this toolkit and its relay. A
  flow runs in CI, on Codemagic, in Maestro Studio and on any other machine.
- **What it costs.** A journey keeps the driver up: the setup journey takes
  about 9 s. Every `maestro test` pays 15–30 s of startup and kills that
  device's driver (`bin/flow.sh:7-10`).
- **What Maestro has that journeys lack.** `id:` selectors, relational
  selectors (`below:`, `childOf:`), `retryTapIfNoChange`, `repeat`, JavaScript,
  `launchApp` with `arguments` and `clearState`, JUnit and HTML reports. Parts
  of its settle-then-re-resolve are rebuilt here: `_settle`, the
  byte-identical-tree check, and the keyboard guard.

**Why.** Nothing learnt by driving becomes a test that runs outside this
toolkit. It cannot simply switch: with Maestro 2.8.0 against an app built on
Flutter 3.41.9, once a searchable dropdown closes every Flutter node reports at
1/3 scale until the process restarts, and a restart loses the chosen value. No
Maestro command acts on correct frames between closing the dropdown and tapping
the submit button; only a hard-coded `point:` works. `resolve.py`'s correction
is the only reason journeys pass that screen. On the 3.49.0-0.1.pre beta the
scale is fixed and a selector-only flow passes end to end, provided it commits
the dropdown value by filtering and pressing Enter. A second bug survives the
beta: rows of a `DropdownMenu` whose field moves after it opens keep their old
frame, so a row tap still misses. It is isolated in a stock app; no upstream
report of it exists.

**To do.** Proposed shape, not decided:

1. `driver.sh` stays the way to read, look and explore: 0.28 s against 7.7 s
   for a hierarchy, and it drives several devices.
2. What gets kept and replayed becomes a Maestro flow, run with `maestro test`.
3. Screens after setup convert now. The setup screens wait for 3.49 stable or a
   launch argument that skips them; otherwise they need `point:` taps.
4. When 3.49 is stable, `resolve.py`'s scale correction is removed.

Questions to answer before building:

- Whether a journey → flow converter is worth writing, or flows are written by
  hand.
- Whether the byte-identical-tree check has a Maestro equivalent, since Maestro
  reports COMPLETED for a tap that landed on nothing. The 2.8.0 docs
  (`reference__commands-available__tapon.md`) give `tapOn` a
  `retryTapIfNoChange` option that retries when the hierarchy does not change —
  the same check, used to retry. They do not say whether the step fails when
  the retry also changes nothing, so a flow still needs an assertion after it.
  Per item 105, the raw hierarchy JSON differs read to read on an unchanged
  screen, so any comparison must be of the parsed tree.
- What per-run startup costs when iterating on one flow, and whether
  `maestro test --continuous` removes it. The docs
  (`maestro-cli__maestro-cli-commands-and-options.md`) do not say. Measuring it
  needs a `maestro test` run on a device whose driver can be stopped
  (`bin/flow.sh:7-10`).
- How `flow.sh` and several devices fit together, given each run takes that
  device's driver down.

**Gated on.** Flutter 3.49 stable, or a launch argument that skips them, for
the setup screens only.

## 97. The MCP server dies when the Mac is on another network — **OPEN**

**What.** `bin/mcp.sh` sources `config.sh`, which loads the project conf. With
`MAC_HOST` naming one alias that is not reachable from the current network,
`_pick_host` has one candidate, cannot reach it, and the server exits before it
speaks any MCP. Claude Code reports `CONNECTION_CLOSED`, which reads as a broken
install, while ssh to another alias and every `bin/` script work.

`_pick_host` returns at `[ "$n" -le 1 ] && return 0` (`lib.sh:205`): with one
candidate it never probes, caches or re-picks. A single-alias conf switches the
fallback mechanism off, which is why the failure is total rather than slow.

`maestro-bridge` can show the same `CONNECTION_CLOSED` for an unrelated reason.
It takes no conf and touches no Mac, so a network change cannot close it; it
fails when the session was spawned before its directory existed under
`~/.claude/skills/maestro-drive/bin/`. `CONNECTION_CLOSED` names only the
transport, so which server reported it is the first thing to establish.

**Why.** An unreachable Mac makes the `maestro-mac` server vanish with a
message that names none of the cause: not the conf, not the aliases tried, not
the network.

**Done.**

- *Where the aliases live.* `MAC_HOST` may name several and `_pick_host` walks
  them (item 18). A conf now lists every `Host` block for the Mac, e.g.
  `mac-a mac-c mac-b`, existing value first. Before: `bin/mcp.sh` printed
  `socat[22] E CONNECT …:22: Bad Gateway` and
  `kex_exchange_identification: Connection closed by remote host`, exit 255.
  After: `mcp_viewer_ready http://127.0.0.1:9999` and
  `MCP Server: Started. Waiting for messages. Working directory: /Users/dev`,
  exit 0.
- *`bin/init.sh` writes all aliases.* It used to emit `: "${MAC_HOST:=$HOST}"`
  from a single `--host`. `--host` now accumulates, repeated or as one quoted
  list. `--detect` probes every alias and prints which answered; detection then
  uses the first that answered. The write path picks one alias the same way for
  the JDK and `maestro` lookups, and skips both when none answers, because
  `_javahome` with no argument answers about the local machine and would write a
  Linux JDK path into a Mac's conf. Three tests: both `--host` spellings, and
  that an unreachable Mac leaves `RJAVA` unset.
- *What the server does when it cannot reach the Mac.*
  `bin/unreachable-mcp.py` (74 lines, the same stdio loop as `bridge-mcp.py`):
  `mcp.sh` execs it instead of exiting. It answers `initialize`, lists one tool,
  `why_unreachable`, and returns the reason from every `tools/call`, so a caller
  that guesses a Maestro tool name gets the reason, not a protocol fault. The
  message `_pick_host` writes to stderr is passed on argv, so the aliases tried
  and the conf path travel with it. It is not a retry and not a proxy:
  answering `tools/list` with the Maestro tool set would advertise tools that
  cannot run, and lazy connection would mean proxying stdio for the life of the
  session. The message says to restart the session. Four tests: the three calls
  a client makes before it can show anything are each answered, and the reason
  names the aliases.

**To do.**

- *Probe time.* Three aliases and no Mac is three probes at `PROBE_FAST` then
  three at `PROBE_SLOW`: up to 69 s before `_pick_host` gives up. The server now
  explains itself after that wait, but the wait remains.
- *Half-written conf.* `config.sh` refuses a conf missing `MAC_FQDN` and exits
  before any of `mcp.sh`'s code runs, so it still shows as `CONNECTION_CLOSED`.
- *Whether the server should read the project conf at all.* It is spawned once
  per session, before any project is in view, and `config.sh`'s search walks up
  from `$PWD`, which for a server Claude Code spawns is wherever the session
  started. `maestro-bridge` takes no conf and starts a helper the conf then
  points at; `mcp.sh` could work the same way.
- *Whether it is still called `maestro-mac`.* Under local or bridge transport it
  never touches a Mac. It sits here rather than in item 98 because the
  decisions above may restructure or retire the server. Renaming changes the
  tool names to `mcp__maestro-drive__*`, so anything matching
  `mcp__maestro-mac__*` must accept both prefixes first. `uninstall.sh` deletes
  `.mcpServers[$MCP_NAME]` and knows only the current name (`manifest.sh`:
  `MCP_NAME="maestro-mac"`), so a rename without a legacy sweep in
  `manifest.sh` leaves the old entry in `~/.claude.json` pointing at a script
  that no longer exists.

## 93. `flutter-hot-reload-mac` carries its own Flutter answers, and they are worse — **OPEN**

**What.** Split out of item 87 (its Stage 5.3). The work is in the
`flutter-hot-reload-mac` repo; it is filed here because the seam it should plug
into is here. The sister skill installs alongside this one, reads the same
`.maestro-drive.conf`, and builds from source, launches under `flutter run` and
pushes edits as hot reloads. It hardcodes defaults where this package
discovers them from the same conf:

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

Its `inspect` equivalent is its own VM Service discovery in `frun.py`, reading
`/tmp/frun.log`, which `runners/flutter/vmservice.sh` also checks by name: two
implementations of one answer.

**Why.** `lib/main_dev.dart` is hardcoded as the entrypoint. This package
derives it from the bundle id under test and refuses when two flavours build
the same one, because building the wrong flavour installs a different app and
leaves the one under test untouched, and nothing reports it. A project that is
not `dev`-flavoured gets the right answer from one skill and the wrong one from
the other, from the same conf. Separately (item 24), `bin/start.sh` runs
`git checkout` on the single shared `$REPO`, so pointing it at a review branch
overwrites uncommitted work in anything else using that checkout; that is a
safety requirement for concurrent reviews.

**To do.** Make `flutter-hot-reload-mac` consume this package's runner verbs —
`describe`, `build` and `inspect` — instead of its own defaults. Then hot reload
for another framework becomes a runner module rather than a second skill, and
two skills reading one conf cannot disagree about which flavour a project
builds.

**Gated on.** Item 87 landing, so the contract is stable.

## 90. The wall shows simulators only, and a phone is a device too — **OPEN**

**What.** `bin/wall.sh` puts every booted simulator on one live page. A
physical iPhone driven through `runners/ios-device` does not appear on it.

**Why.** The one device whose screen cannot be seen from the desk is the one
the wall omits.

**To do.**

- *Ask every platform module.* `remote/wall.py` resolves
  `runners/<PLATFORM>/platform.sh` from the environment and calls
  `devices --booted` on it. A Mac with three simulators and a phone has two
  platforms live at once, so the wall must ask every module it finds, merge the
  answers and tag each row with its module. This is the first place in the
  package where platform stops being one choice per session.
- *Find out whether a phone can be streamed or only sampled.*
  `runners/ios-device capture-cmd` exits 2 with "not established for a physical
  device". Known so far: `devicectl device capture screenshot` works on the
  phone (6.7 MB PNG, about one second) — a poll, not a stream.
  `devicectl device capture screen-record` records to a file, the wrong shape
  for a tile that must start before anyone watches and survive the browser
  closing. Whether Maestro's `simulator-server` drives a physical device is
  untested; it takes a platform word (`ios` for a simulator) and no other has
  been tried.
- If only sampling works: the wall's `Stream` class assumes MJPEG frames from a
  child process, so a polled tile is a separate class beside it, not a
  parameter. A phone tile that updates every few seconds is still useful, and
  the tile should say it is polled rather than look live.

**Gated on.** Finding something that can stream a physical device's screen.
Item 87 built `runners/ios-device` and left `capture-cmd` unanswered for this
reason.

## 87. Flutter and iOS are wired in, not plugged in — **OPEN**

**What.** The driving half of the package does not depend on what built the
app: `driver.sh`, `drivers.sh`, `flow.sh`, `img.sh`, `wall.sh` and the journey
tooling are written against Maestro and XCUITest. The other half — getting an
app onto a device and inspecting it while it runs — was Flutter and iOS
throughout and not separated from the generic half. Reading the files (a
`grep -ciE 'flutter|dart|pubspec'` overcounts with comments, and misses
`bin/prefs.sh`, whose default filter is `flutter` because
`shared_preferences` prefixes every NSUserDefaults key), eight files hold
Flutter logic: `remote/build.sh`, `remote/vmservice.sh`, `bin/net.sh`,
`bin/publish.sh`, `remote/net.py`, `remote/gitstate.sh`, `bin/preflight.sh`,
`bin/prefs.sh`. Platform (`xcrun`, `simctl`, XCUITest) was wired into
`remote/wall.py`, `remote/build.sh`, `bin/driver.sh`, `remote/deviceup.sh`,
`bin/drivers.sh`, `remote/driverup.sh` and others. Nothing mentioned `adb`, an
emulator or Android: Android was absent, not half-done.

**Why.** Driving a React Native app, or a plain Android or iOS one, would mean
forking the package or teaching every one of these files a second way to do
its job. Everything expensive — the rig, the wall, the journey tooling, the
driver lifecycle, the SSH and network side — is in the half that already
generalises; a fork would copy all of it to change `build.sh`. A package that
names its runner also makes the build-skill/drive-skill split (item 82)
structural.

**Done.**

*The seam.* Two axes, two modules. Framework (`flutter`, `react-native`)
decides how the app is built and inspected; platform (`ios`, `ios-device`,
`android`) decides how it is installed and driven. A single
`RUNNER=flutter|react-native|ios|android` cannot work, because Flutter and
Android are both true at once. `ios` and `android` also answer the framework
questions for an app with no framework above the platform. A module is one
POSIX `sh` script per axis, dispatching on its first argument. **Exit 2 means
"this module does not have that verb"** and is not a failure: it lets `net.sh`
say "native apps have no traffic endpoint" instead of "the relay is broken".

- framework verbs: `claim describe variants variant-for-appid build residue
  devsession inspect traffic-arm traffic-list traffic-one prefs-prefix`
- platform verbs: `claim devices boot shutdown install container data-container
  prefs-read prefs-flush orientations screenshot driver-up driver-down
  driver-scan capture-cmd`, plus `last-used`, `uninstall`, `locked`,
  `installed-info` added below

Files: `skill/runners/README.md` (the contract and the seven call sites),
`runners/TEMPLATE/`, `runners/flutter/framework.sh`, `runners/ios/platform.sh`,
`runners/react-native/framework.sh` and `runners/android/platform.sh` (stubs;
each verb says whether it is documented-not-measured or unanswered),
`bin/runner.sh` (dispatcher: `which`, `path`, `rpath`, `detect`).
`bin/config.sh` gains `RUNNER=flutter` and `PLATFORM=ios`. `bin/install.sh`
pushes `runners/` to `$RDIR`.

*Call site 3, `bin/build.sh`.* Two SSH calls: `framework.sh build` prints
`artifact <path>` back to this side, then one `platform.sh install` loops over
the target devices on the Mac. `platform.sh claim` replaces the UUID-shape
test, `platform.sh devices --booted` replaces the inline `simctl` parse behind
`--all`, `framework.sh describe` answers `--detect`, and
`--install-only <path>` is new; `--no-install` passes `--build-only` through.
The build script prints `artifact <path>` and gains `--build-only`; the
simulator install is `_install_sim`, and on the physical-device path
`--build-only` emits only the build half of the GUI-session script. Five tests.
Merging the two calls would save 0.35 s against a 36 s incremental build and
would leave the artefact path on the Mac; keeping it here lets any later
install skip the build (a simulator booted after the build, a reinstall after
`simctl erase`, an uninstall to test first launch, a replaced driver or
device). A no-op build is 21–22 s, not zero: Xcode re-runs Flutter's script
phase every time and about 9 s goes on `pub get` resolution before Xcode
starts. Measured: `--install-only` 3 s against 25 s for build-and-install; with
two simulators, `--all --install-only` 23 s against 88 s. Build timeouts are set
per platform in `bin/build.sh` (`BUILD_TMO`, default 1500 s for `ios-device`
and 900 s otherwise; the physical-device build caps its own poll at 1200 s).

*Stage 1, five call sites.*

- 1.1 `bin/preflight.sh` passes `RESIDUE_GLOBS=$(framework.sh residue)` into
  the remote call before sourcing `gitstate.sh`, which keeps its default of
  five patterns for standalone use and tests.
- 1.2 The three `DEVSESSION_*` variables come from `framework.sh devsession`,
  folded into preflight's one SSH call. `RUNNER=react-native` makes preflight
  name Metro and say the app may not start, rather than `flutter run`.
- 1.3 `bin/publish.sh` uses `framework.sh inspect` and `traffic-arm`. A
  framework whose `inspect` exits 2 makes it say there is no debug endpoint,
  not that the relay failed. `relay.py`, the state file and the per-device
  suffix are unchanged.
- 1.4 `bin/net.sh` uses `traffic-list` and `traffic-one`, keeping the
  fast-path/SSH-fallback choice and `_explain_empty` ("the app made no calls"
  and "capture was never armed" look identical). The `traffic-*` verbs run
  locally through `$grpc_proxy`; every other verb runs on the Mac.
  `runner.sh framework` handles the local side, `runner.sh rpath` the remote
  one; a verb invoked on the wrong side fails as a network error. The module
  addressed `net.py` as `$RDIR/net.py`, a Mac path, so only the SSH fallback
  worked; it now runs `$HERE/net.py`.
- 1.5 `bin/prefs.sh` uses `platform.sh data-container`, `prefs-read` and
  `prefs-flush`, and takes its default filter from `framework.sh prefs-prefix`;
  a framework with no prefix reads every key.

*Stage 2.1, platform verbs against booted devices.* `boot`, `driver-up`,
`driver-scan`, `devices --booted`, `install`, `container`, `orientations`,
`data-container`, `prefs-flush`, `prefs-read`, `screenshot`, `capture-cmd`,
`last-used`, `uninstall`, `driver-down` and `shutdown` ran through their real
callers. With two simulators: `drivers.sh down <udid>` stops one driver and
leaves the other; `drivers.sh up <udid>` brings it back on the same port
(22088), the per-device ports map on the Mac holding across a restart;
`build.sh --all` does one build and both installs in one round trip. This
found item 88: the live-driver guard on the wall's label reclaim was a `$( )`
inside a double-quoted `_ssh` string, expanded locally, with field references
escaped for the Mac, so awk failed and the guard never fired. The reclaim tests
reimplemented the logic in shell; the new test reads the shipped file.

*Stage 3, call site 7 (seven files).*

- `lib.sh`: `_dev` and `_driver_scan` call `devices --booted` and
  `driver-scan`. Module paths are plain strings in `lib.sh`, because
  `runner.sh` sources `lib.sh` and every `_dev` would otherwise pay a
  subprocess.
- `drivers.sh`: six call sites. `rig reap`'s freshness probe walked
  CoreSimulator's per-app data containers two levels deep for an mtime,
  because a container's own mtime moves only when its immediate contents
  change. It is now `last-used`: `<id>|<yyyymmdd>|<human>|<today>` for every
  booted device in one call, with today's date from the device's host so clock
  skew cannot reap a live device. Android's `last-used` is under *Android
  `last-used`* below.
  `platform.sh boot` waits for the device; `drivers.sh` then waits for the
  machine, which decides whether the next boot or driver start survives.
- `shot.sh` and `flow.sh`: the screenshot calls.
- `wall.py`: used the runtime only to sort, so `devices` gained an optional
  fourth column carrying it, in the same text format. No `simctl`, `XCRUN` or
  `SIMSERVER` remains. The module reads `simctl … -j` with python, because the
  human listing puts the runtime on a heading line above its devices.
- `preflight.sh`: `container` and `orientations`. `orientations` takes the
  container, not the device: it reports what the installed build declares,
  which differs from what the device supports for a landscape-locked app on a
  natively portrait iPad.
- `driver.sh`: two new verbs. `uninstall <id> <app-id>` for `clearstate` —
  removing the app removes its data, giving a first-launch app; an absent app
  is not a failure. `locked <id>` returns 0 locked, 1 not, 2 not applicable;
  `devicectl` returns nothing for a simulator udid, so a simulator gets 2 and
  the caller need not know the device kind. The lock stubs in the tests now
  answer by status.

Nothing under `bin/` calls `xcrun`, `simctl` or `devicectl`; matches left are
comments in `build.sh` and `driver.sh`.

*Stage 4, contract decisions.*

- 4.1 `boot` prints the id it booted as its last line. On a platform where the
  id changes on boot, the `devices` id column means the id to act on the
  device in its current state: a shut-down emulator lists under its AVD name, a
  running one under its serial. `runners/ios` echoes its argument.
- 4.2 `variants` and `variant-for-appid` take an optional `--platform <p>`. A
  Flutter `--flavor` builds both platforms, so the Flutter module ignores it;
  React Native's iOS schemes and Android product flavours are two lists. The
  caller always knows its platform (`bin/build.sh` has `PLATFORM`), and an app
  id is itself per-platform.
- 4.3 Superseded: instead of an Android `container`, `platform.sh
  installed-info` reports what a platform can say and `appcheck` reasons from
  whatever arrives, so an absent key is a fact rather than a failure. Android
  answers `version`, `build` and a timestamp through `dumpsys package`.
  Written, not measured.
- 4.4 Android driver questions answered against Maestro 2.10.0 and
  `Pixel_6_Pro_API_34` over item 96's bridge. The port can be chosen per run:
  `maestro --driver-host-port <n>` is a global option, absent from
  `maestro --help`, present in `App.class` beside `--host` and `--port`;
  `DEFAULT_DRIVER_HOST_PORT = 7001` in `maestro/android/AndroidDeviceConnection`;
  it is validated at startup (`--driver-host-port 1` prints
  `Requested driver host port 1 is not available`, exit 1; 7099 runs the flow,
  exit 0). The APKs `maestro-app.apk` (11.7 MB) and `maestro-server.apk`
  (0.9 MB) are inside `maestro-client.jar`, not `~/.maestro/deps`; they install
  as `dev.mobile.maestro` and `dev.mobile.maestro.test` for a run and are gone
  from `pm list packages` afterwards. `adb forward --list` stays empty during a
  flow and no host socket appears on 7001 or 7099: Maestro reaches the device
  through dadb, so `driver-scan` on Android cannot be `adb forward`.
- 4.4 The three verbs, measured on `Pixel_6_Pro_API_34` and `Small_Phone`
  running at once. Android has no standing driver, so the ports map has no
  Android half:
  - The port is the device's. `AndroidDriver` starts
    `am instrument … -e port <n>`, the emulator's `/proc/net/tcp6` showed 7101
    listening for `--driver-host-port 7101`, and the host connects through one
    adb stream per socket (`AdbSocketFactory`).
  - Two emulators ran flows side by side, both passing. Without
    `--driver-host-port`, `maestro test` picks a free port per run (37131,
    42439, 35277, 43091), not 7001.
  - One emulator holds one run. A second run on it took the driver, and the
    first failed with `DeviceServerDiedException … Command failed (tcp:7101)`.
  - The driver process appears about 20 s into a run and is gone, with both
    APKs, when the run ends.

  `driver-up` exits 2 saying so: a driver started ahead of a flow would be
  replaced by the flow's own, and nothing here speaks its gRPC protocol.

  `driver-scan` prints `<serial> <port> <pid>` per `maestro.cli.AppKt` process.
  The command line comes first, and the run's `maestro.log` (found through
  `/proc/<pid>/fd`, or `lsof` where there is no `/proc`) fills in what it left
  open. Two runs started in the same second share one `~/.maestro/tests/<time>/`
  log, and reading only the log gave both processes the same device.

  `driver-down` sends TERM to the device's runs and waits up to 10 s. It then
  force-stops `dev.mobile.maestro`, uninstalls both APKs and deletes the
  device's `ANDROID_<serial>_*` lines from `~/.maestro/sessions`. Measured
  without that cleanup:
  - TERM left both APKs installed.
  - TERM also left the session record. Maestro counts a record as live for
    21 s after its last heartbeat, so the next run on the device skipped
    starting a driver and failed in 2 s.

  With the cleanup, a run started straight after `driver-down` passed, and the
  other emulator's run was untouched. Five offline tests.

  `lsof` on macOS is not measured.

*Android `last-used`.* The date is the device's last touch or key input:
PowerManager's `mLastUserActivityTime` in `dumpsys power`, in uptime
milliseconds, turned into a time on this machine's clock. Three candidates were
measured on `Pixel_6_Pro_API_34`:
- The userdata qcow2's modified time moves whenever the emulator writes
  anything.
- `dumpsys usagestats` `lastTimeUsed` moved for the launcher and Settings on an
  emulator nobody touched for a minute. Settings' `lastTimeVisible` equalled
  the moment of the read.
- `mLastUserActivityTime` held still across 90 s idle and three reads. It moved
  on one `adb shell input tap` and on a Maestro `tapOn` (326361 → 455696 ms).
  The line is the same on API 36 (`Small_Phone`).

Boot sets it: a fresh API 36 boot read 53667 at 54.3 s uptime. So a device
nobody has touched reports its boot time. A flow of `launchApp` and assertions
sends no input and does not move it, as an iOS flow that writes nothing does not
move the container walk.

Live, `drivers.sh rig reap` listed both emulators with their last input time
(16:06 and 16:07) and kept them as used today. One offline test checks that a
device touched 27.8 h of uptime ago gets a day other than today.

*Stage 5.*

- 5.1 `SKILL.md` explains what a runner is and why there are two settings:
  everything Flutter or iOS in the rest of the file is one runner's answer. The
  dev-session step warns that no Metro is not the same as no `flutter run`.
  `--detect` is named as the framework's `describe`; `bin/runner.sh` is in the
  tool table.
- 5.2 `bin/init.sh` runs `runner.sh detect` when given a REPO and writes what
  claimed it; without one it writes the default and says it is a default.
  `PLATFORM` is `ios`, with the reason that nothing is booted yet. The
  gitignore advice covers `.maestro-drive.conf.*`, where a credential lives in
  a two-environment project.
- 5.3 Moved to item 93.
- 5.4 `remote/` keeps only shared code. `build.sh`, `vmservice.sh` and
  `net.py` are in `runners/flutter/`. `variants` and `variant-for-appid` had
  reimplemented the build script's flavour rule (a flavour is real only when
  both an xcscheme and `lib/main_<f>.dart` exist); `build.sh` gained
  `--list-variants` and `--variant-for`, and against a seven-flavour repo the
  verbs list six flavours and narrow an app id to exactly one.
  `runners/ios-device/` holds `platform.sh`, `deviceup.sh` (the usbmux
  forwarder and tunnel wake) and `iproxy.py`.

*Flutter module verified end to end.* Every verb has run live: `claim` against
sixteen checkouts; `describe`, `variants` and `variant-for-appid` against the
seven-flavour repo; `build`, `residue`, `devsession`, `prefs-prefix`; `inspect`
in both failure modes and in success; `traffic-arm` in both states;
`traffic-list` (`GET /v1/users → 200`, `/v1/chats → 401`) and `traffic-one`
(headers and body, `user-agent: Dart/3.11 (dart:io)`). The login journey reads
`${APP_PIN}` from the conf, so the run log shows the variable name, not the
value, and `bin/secrets.sh check` reported no project value in any tracked
file.

*2.2, React Native on Android.* Written against `oneiota-products-rn`
(`~/claude-sandbox`): Expo 58, React Native 0.88, a prebuilt `android/`, no
`ios/`, no product flavours, app id `dev.sandbox.oneiotaproducts`. iOS was the
plan; the checkout decided Android. `claim`, `describe`, `variants`,
`variant-for-appid` and `build` are written for Android and exit 2 on iOS.
`runners/react-native/project.py` does the two parses: the node to build with,
and flavours and app ids out of `build.gradle`.

- Node: the default on `PATH` is nvm's v14.21.3 and React Native 0.88 needs
  `^22.13.0 || ^24.3.0 || >= 26.0.0`. A repo `.nvmrc` or `.node-version` wins
  when nvm has it; otherwise the newest nvm node the range accepts (v22.21.1).
  Gradle's autolinking step runs node, so the wrong one fails inside Gradle.
- The artefact is the file `output-metadata.json` names in the variant's own
  output directory, not a glob. No mtime check: a no-op build leaves the APK
  untouched and it is still current.
- `bin/build.sh --detect` reports the RN project and `--no-install` printed
  `artifact …/android/app/build/outputs/apk/debug/app-debug.apk`, through the
  bridge (item 96), because the Bash sandbox blocks writes to the checkout and
  `~/.gradle`. Cold build: 13 m 49 s, 460 of 488 tasks executed, a 242 MB debug
  APK. `bin/build.sh` now copies its output to `$LDIR/build.log`.

**To do.** Quickest first; each says what it waits on.

- 6.1 **Done.** Offline tests for `project.py`: gradle fixtures with flavours,
  `applicationId` and suffixes per flavour and build type, and node ranges.
  Eighteen cases, including `build` against a stub `gradlew` that records its
  task, which catches the `assembleD<newline>ebug` bug.
- 6.2 **Done.** `version <repo> [--platform <p>]` returns the named
  platform's `<version>+<build>`, as `variants` takes `--platform`; Flutter
  ignores the flag and `bin/preflight.sh` passes `$PLATFORM`. Android reads
  `versionName` and `versionCode` from `build.gradle` (`1.0.0+1` for
  `oneiota-products-rn`), not `package.json` or Expo's `app.json`. Half a
  pair exits 2. A flavour's own values are not used: the verb has no app id.
  Android `installed-info` prints `when=<date>` and `appcheck` reads
  `epoch=<seconds>`, so on Android this version comparison is the only check
  that fires.
- 6.3 **Done.** `devsession` against a running `expo start` (node v22.21.1,
  through the bridge). The old `pgrep` pattern (`cli.js start\|metro`) said
  "none" beside a running Metro: Expo's processes are `npm exec expo start` and
  `node …/node_modules/.bin/expo start`. The verb now asks Metro: `GET
  :$RCT_METRO_PORT/status` (8081 unless set) answers `packager-status:running`.
  A process match names it, through `ps`, because `pgrep -l` prints only
  `node` on Linux; with no answer on the port it says a Metro process is
  running elsewhere. Two offline tests stub `curl`. `CI=1 expo start` disables
  reloads.
- 6.4 **Done on an emulator.** `drivers.sh rig up Pixel_6_Pro_API_34` booted
  `emulator-5554` in 1 m 50 s; `build.sh --install-only` put the 242 MB debug
  APK on it in 18 s; `am start` reached `MainActivity` in 1.7 s. With
  `adb reverse --list` empty, Metro logged `Android Bundled 12059ms` and the
  product list rendered about 16 s after launch (blank before that). An
  emulator needs no `adb reverse`: React Native's debug default on an emulator
  is the host alias 10.0.2.2:8081. A physical Android device still would;
  not measured. Two wrong lines from `rig up` on Android: "starting on 22087
  (about 30s)" before `driver-up` exits 2, and "carrying on at load unknown
  after 0s".
- 6.5 **Done, and the AsyncStorage half cannot be answered with this app.**
  `prefs.sh` and `prefs.sh --all` ran end to end on `emulator-5554` and print
  the same thing: two XML documents back to back, with no file names.
  `shared_prefs/` holds `WebViewChromiumPrefs.xml` (`lastVersionCodeUsed`) and
  `expo.modules.kotlin.PersistentDataManager.xml` (empty), both left by SDKs.
  Neither is the app's. `oneiota-products-rn` depends on no storage library (no
  AsyncStorage, SecureStore, SQLite or MMKV), and there is no `databases/`
  directory, so where AsyncStorage's keys land is still not measured. `files/`
  holds the 5.9 MB `BridgelessReactNativeDevBundle.js` Metro served. Still to
  do: `prefs-read` concatenates every `shared_prefs/*.xml` without naming them
  (its own comment counts 28 files for a Flutter app), and a React Native app
  with AsyncStorage needs its SQLite store read (`databases/RKStorage` by
  AsyncStorage's own documentation; not seen here).
- 6.6 **Run; `flow.sh` cannot run these flows, and two fail on a debug-build
  toast.** `flow.sh -f flows/01-product-list.yaml` failed with
  `Invalid File Path at …/_adhoc.yaml:6:3`: it copies the flow's body alone,
  so the `runFlow: ../subflows/launch.yaml` every flow starts with has nothing
  beside it. (Before that, `$RDIR/flows` did not exist under the bridge until
  `install.sh` ran.) `maestro --device emulator-5554 test maestro/` in place
  ran all six in 3 m 17 s: product list, detail, basket and load-error retry
  pass; recently viewed and out of stock fail. Both fail on the same thing.
  The debug build's LogBox toast "Open debugger to view warnings" (raised by
  the app's own `unstable_settings.initialRouteName` deprecation) sits at
  [35,2782][1405,2949] after every `clearState` launch. `scrollUntilVisible`
  stops with the target at the bottom edge, and Maestro counts it 100%
  visible underneath the toast: the taps at (720,2898) on `product-card-8` and
  (456,2783) on `recently-viewed-item-1` hit the toast and the screen did not
  change. Confirmed: with `launch.yaml` closing the toast first (a tap on its
  X at 92%,92%, in a scratch copy), both flows passed, in 36 s and 21 s.
  Still to do: `flow.sh -f` runs a flow in place, or ships its directory,
  when the flow refers to other files.
- 6.7 **Done.** `inspect` reads Metro's `/json/list` on `RCT_METRO_PORT`
  (8081 unless set, the port devsession asks) and prints
  `ws://127.0.0.1:8081/inspector/debug?device=…&page=1 <target id>`; a CDP
  `Runtime.evaluate` over that URL answered from Hermes. Measured:
  - The inspector proxy returns 401 with no Origin. With Origin
    `http://localhost:8081` it accepts the upgrade and drops the session
    (1006) before a message reaches the device, in both Node's WebSocket and
    the `ws` package. URL and Origin on 127.0.0.1 work; a client must send it.
  - The target id and URL stayed the same across CDP `Page.reload` and an app
    force-stop and restart, and kept answering; only the runtime was new (a
    global counter went back to 1). After a force-stop the list is empty
    within 2 s. So nothing is cached: the list is read every call.
  - Metro's `POST /reload` answered 200 and reloaded nothing, with or without
    `CI`; `Page.reload` reloaded. `CI=1 expo start` prints that reloads are
    disabled; `CI=` (empty) fails with `GetEnv.NoBoolean`; `CI=false` works.
  - Exit 1 for no Metro, for Metro with no app connected, and for two targets
    of `APP_ID` (it lists them and does not guess; matching a target to a
    serial is not written). Five offline tests stub `curl`.
  - `publish.sh` against React Native: `start` brings the relay up (9100 to
    8081; `/json/list` read through it from the sandbox) and writes the state
    file, but its report is Flutter's. It prints `profiling unknown (could not
    be set …; net.sh may come back empty)` where `traffic-arm` exited 2, and a
    by-hand line of `curl "$BASE/getVM"`. `status` says "not reachable — the
    app has probably restarted" with the relay up and the app connected, and
    `net.sh` says "no relay published": both test the relay with the Dart VM
    Service's `getVersion` (`bin/publish.sh` `_vm`, `bin/net.sh:63`). `net.sh`
    then exits 2 with React Native's own "no in-runtime HTTP capture" text,
    which is right. **Fixed:** a framework verb `alive <base> <session>`
    answers the liveness question (Flutter: `getVersion`; React Native: the
    session id in `/json/list` on the base's host and port; TEMPLATE exit 2),
    and `publish.sh` status, its by-hand line and `net.sh` ask it. `start`
    reports a `traffic-arm` exit 2 as `profiling none (the react-native runner
    has no in-runtime HTTP capture …)`. Live: `status` said reachable, then
    not reachable 3 s after a force-stop, then reachable after the app came
    back; `net.sh` took the relay path and exited 2 with React Native's text.
    Five offline tests.
  - Through the relay (9100), a CDP evaluate run on the device's machine
    answered with Origin `http://127.0.0.1:8081`; the relay's own Origin
    `http://192.168.4.39:9100` got 401, and no Origin failed. From the
    sandbox, Node's WebSocket cannot reach the relay at all (ENETUNREACH):
    unlike `curl`, it does not go through the sandbox's HTTP proxy.
- 6.8 Traffic. **CDP route done; proxy route open.** `traffic-arm` starts
  `runners/react-native/recorder.cjs` (Node 22, detached) on the device's
  machine, attached to `inspect`'s socket; it writes each finished request,
  with headers and body, to `$RDIR/rn-net/<session>/traffic.ndjson`, and
  reconnects every 2 s after an app restart. `traffic-list`, `traffic-one`
  read it; `traffic-disarm` (new, exit 2 for Flutter and TEMPLATE) stops it.
  Given the relay's base the verbs exit 3, a new contract code meaning "run
  on the device's machine": `publish.sh` then arms over SSH against the base
  `inspect` reported (kept in `$STATE.device`) and disarms on `stop`;
  `net.sh` takes its SSH path. Live on `emulator-5554`: `publish.sh start`
  said `profiling on (was off, now on …)`; after a `Page.reload`, `net.sh`
  listed the symbolicate POST and `GET 200 …/products.json`, and `net.sh
  <id>` printed the whole JSON body; `publish.sh stop` left no recorder.
  Six offline tests.
  - **Proxy route, measured by hand; no verbs yet.** HTTP Toolkit's server
    (1.26.1, `~/.local/share/httptoolkit-server`) started headless with
    `start -c ~/.config/httptoolkit --token <ours>`, the desktop app closed.
    Its Mockttp admin API (45456, Origin `https://app.httptoolkit.tech`)
    started a session with `recordTraffic: true` on port 8000;
    `POST /interceptors/android-adb/activate/8000` (45457, Bearer token)
    rooted `emulator-5554`, injected the CA into the system store, installed
    its app (v1.7.0) and set `adb reverse tcp:8000`. Four things it needed:
    - The app checks the proxy through `http://android.httptoolkit.tech/config`
      (JSON `{certificate: <PEM>}`) and `http://amiusing.httptoolkit.tech/certificate`,
      which HTTP Toolkit's UI answers. A pass-through rule sent them to the
      internet and the app said it could not connect; two rules answering
      them with `ca.pem` fixed it.
    - Android's VPN consent dialog (OK) and a notification prompt, tapped
      through Maestro.
    - The VPN carries the app's Metro traffic, to 10.0.2.2:8081, which means
      nothing on the host: the app stayed blank. A rule forwarding
      `10.0.2.2:8081` to `127.0.0.1:8081`, for HTTP and WebSockets
      (`forwarding: {targetHost}`), let the bundle load.
    - OkHttp's disk cache answered `products.json` on a plain relaunch, so
      nothing reached the proxy; a `clearState` launch sent it.
    Then `mockedEndpoints { seenRequests }` listed the decrypted
    `GET https://…/products.json`, nine expo-image requests (its own client,
    which the CDP route never sees) and another app's analytics POST (the VPN
    is device-wide). With Metro restarted without `EXPO_PUBLIC_USE_RN_FETCH`
    (bundle 1299 modules, against 1322 with it), a `clearState` launch's
    `products.json` was recorded too. Against: with the VPN up, the app's
    inspector WebSocket reached the proxy (three recorded) but Metro listed
    no target, so the two routes do not run together yet. `seenRequests`
    holds requests only; responses need the `responseCompleted`
    subscription.
  - The inspector through the VPN, two causes. The WebSocket rule's rewrite
    was ignored: `ws-passthrough` takes `transformRequest: {replaceHost:
    {targetHost}}`, not the HTTP step's `forwarding`, and with it a probe
    upgrade through the proxy registered with Metro (`Got new device
    connection … via=http://127.0.0.1:8081`). Then the app itself did not get
    that far: on two relaunches the VPN reset the bundle download (`Sent RST
    Packet … 192.168.4.39:8000`, the app at "Downloading 10.2%"), where two
    earlier launches through it had loaded. So both routes at once is still
    not measured.
  - Why the VPN drops connections, not found. HTTP Toolkit's Android app
    reaches the proxy at the LAN address (192.168.4.39:8000), not through
    `adb reverse`. On the next launch the bundle loaded, and the app's
    inspector WebSocket registered with Metro through the proxy
    (`via=http://127.0.0.1:8081`), then closed after 16.0 s with code 1005
    and did not come back; a direct one, VPN off, had lasted 5 min. Around
    it the VPN logged `closed session` then `Ack for unknown session … Sent
    RST`: it drops sessions and resets the app's next packet. Metro served
    every bundle in about 65 ms and the proxy logged no error.
  - The proxy alone, VPN off, emulator untouched: on a fresh session with the
    same rules, the first WebSocket upgrade to `10.0.2.2:8081/inspector/device`
    through it (curl `-x`) got `101` and registered with Metro; every upgrade
    after it on that session (curl three times, the `ws` package in both
    request forms, a raw socket) got no answer at all, while plain HTTP
    through the same proxy (`/status`, `example.com`) kept answering. So
    Mockttp, as driven here, forwards one WebSocket and stalls the rest. That
    fits the app: its first inspector connection got through, and after it
    closed none of its reconnects did. Not known: why the first closed after
    16 s.
  - The stall is the host rewrite. Fresh session each, four curl upgrades
    each, every one closed by curl after 4 s: to `127.0.0.1:8081` with a
    plain `ws-passthrough`, 4 of 4 reached Metro; to `127.0.0.1:8081` with
    the `replaceHost` rule (a no-op there), 4 of 4; to `10.0.2.2:8081` with
    the rule rewriting it to `127.0.0.1:8081`, the first reached Metro and
    the next three got no answer. Likely the rewrite is applied to the first
    upgrade only and the rest dial 10.0.2.2, which the host cannot reach; the
    proxy logged no timeout inside 4 s, so that is not confirmed.
  - **Pointing the app at Metro's LAN address removes the rewrite, and both
    routes then ran together.** The app's `debug_http_host` preference
    (`shared_prefs/<app-id>_preferences.xml`, read by
    `PackagerConnectionSettings`) set to `192.168.4.39:8081`; Metro listens
    on every interface. VPN off, the app loaded and registered
    `via=http://192.168.4.39:8081`. VPN on, with only pass-through rules
    (no rewrite) besides the two proxy checks: the proxy carried both bundle
    downloads, `/status`, `/symbolicate` and every Metro WebSocket; Metro
    registered three inspector connections in a row through it (the
    rewrite had stalled the second); the target was still listed after
    60 s; over it the CDP route got `requestWillBeSent` and
    `responseReceived` for an XHR to `products.json`, and the proxy recorded
    the same request, decrypted. Still failing: on the next relaunch the
    bundle download stalled at 2.6 %, and on that run the VPN reached the
    proxy at 100.111.114.95 rather than the LAN address. So the bundle
    stall is separate from the rewrite and from the address. This HTTP
    Toolkit app build also refuses to connect without notification
    permission (`pm grant … POST_NOTIFICATIONS` settles it). A `clearState`
    launch erases `debug_http_host`. Afterwards: HTTP Toolkit uninstalled,
    the preference removed, the emulator rebooted (CA gone), the app loads.
  Measured before the design:
  The stub's premise is out of date: React Native 0.88 implements
  the CDP Network domain (`jsinspector-modern/network`, ungated in a debug
  build), and Android's `NetworkingModule` reports every request to it. Over
  `inspect`'s socket, after `Network.enable`, an `XMLHttpRequest` in the app
  gave `requestWillBeSent` (URL, method), `requestWillBeSentExtraInfo`
  (headers), `responseReceived` (status, headers) and `loadingFinished`
  (7342 bytes), and `Network.getResponseBody` returned the body (base64
  JSON). The agent survived `Page.reload`: the app's own products request
  at launch came through.
  - Expo 58 replaces the global `fetch` with `expo/fetch`
    (`expo/src/winter/runtime.native.ts`), which reports nothing: a `fetch`
    completed with 200 and no event arrived. With
    `EXPO_PUBLIC_USE_RN_FETCH=1` in Metro's environment (inlined into the
    bundle; no native rebuild) the same `fetch` gave every event. That swaps
    the fetch implementation under test.
  - Events reach only a connected CDP client, so capture needs a recorder
    attached before the requests, not a read afterwards.
  - The proxy route: no mitmproxy on this machine; the app's only request is
    HTTPS; the AVD is `google_apis` and debuggable, so root is available for
    a system CA, which on API 34 lives in the conscrypt APEX.
- 6.9 iOS: `variants`, `variant-for-appid` and `build`. Needs the Mac,
  `expo prebuild` to create `ios/` in the RN checkout, `pod install` and a cold
  Xcode build.
- 6.10 Record the results of 6.1–6.9 here. Needs all of them.

## 107. The `MaterialApp.router` dropdown report has not been sent upstream — **OPEN**

**What.** `flutter-router-dropdown-repro/` reproduces, in 60 lines with no
third-party packages, an app built with `MaterialApp.router` reporting its whole
accessibility tree at 1/dpr once a `DropdownMenu` has been opened and closed.
`MaterialApp(home:)` does not. `DRAFT-ISSUE.md` holds a report written for the
flutter/flutter tracker and `UPSTREAM.md` records what is already there: the
root cause is flutter/flutter#100946 and an unmerged fix is
flutter/flutter#189686. Every existing report needs a `ReorderableListView` and
a drag; this trigger needs neither and affects the whole tree.

**Why.** Until Flutter fixes it, `resolve.py`'s scale correction is the only
reason taps resolve on any screen after such a dropdown closes, and item 100's
conversion of the setup screens to Maestro flows waits on it.

**To do.** Run the repro against Flutter 3.49 (item 100 measured the scale
fixed on the 3.49.0-0.1.pre beta) and against the #189686 patch. If the fault
is gone in 3.49, record that in `UPSTREAM.md` and close this item without
posting. If not, decide where the report goes (a new issue, a comment on
#189686, or a comment on #100946), replace the app-specific caption and
dropdown labels in `DRAFT-ISSUE.md` with generic ones, and post it once the
exact text is approved. Either way, when the item closes, move
`flutter-router-dropdown-repro/` out of this repo — it is a Flutter bug
reproduction, not part of the skill, and nothing installs or tests it.

**Gated on.** Approval of the exact text before anything is posted.

## 109. `wall.sh label <name> <udid>` labels the wrong device and reports success — **OPEN**

**What.** The usage is `label [<udid>] <name> [--group <g>]`. Passing the UDID
after the name — `wall.sh label "<release>: <ticket> iPad" EF266A1C-…
--group <project>` — labelled the `DEV` device (C61983AE, the
iPhone) with the text `<release>: <ticket> iPad EF266A1C-BB33-…` and
printed it as a success. Measured 21 Oct 2026.

**Why.** A wrong name on a shared wall is exactly what the label exists to
prevent, and the success line hides it unless it is read closely.

**To do.** When any trailing word matches a UDID, either take it as the target
or refuse with the usage line; never fold it into the name.

## 110. `script --steps '…' file.journey` swallows the file name into the last step — **OPEN**

**What.** `driver.sh script --steps 'expect "ID - 1927-92626"' 22-cancel-request.journey`
ran one step, printed `ok … expect "ID - 1927-92626" 22-cancel-request.journey`,
and never ran the journey. The same happened with `--steps 'expect "Item
Picked Up" 10' 19-deliver.journey`. Measured twice, 21 Oct 2026.

**Why.** It reads as a pass. The steps that were meant to change state (a
cancel, a deliver) did not run, and nothing said so.

**To do.** Either run trailing journey names after the inline steps, or refuse
when `--steps` is followed by anything.

## 111. The ambiguity refusal says "pass --index", and `tapon` refuses `--index` — **OPEN**

**What.** `resolve: /^Continue$/ matches 2 nodes; narrow the pattern or pass
--index`. `tapon "^Continue$" --index 0` and `--index 1` both die in
`resolve.py`'s argparse with `argument --index: expected one argument`; the
positional `tapon "^Continue$" 0` works. Measured 21 Oct 2026. Item 29 fixed
`--anyway` in the same position but not `--index`.

**To do.** Accept `--index N` in `_resolve`'s flag sorting, or make the refusal
say `tapon <pattern> <index>`.

## 112. Nothing stops a second session launching onto a device another session has labelled — **OPEN**

**What.** 21 Oct 2026, one iPhone 16 Pro (C61983AE): this session had labelled
it and was driving a branch build; a peer session, on another ticket, ran `flutter run`
onto the same UDID at 16:37 and again at 16:44, and SpringBoard logged
"Termination requested by simulator host" each time. The driver went with it
(`nothing listening on 22087`), the app came back as the other branch's build,
and the first symptom on this side was the tree turning into the home screen
mid-journey. `drivers.sh rig status` did show `BY cyan · d978fd3` against the
device; nothing read it before the launch.

**Why.** Two reviews of two branches on one simulator each look like the app
misbehaving. Finding the cause took the SpringBoard log, the Mac's process
list and `/tmp/p26-*.log`.

**To do.** A check the launch paths can call — `build.sh`, `drivers.sh up`,
and the hot-reload skill's `start.sh` — that refuses when the device carries
today's label from a different live session, naming that session. Cheap: the
label file is already on the Mac. A `PreToolUse` hook on `flutter run -d
<udid>` over `mac.sh`/`ssh` would catch the hand-launched case too.

The same check belongs on the paths that destroy another session's state
rather than replace its app: `simctl erase`, `simctl uninstall`, and
`drivers.sh` taking over a device's port or driver. The hook on Bash covers
those as well as `flutter run -d <udid>`. The rule exists today only as a
hugoboss-flutter-runner project memory that is missing from that project's
`MEMORY.md` index, so no session has loaded it, and no other project that
drives a simulator would see it even if one had.

## 113. The ssh transport only reaches a Mac; a remote Linux box with an Android emulator cannot be driven — **OPEN**

**What.** The Android runner works on the machine running the skill (items 94,
96), but over `TRANSPORT=ssh` the far side is assumed to be macOS.
`REMOTE_ENV` in `skill/bin/lib.sh:128` replaces `PATH` with
`/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.maestro/bin`, so `adb` and the emulator
from an Android SDK are not found unless they sit in `/usr/bin`.
`skill/setup/wizard.sh` is Mac-only: `systemsetup` for Remote Login, a launchd
plist for the fixed address, and `.local` mDNS names. Nothing has been run
against a remote Linux host. Windows has no POSIX shell for the `sh` scripts
short of WSL.

**Why.** An Android emulator needs KVM, and a Linux box with it is a cheaper
device host than a Mac. The runner modules already answer every Android verb
that can be answered; only the transport and the setup stand in the way.

**To do.** Add the Android SDK's `platform-tools` and `emulator` directories to
`REMOTE_ENV`, taken from a conf value that `bin/init.sh --detect` asks the
remote host for, as it does for `RJAVA`. Give the wizard a non-Mac path that
skips Remote Login, launchd and mDNS. Then drive an emulator on a remote Linux
host end to end and record what broke. Rename `MAC_HOST` and `MAC_FQDN`, or
alias them, once the remote is not always a Mac.

## 114. `lib/update-check.sh` is installed and nothing runs it — **OPEN**

**What.** `install.sh:84-88` copies `lib/update-check.sh` into
`~/.local/share/maestro-drive/` and `install.sh:233-235` records the installed
version with it. Its header describes a once-a-day check of the GitHub Releases
API, run in the background so an unreachable remote never holds up a session.
No hook, no `skill/` script and no MCP server calls it, and `manifest.sh`
registers nothing for it.

**Why.** A user who installed from the tarball never hears that a release is
out. `./update.sh --check` only answers when someone thinks to run it.

**To do.** Register a `SessionStart` hook in `manifest.sh` that runs the check
in the background, and have the skill say once per session when the state file
records a newer release. Or, if the check is not wanted, delete the script and
its two call sites in `install.sh`.

## 115. `remote-STALE-pre-skill/` is still tracked — **OPEN**

**What.** Five files at the repo root, `remote-STALE-pre-skill/`, are the
scripts as they stood before the skill was packaged. Their own README says
"Superseded — do not edit, do not run", and they refer to
`~/.claude/skills/maestro-remote-mac`, the package's old name.

**Why.** A reader new to the repo sees a top-level directory that looks like
part of the project. Git history keeps the files without it.

**To do.** `git rm -r remote-STALE-pre-skill/`.

## 116. `erase --all` locks the simulator's touch input for about twenty minutes — **OPEN, raised 26 Oct 2026**

**What.** `erase --all` posts `eraseText` with `charactersToErase: 9999`. The
driver turns that into one long synthesized key gesture, and while it runs
testmanagerd refuses every other gesture. Measured 26 Oct 2026 on iPhone 16 Pro
Max 6EA2EBFE (hugoboss-flutter-runner, a rename sheet holding 14 characters):
from 12:30:52 the simulator log shows `Error tapping: XCTDaemonErrorDomain
Code=21 … only one gesture can be performed at a time` for every tap and key,
and the app ignored all input until about 12:50. `driver.sh` reported `ok` for
the taps throughout. `drivers.sh up` on the device did not clear it: the lock is
in testmanagerd, not the driver.

**Why.** From outside it looks exactly like an app whose text field and buttons
have stopped responding. It cost about twenty minutes and nearly became an app
defect report.

**To do.** Make `erase --all` read the focused field's value length from the
hierarchy and erase that many characters plus a small margin, not 9999. When a
tap fails with Code=21, have `driver.sh` say so instead of printing `ok`.

## 117. A driver dies on an XCTest screenshot timeout and nothing says why — **OPEN, raised 26 Oct 2026**

**What.** The iPad Pro 11-inch (M4) EF266A1C driver ended four times in about
an hour on 26 Oct 2026 (hugoboss-flutter-runner, landscape app). Its log,
`/tmp/maestro-mac/drv/driver-EF266A1C-….log`, ends each time with
`testHttpServer : Failed to get screenshot: Timed out while requesting
screenshot.`, after which the test case fails and xcodebuild restarts with
"Interface orientation changed to Landscape Right". The wall's
`simulator-server` capture for the same device was running throughout. The
next `driver.sh` call says only that the relay did not answer, or that the
driver "is gone" and that Maestro runs destroy drivers, which was not the
cause: no Maestro process touched the device.

**Why.** The message points at the wrong cause, and the restart flips the
device to landscapeRight, so raw app-space taps then land on the wrong points
until `orient landscapeLeft` is sent again.

**To do.** When a driver has gone, have `driver.sh` tail its log and print the
last error line. After `drivers.sh up` on a device whose app is landscape-only,
restore the orientation the device had before.

## 118. Nothing stops screenshot-driven element finding or raw-coordinate taps — **OPEN**

**What.** Elements get found by reading a screenshot and tapped by raw x/y,
rather than by reading the view hierarchy and resolving with `tapon`, `find`
or `--index`. `skill/hooks/gate-journey-first.sh` bumps a raw `tap`/`swipe`
once per session and then lets every later one through, and nothing at all
fires on a screenshot: neither the maestro-mac `take_screenshot` tool nor
`shot.sh`. The rule lives in four hugoboss-flutter-runner project memories,
dated 21 Aug, 3 Sep, 15 Sep and 5 Oct 2026, and was broken again on 20 Oct.

**Why.** Project memories never reach the other projects that drive an app,
and four of them in one project have not held. A hook ships with the skill,
so every project gets it.

**To do.** A `PreToolUse` hook beside `gate-journey-first.sh` that denies the
screenshot calls (`take_screenshot`, `shot.sh`) and any driver call or journey
step that taps raw x/y, unless the view hierarchy was read earlier in the same
turn. The refusal says to read the tree and resolve with `tapon`, `find` or
`--index`. Decide whether it replaces the raw-tap half of
`gate-journey-first.sh` or sits beside it. Once it ships, the four memories
can be deleted.

## 119. `SKILL.md` does not say that driving and building are different skills — **OPEN**

**What.** The skill descriptions separate `maestro-drive` (drive an app that
is already installed) from `flutter-hot-reload-mac` (build and run from
source), but `skill/SKILL.md` says neither. The distinction is otherwise a
hugoboss-flutter-runner project memory missing from that project's
`MEMORY.md` index.

**Why.** A session that reads only the skill body, not its description, has
nothing telling it which skill to reach for, and no session loads the memory.

**To do.** One short section near the top of `SKILL.md`: what this skill does
not do, and which skill does it.

## 120. `flow.sh -f` cannot run a flow that `runFlow`s a file beside it — **OPEN, raised 26 Oct 2026**

**What.** `flow.sh -f <file>` sends the file's text to the device's machine
and writes it to `$RDIR/flows/_adhoc.yaml`; nothing else travels. Every flow
in `oneiota-products-rn/maestro/flows/` starts with
`runFlow: ../subflows/launch.yaml`, and `flow.sh -f flows/01-product-list.yaml`
failed with `Invalid File Path at /tmp/maestro-mac/flows/_adhoc.yaml:6:3`
(item 87, 6.6). `maestro test maestro/` run in place passed four of six.

**Why.** A project's own flows are the ones worth running, and Maestro's
documented layout is a `flows/` directory beside the subflows it calls.

**To do.** When the transport puts the file on the same machine as the device
(bridge, local), run it where it is. Over ssh, ship the flow's directory, or
the files its `runFlow` lines name, keeping their relative paths.

## 121. `drivers.sh rig up` on Android announces a driver it will not start — **OPEN, raised 26 Oct 2026**

**What.** `drivers.sh rig up Pixel_6_Pro_API_34` printed
`Pixel_6_Pro_API_34  starting on 22087 (about 30s)` and then
`runners/android driver-up: Android has no standing driver …`, the module's
exit 2. Before that it printed `carrying on at load unknown after 0s`
(item 87, 6.4).

**Why.** The first line says a driver is starting on a port when none will;
the second reads like a failed load check.

**To do.** Ask `driver-up` first, or treat its exit 2 as "no standing driver"
and print that instead of the start line. Say why the load is unknown on
Android, or skip the settle wait there.

## 122. `prefs-read` on Android runs every `shared_prefs` file together, unnamed — **OPEN, raised 26 Oct 2026**

**What.** `runners/android/platform.sh prefs-read` is
`cat /data/data/<app>/shared_prefs/*.xml`. For `oneiota-products-rn`,
`prefs.sh` printed two XML documents back to back with nothing saying which
file each was (`WebViewChromiumPrefs.xml`,
`expo.modules.kotlin.PersistentDataManager.xml`; item 87, 6.5). The verb's own
comment counts 28 files for a Flutter app. AsyncStorage's SQLite store is not
read at all.

**Why.** A key cannot be traced to the SDK that wrote it, and no parser reads
the stream as one document.

**To do.** Print each file's name before its contents, and let the framework
name the file that is its own (Flutter's `FlutterSharedPreferences.xml`).
Reading AsyncStorage needs an app that uses it, to measure where it lands.
