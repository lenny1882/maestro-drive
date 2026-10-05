# maestro-drive — backlog

- **100.** Journeys are not Maestro tests — gated on Flutter 3.49 stable for the setup screens.
- **97.** The MCP server dies when the Mac is on another network.
- **93.** `flutter-hot-reload-mac` carries its own Flutter answers, and they are worse — gated on item 87.
- **90.** The wall shows simulators only, and a phone is a device too — gated on finding a way to stream a physical device's screen.
- **87.** Flutter and iOS are wired in, not plugged in.
- **107.** The `MaterialApp.router` dropdown report has not been sent upstream — re-test against Flutter 3.49 first.
- **108.** Android `boot` gives up on a second emulator that is still coming up.

Next item number: 109.

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
  skew cannot reap a live device. Android's `last-used` is unanswered: an
  emulator image's mtime says the emulator runs, not that anyone drives it.
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

**To do.**

- 2.2 React Native on iOS end to end: fill in `describe`, `build` and
  `residue` in `runners/react-native/framework.sh` against a real checkout.
  Done when `bin/build.sh --detect` reports an RN project and `--no-install`
  produces an artefact path. Needs node, a `react-native init` app and
  `pod install` on the Mac.
- Android `last-used` still refuses in `runners/android/platform.sh`: an
  emulator's qcow2 userdata mtime moves whenever the emulator writes anything,
  so it shows the emulator is running, not that anything is driving it.

**Gated on.** 2.2 needs a React Native checkout on the Mac; none of the
sixteen there is React Native.

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
exact text is approved.

**Gated on.** Approval of the exact text before anything is posted.

## 108. Android `boot` gives up on a second emulator that is still coming up — **OPEN**

**What.** `runners/android/platform.sh boot` waits 180 s for a new serial to
reach `device` state in `adb devices`, then exits 1 with "no new device
appeared within 180s". Booting `Small_Phone` straight after
`Pixel_6_Pro_API_34` on this machine (8 cores, 31 GB) hit that limit. The
emulator's log ended at `Loading snapshot 'default_boot'...`, `adb devices`
showed `emulator-5556 offline`, and the device reached `sys.boot_completed=1`
shortly afterwards.

**Why.** The caller is told the boot failed and is given no serial, while the
emulator it started keeps running and finishes booting.

**To do.** Count an `offline` serial that was not in the baseline as the new
device, and keep waiting on it for `sys.boot_completed`. Then make the limit a
setting and measure what two and three emulators booting back to back take
here.
