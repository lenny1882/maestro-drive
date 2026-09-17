# Maestro itself — the surface worth knowing before driving

Everything in this file is about Maestro rather than about any app. The
headline finding is the process one: read the surface first. Three separate
sweeps in the original work stopped early, and each early stop left a fix on
the table.

## 6. The tool surface — read it before driving, not after

The worst process failure of this session was three separate rounds of "read a
little, find something useful, jump straight back to tapping". Each round found
things that mattered, and each stopped early. Reading the whole surface first
costs a few minutes; not reading it cost most of two sessions.

A mirror of the Maestro documentation — 154 pages — is in `docs/pages/` in this skill,
with the URL list in `docs/urls.txt`. Grep it instead of fetching page by page:

```sh
grep -rl "centerElement" docs/pages/
grep -rn "traits" docs/pages/reference__selectors__*.md
```

To refresh it, run the download on the Mac (it has internet, the sandbox does
not): fetch `llms.txt`, extract the `.md` URLs, download in parallel with
`xargs -P 8`, tar, and `scp` back.

**The docs also answer questions directly.** Every page carries a GitBook agent
block: a GET on the page URL with an `ask` parameter returns an answer plus the
relevant excerpts, so an undocumented corner can be queried rather than guessed
at. Run it on the Mac, which has internet:

```sh
./bin/mac.sh 'curl -sG "https://docs.maestro.dev/reference/commands-available/addmedia.md" \
  --data-urlencode "ask=can addMedia provide frames to the camera, not just the gallery?" \
  --data-urlencode "goal=test a barcode scanner on an iOS simulator"'
```

**The documentation is behind the binary.** `maestro test --help` on 2.8.0 lists
`--[no-]reinstall-driver` and `--format HTML-DETAILED`, neither of which appears
anywhere in the 154 pages. Check `--help` against the installed version before
concluding a flag does not exist.

### MCP tools

Six local tools: `list_devices`, `inspect_screen`, `take_screenshot`, `run`,
`cheat_sheet`, `open_maestro_viewer`. Four cloud tools need `maestro login` and
are not relevant here.

**Every one of the device-facing tools resolves to the driver on port 22087 and
ignores the `device_id` it is passed** — the port is compiled in with no
override (`reference/driver-api.md`). With one simulator booted that does not
matter; with two, they answer about the wrong one without saying so. Use
`bin/driver.sh` with `DEV` for anything where the device matters. **Call `cheat_sheet` once at the start of a session** —
the server's own instructions say to, and it is one cheap call that covers the
whole command language.

### Commands worth knowing exist

Grouped by the problem they solve. None of these were used in the original
session, and most were not used in this one either.

| problem | command |
| --- | --- |
| deterministic start | `launchApp: { clearState: true, clearKeychain: true, permissions: {...} }`, `clearState`, `killApp` |
| skipping a setup journey | `openLink` with a deep link — the app uses `auto_route` with named routes such as `RequestDetailRoute(requestId:)` |
| the keyboard | `pressKey: "Enter"` submits without hunting for a button. `hideKeyboard` is documented as flaky on iOS; the official workaround is tapping a non-interactive area — not the keyboard's own done key |
| lazily-built lists | `scrollUntilVisible` with `centerElement: true`, which settles the element more than 30% from the viewport edge. It fails on partial-screen scrollables such as bottom sheets and overlay menus; write a custom loop there |
| waiting | `waitForAnimationToEnd`, `extendedWaitUntil`, and `waitToSettleTimeoutMs` on `tapOn` itself |
| taps that do nothing | `retryTapIfNoChange` (on by default), `retry: { maxRetries: }` — **capped at 3**, and 0 is legal — and `repeat: { while: { visible: } }` |
| branching on state | `runFlow: { when: { visible / notVisible / platform / true } }` |
| probing without failing the run | `optional: true` on any command |
| reading a value out of the app | `copyTextFrom` into `maestro.copiedText` |
| checking the backend agrees | `evalScript` / `runScript` with the built-in HTTP client: `http.get/post/put/delete`, headers, `json()` to parse, results into the global `output` object |
| test data | `faker` in JavaScript; `-e` and `env:` for parameters |
| camera and media | `addMedia` — documented as adding to the device *gallery*. Whether it can feed a camera feed is not documented and is untested |
| evidence for a bug report | `startRecording` / `stopRecording`, `takeScreenshot: { cropOn: }`, `assertScreenshot`; `maestro record --local <flow>` stitches the screen and the flow output into one MP4 |
| when the hierarchy cannot answer | `extractTextWithAI`, `assertWithAI`, `assertNoDefectsWithAI`. These read pixels, and are the sanctioned way to do it. They need a Maestro Cloud login — a free account is enough — and default to `optional: true`, so a failure only warns unless you set `optional: false` |
| scrolling inside an overlay or sheet | `swipe: { from: { <selector>, point: "50%,85%" }, direction: UP }`. The percentage is measured **within the matched element**, so the gesture starts inside the scrollable region instead of the middle of the screen. Simpler than the custom-loop recipe and it needs no absolute coordinates |
| waiting for a control to become usable | put `enabled: true` in the selector. Maestro waits for the element to become interactive before tapping, so `tapOn: { text: "Submit", enabled: true }` replaces a poll |
| checking a reported bound is where you think | `takeScreenshot: { path: x, cropOn: <selector> }` crops to the element's *reported* bounds — if the crop shows the wrong part of the screen, the bounds are wrong, which is the bounds section's problem made visible in one command |
| asserting a screen the hierarchy lies about | `assertScreenshot: { path:, cropOn: <selector>, thresholdPercentage: 95 }` compares pixels against a baseline taken by an earlier `takeScreenshot`. It is the only assertion that does not depend on the bounds being right, which is the point on any screen whose bounds cannot be trusted. Default threshold 95%; the value is interpolated, and an unset variable fails the command rather than falling back |
| clearing a long field | `eraseText` sends backspaces — 50 by default, 100 maximum. For anything longer, `longPressOn` then `tapOn: "Select All"` then `eraseText: 1` |
| generating test data | `inputRandomEmail`, `inputRandomPersonName`, `inputRandomNumber`, `inputRandomText`, `inputRandomCityName`, `inputRandomCountryName`, `inputRandomColorName`; `length:` (default 8) applies to the number and text ones |
| comparing two screens' values | `copyTextFrom` → `evalScript: ${output.a = maestro.copiedText}` → `assertTrue: { condition: ${output.a == output.b}, label: ... }` |
| changing a permission mid-journey | `setPermissions: { permissions: { camera: allow } }`. Values are `allow`, `deny` and `unset`; iOS also takes `location: always/inuse/never` and `photos: limited`. Interpolated, so one flow can run both the granted and denied journeys off `-e` |
| going back on iOS | not `back` — that command is Android and Web only. Use the app's own back control, or `id: "breadcrumb"` for the system return link after following a link into Safari |

### Mechanisms, not just commands

Four behaviours that explain failures rather than merely offering features.

- **A tap on a matched element is a tap on the centre of its bounds.** A
  selector is a lookup followed by a coordinate tap, so bad bounds defeat every
  selector equally — this is the whole of the problem described in `reference/driving.md`. `tapOn`
  also accepts `point` *alongside* a selector, in which case the percentage is
  measured **within that element's bounds**:
  `tapOn: { text: "A text with a hyperlink", point: "90%,50%" }`.
- **`hideKeyboard` on iOS scrolls from the centre of the screen**, because iOS
  exposes no API to dismiss the keyboard. That is exactly why it is flaky, and
  why the documented workaround is to tap a non-interactive area instead. Both
  halves of that were measured on 13 Aug 2026 and neither worked on the app
  under test: a swipe from the middle and six taps on different blank areas all
  left the keyboard up, and `key return` put it away every time. Tapping a
  blank area only unfocuses if the app was written to do it, which a Flutter
  app usually is not. `driver.sh dismiss` tries the tap first and falls back to
  return, and says which it used, because return also submits the field.
- **`scroll` and `scrollUntilVisible` also swipe from the centre of the
  screen.** Where the centre is not inside the scrollable region — a bottom
  sheet, a dropdown overlay, a split layout — the swipe lands on a static
  element and the command quietly achieves nothing. The fix is a manual loop
  with explicit `swipe: { start:, end: }` coordinates inside the container,
  driven by `repeat: { while: { true: ${output.found == 0} } }` with a
  `runFlow: { when: { visible: } }` that sets the flag. Full recipe in
  `docs/pages/examples__recipes__custom-scrolling-for-screen-fragments.md`.
- **An element counts as visible only when *fully* inside the viewport**, by
  default. `visibilityPercentage` relaxes that threshold.
- **`clearState` on iOS reinstalls the whole app.** It is not Android's
  `pm clear`. That makes it slow, and it takes the running process with it — so
  in a `flutter run` debug build the Dart VM Service dies and comes back on a
  *different port*. Re-run `./bin/publish.sh` after any `clearState`, or
  `bin/net.sh` will be reading a port nobody is listening on — and a new
  isolate, whose dart:io HTTP profiling is off again. `publish.sh` sets it.
- **Reading the hierarchy is not free of side effects on iOS.** XCTest triggers
  `willDisplayCell` on `UITableView` and `UICollectionView` whenever a UI-test
  API is called, so an app that paginates on that callback fetches data because
  you inspected the screen. Flutter does not use those views, but any native
  iOS screen in a hybrid app can be disturbed by the act of looking at it.
- **`repeat` takes `times` and `while` together**, and stops at whichever comes
  first. Every unbounded `while` loop in the recipes should carry a `times:`
  as well — a flow that never terminates costs a full SSH timeout here, not a
  quick failure.
- **`assertVisible` and `assertNotVisible` already poll for 7 seconds** before
  failing, and `waitForAnimationToEnd` waits 15 s by default and *succeeds* on
  timeout rather than failing. So an assertion that fails immediately after a
  `tapOn` has not lost a race with an animation — it waited seven seconds. The
  element was genuinely unmatchable — where bounds are wrong, that is the
  problem in `reference/driving.md`. An earlier version of this file blamed
  dropdown animations for it; that explanation was wrong.

There is also no `index: last`. Finding the final element of a list of unknown
length needs a scanning loop —
`docs/pages/examples__recipes__get-the-last-matching-element.md`.

### Every run leaves a full diagnostic bundle on the Mac

This is the largest unused source of state in the setup. Every `run` — through
the MCP server as much as the CLI — writes a timestamped session folder under
`~/.maestro/tests/` on the Mac, and a per-flow folder inside it. Confirmed
present for this session's runs:

```
~/.maestro/tests/<timestamp>/
├── maestro.log                      # the session
├── xctest_runner_<timestamp>.log    # iOS: the raw XCTest runner log
└── <flow>/
    ├── manifest.json                # documented index, carries a $schema
    ├── commands.json                # one entry per step: status, duration, error, artifacts
    ├── screen-hierarchy/step-NNN-*.json   # the hierarchy at the failing step
    ├── screenshots/step-NNN-*.png         # the screen at the same step
    └── logs/{maestro,device-simulator,device-xctest}.log, crash-report.txt
```

**When a step fails, the hierarchy and the screenshot at the moment of failure
are already on disk.** Read them instead of re-running the flow to reproduce it:

```sh
./bin/mac.sh 'd=$(ls -td ~/.maestro/tests/*/ | head -1); find "$d" -name "*.json" | head'
```

`commands.json` also gives per-step durations, including Maestro's own implicit
steps, which is the honest way to find what is actually slow. A crash lands as
`crash-report.txt` — on iOS that is the simulator's `.ips` report copied
verbatim, so it holds JSON despite the extension. A passing flow writes no
`screenshots/` folder at all.

`--analyze` captures much more — a screenshot before every action step, a
`final.png`, and an MP4 of the whole run — but it needs a Maestro Cloud login.

### Configuration the docs bury

`config.yaml` sits in the workspace root and is picked up when Maestro is
pointed at a *directory*; an inline `yaml:` snippet through the MCP `run` tool
never sees one. Use `run` with `dir:`, or `maestro test --config <file>`.

| key | why it matters here |
| --- | --- |
| `platform.ios.snapshotKeyHonorModalViews: false` | includes elements behind a modal and "elements that have absolute positioning" in the hierarchy. The first thing to try against the dropdown overlay problem (reference/driving.md). Works locally, not cloud-only |
| `platform.ios.disableAnimations` | **cloud only.** It does not affect a local simulator, so it is not the answer to local animation flakiness |
| `testOutputDir` | move the artifact bundle somewhere predictable rather than the timestamped default |
| `flows`, `includeTags`, `excludeTags`, `executionOrder` | discovery and ordering. Maestro only runs YAML in the *top level* of a directory unless `flows: "**"` says otherwise |

Environment variables worth exporting on the Mac before any CLI run — each
removes a per-invocation network call or a banner:
`MAESTRO_DISABLE_UPDATE_CHECK=true`, `MAESTRO_CLI_NO_ANALYTICS=true`,
`MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true`. Also
`MAESTRO_DRIVER_STARTUP_TIMEOUT`, where **the published documentation is
wrong**: it gives the default as 15000 ms, but `LocalXCTestInstaller.getStartupTimeout()`
falls back to `120000L` when the variable is unset or unparseable, so on iOS a
slow driver start has two minutes before it gives up. Verified by disassembling
the class on the Mac, not inferred. Do not "correct" this back to 15000. Any shell variable named `MAESTRO_*` is readable inside a flow as
`${MAESTRO_*}`, which is a way to pass configuration without touching the
command line.

`MAESTRO_OPTS` passes JVM options to the CLI and nothing else; `JAVA_OPTS` does
the same for every JVM on the machine. Documented for proxy settings
(`-Dhttps.proxyHost`, `-Djava.net.useSystemProxies=true`), but it is the general
lever for anything that needs to reach the JVM rather than Maestro.

### Launch arguments — telling the app it is under test

Absent from the cheat sheet, and the most useful thing found in the whole sweep:

```yaml
- launchApp:
    arguments:
      isMaestro: true
```

Values may be string, boolean, double or integer, and the app reads them at
startup. This is the documented answer to bypassing 2FA, pointing at a mock
server, holding a transient banner on screen long enough to be tapped, and
switching off custom animations that `waitForAnimationToEnd` cannot detect.

**On Flutter the app side is a named package.** `flutter_launch_arguments`
exposes `getString`, `getBool`, `getDouble` and `getInt`
(`docs/pages/reference__commands-available__launchapp.md`), so the proposal to
the app team is concrete: add that dependency and read an `isMaestro` flag at
startup. On iOS the values also arrive in `ProcessInfo.processInfo.arguments`
and `UserDefaults.standard`, all as strings, if a platform channel is preferred
to a package.

`launchApp: { stopApp: false }` foregrounds a backgrounded app without
restarting it — useful when you want to keep state rather than reset it.

Hooks (`onFlowStart`, `onFlowComplete`) belong in the config section above the
`---` and run for every flow, which is where login and reset should live rather
than being repeated at the top of each file.

Maestro drives the whole device rather than just the app, so a journey may
follow a link out into Safari and come back.

### CLI options that matter for the fallback path

`maestro test --no-reinstall-driver` skips the driver reinstall, which is a
large part of the 7.7 s per-invocation cost measured in `reference/driving.md`.
`--test-output-dir` gathers `manifest.json`, `commands.json`, `logs/`,
screenshots and recordings in one directory. Also `--debug-output`,
`--flatten-debug-output`, `--format HTML-DETAILED`, `-e` for env vars.

Other subcommands: `maestro hierarchy` (prints the current hierarchy straight to
the terminal), `record`, `check-syntax`, `start-device`, `list-devices`,
`driver-setup`, `bugreport` (collects logs and system information into a zip,
which is what an upstream issue needs), `download-samples`.

Defaults read from the classes rather than the pages, since the documentation
states some and not others: `scrollUntilVisible` timeout 20000 ms and speed 40;
`tapOn` `delay` 100 ms between repeats; `waitToSettleTimeoutMs` capped at
30000 ms however large a value you pass. `TestCommand` also carries
`--apple-team-id`, `--api-url` and `--api-key`, none of which appear in the
options table.

`maestro test -c` watches the flow file and re-runs on save — useful when
iterating on a flow over SSH rather than re-issuing the command each time.
`--shard-all N` runs the same flow across N booted simulators at once; two are
booted on this Mac, which makes it a cheap flakiness check.

### YAML and interpolation traps

Small, silent, and all documented:

- **`YES` and `NO` are booleans in YAML.** `tapOn: YES` searches for the text
  `true` and fails with `Element not found: Text matching regex: true`. Quote
  them: `tapOn: "YES"`.
- **`$` starts a variable.** Escape it for literal text: `assertVisible: \$150`.
  `text` and `id` are regexes, so `[`, `(`, `.` need escaping too.
- **An undefined variable does not fail — it becomes the string `undefined`.**
  `takeScreenshot: { path: ${MISSING} }` silently writes `undefined.png`.
- **No template literals inside `evalScript`.** The command is already wrapped
  in `${...}`, so backticks break it; concatenate instead. They work fine in an
  external `.js` file via `runScript`.
- **`console.log` takes one argument only.** A second is dropped. Output lands
  in `maestro.log` prefixed `JsConsole`, which is a usable channel for getting a
  computed value out of a flow and into a file readable over SSH.
- **Everything passed with `-e` arrives as a string.** `parseInt` it before
  comparing numerically, or a `when: { true: ${COUNT > 5} }` compares text.
- **Variable names are case-sensitive**, and a subflow's own `env:` — or the
  `env:` on the `runFlow` that called it — **overrides** a value of the same
  name from the parent.
- **`${VAR || "default"}`** is the idiom for a default, which is what lets one
  subflow run both standalone and as part of a larger flow.
- **Built-in parameters:** `MAESTRO_FILENAME`, `MAESTRO_DEVICE_UDID`,
  `MAESTRO_SHARD_ID` (from 1) and `MAESTRO_SHARD_INDEX` (from 0). Combined with
  `console.log`, `MAESTRO_DEVICE_UDID` lets a flow record which simulator it
  actually ran against.
