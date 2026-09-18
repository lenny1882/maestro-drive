# The iOS driver's own HTTP API

Maestro's XCUITest driver is a long-lived HTTP server, and it both reads the
screen and drives it. None of this is documented upstream — the routes and
request shapes were read out of the Maestro jars and then exercised against a
live driver — so treat it as a private interface that an upgrade may change,
and re-check it after one.

`bin/driver.sh` wraps all of it.

### Driving the app without Maestro

The iOS driver — `maestro-driver-iosUITests-Runner`, installed into the
simulator — is a long-lived process listening on the Mac's `127.0.0.1:22087`,
and it serves the hierarchy and screenshots itself over HTTP. Relayed onto the
LAN the same way as the viewer, it answers a plain `curl` from here:

```sh
./bin/driver.sh start        # -> http://<mac>.local:9101
./bin/driver.sh info         # points and pixels, so the device scale factor
./bin/driver.sh tree         # labelled nodes: frame, type, id, label, state
./bin/driver.sh nodes        # the same plus every unlabelled container
./bin/driver.sh hierarchy    # the same as raw JSON
./bin/driver.sh shot out.png # full-resolution PNG, upright, in app-space points
```

A shot is delivered the right way up and croppable in the same coordinates as
everything else here — points, app space, the numbers `driver.sh point` gives:

```sh
./bin/driver.sh shot out.png --on "^SCAN$" --pad 8   # crop to one element
./bin/driver.sh shot out.png --crop 40,120,300,80    # or to a rectangle, in points
./bin/driver.sh shot out.png --scale 40              # shrink it
./bin/driver.sh shot out.png --raw                   # native pixels, untouched
```

`/screenshot` itself hands back the device's *native* pixels, which is not the
same picture as the app's:

| | app space, `/deviceInfo` | the PNG that arrives |
| --- | --- | --- |
| iPad Pro 11-inch, landscape-locked app | 1194x834 points, 2388x1668 pixels | **1668x2388** |
| iPhone 16 Pro, portrait | 402x874 points, 1206x2622 pixels | 1206x2622 |

So on the iPad the picture arrives on its side and at twice the points it is
measured in. Both were corrected by hand until 13 Aug 2026 — eight `sips -r 270`
calls in one session, hand-written ImageMagick crops against a 1206x2622 source
in another.

Which way to turn it is the status bar again, the same reading that separates
system space from app space (`resolve.py --space`): the bar down the right edge
means 270 degrees clockwise, down the left edge means 90. Both were measured by
rotating the simulator each way and looking at the result.

The cost is only paid where it is owed. The hierarchy is fetched only when the
picture disagrees with the screen — a portrait image of a landscape screen — so
an upright device pays nothing: 0.6 s for an iPhone shot, 1.2 s for an iPad one
including the rotation.

`bin/img.sh` does the pixels, and needs nothing installed. It uses ImageMagick
if the machine has it, `sips` if the skill is being run from a Mac, and
otherwise sends the file to the Mac and back, where `sips` always exists
(1.8 s). The three agree: an over-wide rectangle is trimmed by the first and
slid by the second, so it is clamped before either sees it.

Both listings come from `bin/tree.py`, which reads `/viewHierarchy` JSON on
stdin, so it can also be pointed at a saved capture.

`tree` is the everyday read; `nodes` is what you want whenever a coordinate
does not add up, because the frames that explain a coordinate-space marker live
on containers that carry no label. Read the JSON directly for anything a flat
listing mangles — labels can contain newlines, and an app that wraps one
mid-number (`"501234567\n8900"`) makes a `grep` over `tree` output split the
value across two lines and silently lose it.

### The driver takes instructions, not just questions

`/viewHierarchy`, `/screenshot` and `/deviceInfo` are three routes out of
eighteen. The full set was read out of the Maestro jars on the Mac
(`xcuitest/XCTestDriverClient.class` names each route, `xcuitest/api/*Request.class`
gives each body) and then exercised against the live driver:

| route | body | verified |
| --- | --- | --- |
| `touch` | `{"x":200,"y":483,"duration":0.1}` | yes — 0.46 s, focused the field it was aimed at |
| `inputText` | `{"text":"1234","appIds":[...]}` | yes — 1.13 s |
| `eraseText` | `{"charactersToErase":10,"appIds":[...]}` | yes — deletes backwards from caret (not forward) |
| `pressKey` | `{"key":"delete"}` | yes — removed one character |
| `pressButton` | `{"button":"home"}` | shape only |
| `swipeV2` | `{"appId":..,"startX":..,"startY":..,"endX":..,"endY":..,"duration":0.4,"appIds":[...]}` | **yes** — the live route, everywhere measured |
| `swipe` | same payload | **v1, and it does not rotate** — 200 either way; correct only while the app frame is portrait; see below |
| `setOrientation` | `{"orientation":"portrait"}` | yes — device rotated |
| `launchApp` / `terminateApp` | `{"bundleId":..}` / `{"appId":..}` | shape only |
| `isScreenStatic` | GET | yes — `{"isScreenStatic":true}` |
| `keyboard` | `{"appIds":[...]}` | yes — `{"isKeyboardVisible":true}` |
| `runningApp` | `{"appIds":[...]}` | yes — returns the foreground bundle id |
| `installedApps`, `setPermissions` | — | not exercised |
| `keyboardInfo` | — | named by the client, **404 on this driver** (13 Aug) |

All of it is in `bin/driver.sh`: `tap`, `text`, `key`, `button`, `erase`,
`swipe`, `orient`, `launch`, `kill`, `static`, `keyboard`, `app`.

### `swipe` is not the swipe route — `swipeV2` is, and the difference is rotation

This table said `swipe` was the working route until 17 Sep 2026, and the
correction cost a day. **`POST /swipe` answers HTTP 200 whether or not it moves
the screen.** The 200 confirms the JSON parsed, nothing more — which is the
whole difference, because a swipe that reports success and moves nothing reads
as an app that will not scroll.

**Where it does nothing.** iPad Pro 11-inch (M4), iOS 18.6, landscapeLeft,
driving a Flutter two-column grid, 16 Sep 2026: fourteen consecutive `/swipe`
calls produced fourteen identical hierarchies — `760 700 760 300` at 0.4, 0.6,
0.8 and 1.0 s, both columns, the scrollbar edge, and a normalised `0.63 0.84
0.63 0.25`. The same payload to `/swipeV2` scrolled the grid first try, and a
22-step sweep built on it reached all 48 rows in 90 s.

**Where it works.** iPhone 16 Pro Max, iOS 18.6, 17 Sep 2026 — first against
springboard (paged the home screen in both directions, returning to an earlier
page's exact row signature, which a redraw cannot fake), then **against a
Flutter scrolling list in the app under test**, which is the case that matters:

```
before  4002 Riverside · 4002 Riverside · 4010 Eastgate · 4014 Eastgate ·
        4032 High St · 4110 Northfield · 4140 Lakeside · 4200 Harbour
after   4002 Riverside · 4110 Northfield · 4140 Lakeside · 4200 Harbour ·
        4210 Marina · 4232 Central Mall · 4237 Outlet Park · 4238 Grand Mall ·
        4241 Grand Mall GF
```

One `POST /swipe` moved it. `/swipeV2` moved the same list immediately
afterwards. The 16 Sep note claiming `/swipe` was confirmed broken on an iPhone
was second-hand and is withdrawn.

**The variable is the orientation, and `/swipe` does not rotate.** Isolated
18 Sep 2026 on iPad Pro 11-inch (M4), one driver, in **Settings** rather than the
app so the framework is out of it. The same app-space payload to each route,
relaunched to a fresh scroll position before every trial:

| device orientation | app frame | `/swipe` | `/swipeV2` |
| --- | --- | --- | --- |
| `landscapeLeft` | 1210x834 | **no change, 2 trials** | moved, 2 trials |
| `portrait` | 834x1210 | moved, 2 trials | moved, 2 trials |

Rotate the device and `/swipe` starts working. Nothing else changed. In landscape
the hierarchy shows the two spaces disagreeing outright — the app node reports
`1210x834` while the status bar reports `24x1210` — and that is the same split
rule 3 exists for. `/swipeV2` applies the rotation; `/swipe` sends the point
through unturned, it lands off the view, and the 200 says only that the JSON
parsed.

So it is not the device and not the framework: Flutter on a **portrait** iPhone
scrolls under either route, and UIKit on a **landscape** iPad scrolls under
neither but `swipeV2`. Anything that posts a raw coordinate has to know which
space it is in — the third instance of that, after the resolver and the raw-tap
rule. Everything here posts `swipeV2`, which is both what Maestro itself uses and
the only route that rotates.

The route Maestro itself uses, read out of its own log for a `scrollUntilVisible`
that worked (`~/.maestro/tests/<run>/xctest_runner_*.log`):

```
37 request: POST /deviceInfo
20 request: POST /viewHierarchy
 5 request: POST /swipeV2
```

The driver ships a `SwipeRouteHandlerV2` test class, so v2 is current.
`bin/driver.sh` posts `swipeV2` from all three of its call sites — the `swipe`
verb, the journey verb, and `_scrollto`, which inherited the dead route and
reported `not found after N swipes down` with the list still on row one.

**What this invalidates, and what it does not.** A sweep that ran through
`scrollto` or a scroll journey **against a landscape app frame** was read from a
list that never moved, and concluded everything in it was reachable. **Against a
portrait frame it was not**: `/swipe` rotates nothing and needs to rotate
nothing there, so those sweeps stand. The test is the orientation the app was in,
not which handset it was on — check that before re-running a reachability claim
(BACKLOG item 69).

**Nothing in that list hides the keyboard**, and the list is the whole of what
the driver serves. iOS exposes no API for it, so Maestro's `hideKeyboard` is
implemented in the Kotlin client instead — `IOSDriver.hideKeyboard` swipes and
then checks `isKeyboardHidden`, which upstream documents as flaky. `driver.sh
dismiss` does the two things that can work from here, harmless one first, and
reads the keyboard back after each; `reference/driving.md` has the measurement
of which one actually worked on the app under test, and why the answer is a
property of the app rather than of iOS.

`keyboardInfo` is worth knowing about but not usable: `XCTestDriverClient`
names the route, and the driver built from the jar on this Mac answers 404 to
it. If a later Maestro ships a driver that serves it, the keyboard's geometry
would come from the device rather than being derived from its size.

Every one of those verbs polls `isScreenStatic` after acting and returns the
moment the screen is still, which is what makes a `sleep` after one pointless.
Until 13 Aug 2026 only the journey verbs did this and the command-line ones
returned immediately, so a caller genuinely did have to guess a wait; 42 of the
154 sleeps counted across four sessions were covering exactly that. A settle
timeout warns on stderr and leaves the exit status alone — the action happened,
the screen is merely still busy — whereas in a journey it fails the step, since
a batch carrying on into a moving screen is how a batch goes wrong. `SETTLE=0`
skips the wait for a screen that never settles; `SETTLE=<n>` shortens it from
the default 20 s.

Any of them, and `tapon` and `type` with them, take `--tree` or `--nodes`
directly after the verb to print the screen once the action has settled:

```sh
./bin/driver.sh tapon --tree "^CONTINUE$"    # act and look, one round trip
./bin/driver.sh tap --nodes 200 483
```

Only in that position — `type` takes the rest of the line as text, so a flag
after it is typed. The screen prints even when the action failed.

Measured live on 13 Aug 2026: 2.29 s for the combined call against 2.61 s for
the same two as separate invocations. So the process saving is 0.3 s and beside
the point — as with journeys, what it removes is the model stopping to think
between an action and the read that tells it what the action did.

**Why this matters more than the speed.** `/touch` takes raw screen coordinates
in points. It has no selector, no bounds lookup, and no conversion step — which
is precisely the part that an app with wrong bounds breaks. Where the reported
bounds are at 1/3 scale, the sequence is: read the tree from the driver,
multiply by 3, tap the point. One call, half a second, no guessing.
That is a better answer to the bounds problem than any selector trick.

Two traps in the request shapes:

- **`setOrientation` values are camelCase on the wire.** `portrait` and
  `landscapeLeft` are accepted; `PORTRAIT` and `LANDSCAPE_LEFT` — the spelling
  Maestro's own `DeviceOrientation` enum uses — come back as `incorrect request
  body provided for set orientation`.
- **A rejected body returns HTTP 200 with a JSON error**, e.g.
  `{"code":"precondition","errorMessage":"incorrect request body ..."}`. A
  successful write returns an empty body. Check the body, not the status.

Nothing here is documented upstream, so treat it as a private interface that a
Maestro upgrade may change without warning. `bin/bench.sh` should be re-run and
these routes re-checked after any upgrade.

It also confirms the driver survives between calls — `lsof -nP -iTCP:22087` on
the Mac is a one-line health check for the driver session, which an earlier note previously
listed as untested. The port number comes from the docs' note that checking for
open port `22087` used to be the way apps detected Maestro on iOS
(`docs/pages/maestro-flows__flow-control-and-logic__detect-maestro.md`); that
detection method is deprecated, but the port is still there.

### The jars are the real reference

`~/.maestro/lib/` holds nine Maestro jars, and they answer questions the
documentation does not. Extract them once on the Mac and read them there:

```sh
./bin/mac.sh 'cd /tmp && rm -rf jx && mkdir jx && cd jx
for j in ~/.maestro/lib/maestro-*.jar; do unzip -o -q "$j" -d .; done'
```

`javap -p -c -constants <class>` is enough; there is no decompiler on the Mac
and none is needed. Note that Xcode's `strings` chokes on `.class` files —
use `javap`, or `LC_ALL=C tr -c "\40-\176" "\n"`.

**`maestro-ios-driver.jar` ships the driver's Swift source**, not just the
built runner: `driver/ios/maestro-driver-iosUITests/Routes/`. That is the
authoritative reference for the HTTP API above — `XCTestHTTPServer.swift` lists
every route, `RouteHandlerFactory.swift` maps them to handlers, and
`Models/*Request.swift` gives every request body. Read those rather than
guessing, and re-read them after a Maestro upgrade.

Four things worth knowing that came out of this:

- **`PORT` overrides the driver's port.** `XCTestHTTPServer` reads
  `ProcessInfo.processInfo.environment["PORT"]` and falls back to 22087.
- **`/touch` coordinates are portrait-referenced.** The handler passes them
  through `ScreenSizeHelper.orientationAwarePoint`, which is the identity in
  portrait and rotates the point itself in landscape. Send portrait
  coordinates whatever the device is doing.
- **A `duration` on `/touch` makes it a long press**, so omit the field for a
  plain tap. `bin/driver.sh tap x y` sends none; `tap x y 1.0` presses for a
  second.
- **`checked:` only matches element types 12, 40 and 41** — checkbox, switch
  and toggle — *and* requires the value to be the string `"1"`
  (`IOSDriver.CHECKABLE_ELEMENTS`). On anything else the selector silently
  matches nothing. `bin/driver.sh tree` now prints type names rather than
  numbers.

**A second lead the jars closed: snapshot parameters cannot fix wrong
coordinates.** `AXClientSwizzler.overwriteDefaultParameters`, in
`driver/ios/maestro-driver-iosUITests/Routes/XCTest/AXClientSwizzler.swift`
inside `maestro-cli-2.8.0.jar`, swaps `XCAXClient_iOS`'s `defaultParameters` for
a copy with entries overwritten from a `[String: Int]` dictionary. Every
parameter is therefore an integer, and they govern how much of the tree is
walked — depth and breadth — not how frames are measured. No HTTP route exposes
the dictionary either, so using it at all would mean rebuilding the driver.
Where an app reports its frames wrongly, nothing on the driver side can correct
it.

**A lead the jars closed: there is no on-device selector resolution on iOS.**
`queryOnDeviceElements` looks like it might ask XCTest to resolve a selector on
the device and hand back a true frame — which would sidestep the bounds problem
outright. It does not. `IOSDriver` inherits the interface default, and that
default is `return emptyList()`. The only implementations are `WebDriver` and
`CdpWebDriver`, and `OnDeviceElementQuery` is a sealed class whose sole subclass
is `Css`. It is a web-only path. Coordinate arithmetic from the hierarchy
remains the only way round wrong bounds on iOS.

### What Maestro does to the bounds: nothing

`IOSDriver.mapViewHierarchy` builds each node's attribute map by straight field
copy — `bounds` is `AXFrame.getBoundsString()` with no arithmetic anywhere in
the method. There is no scaling step on the Maestro side at all. Whatever is
wrong with an app's coordinates is wrong before Maestro sees it — the bounds
section's empirical finding, now confirmed from the code.

The same read settles what `text:` actually matches. `Filters.textMatches` runs
three passes over the tree, in order:

| pass | attribute | fed from |
| --- | --- | --- |
| 1 | `text` | the element's `title`, falling back to `value` |
| 2 | `hintText` | `placeholderValue` |
| 3 | `accessibilityText` | `label` |

with `id:` matching `resource-id`, fed from `identifier`. Two consequences:

- **A `Semantics(label:)` in Flutter lands in `accessibilityText`, not `text`** —
  which is why `inspect_screen` can show elements with `a11y` and no `txt`,
  and why a `text:` selector still finds them.
- **Newlines are replaced with spaces before matching.** A label that wraps on
  screen is matched as one line: write the selector with a space, never `\n`.

### The driver does transform frames — but never scales them

Two adjustments happen inside `ViewHierarchyHandler.swift`, and knowing them
stops us blaming the wrong layer:

- **A cross-process window offset**, `visibleFrame - rawFrame`, applied to a
  subtree only when all three of these hold: the `windowContextID` changes from
  the parent, the subtree is remote, and `visibleFrame` is finite. It exists
  for share sheets and HealthKit. An in-process Flutter overlay does **not**
  qualify, which is exactly why the dropdown described in `reference/driving.md` arrives in its parent's
  space with no correction applied and we have to do the arithmetic ourselves.
- **A whole-hierarchy translation** when the app's root frame differs from
  SpringBoard's, via `expandElementSizes` — misleadingly named, since it only
  adds an offset to X and Y and leaves width and height alone. It carries an
  explicit guard against reading a portrait/landscape swap as an offset.

Neither multiplies. No code path on either side of the wire can produce a
factor of three.

### Running a driver per device, so several can be driven at once

Maestro's client side can only ever talk to one device from one machine.
`MaestroSessionManager.defaultXcTestPort` and
`McpMaestroSessionManager.DEFAULT_XCTEST_PORT` are both the literal `22087`,
`sipush`ed inline with no environment read anywhere. The MCP server therefore
serves **whatever device is on 22087**, whichever `device_id` you pass, and
says nothing about it. Measured 12 Aug 2026: with the iPad's driver on 22087,
`inspect_screen` for the iPhone's UDID returned the iPad's tree, 1194x834,
correct-looking in every other way.

The driver itself has no such limit, and the port is plumbed all the way
through:

- `XCTestHTTPServer.swift` — `ProcessInfo.processInfo.environment["PORT"]`,
  falling back to 22087.
- `XCRunnerCLIUtils.runXcTestWithoutBuild(deviceId, xctestrun, port, ...)` takes
  the port as a parameter and passes it as **`TEST_RUNNER_PORT`**, xcodebuild's
  convention for injecting a variable into the test process with the prefix
  stripped.
- `LocalXCTestInstaller` takes `defaultPort` as a constructor argument. Only the
  two session managers above hardcode it.

So a driver can be started on any port by doing what Maestro does, with the
port chosen — the same build products out of `maestro-ios-driver.jar`, the same
`xcodebuild test-without-building`:

```sh
TEST_RUNNER_PORT=22088 xcodebuild test-without-building \
  -xctestrun <extracted>/maestro-driver-ios-config.xctestrun \
  -destination "id=<udid>" -derivedDataPath <dd>
```

`bin/drivers.sh` does this per simulator and `bin/driver.sh` resolves the port
from `DEV`. Measured: ~30 s cold per device, ~12 s when the runner app is
already installed; reads stay at 0.43 s including local process startup.

Three things that were tested rather than assumed:

- **Two devices, two drivers, at the same time.** iPhone on 22087 and iPad on
  22088 both answered `/deviceInfo` with their own dimensions, and a `launchApp`
  on one left the other untouched.
- **One simulator holds one driver.** Starting a second driver for the same
  device on a different port killed the first — the runner is one app on the
  device, and launching it again replaces the instance that was there. So an
  MCP call or a CLI run for a device destroys whatever driver that device had,
  and rebuilds it on 22087.
- **Naming a device to Maestro destroys that device's driver.** With the iPad
  on 22087 and the iPhone on 22088, `maestro --device <iphone> hierarchy` killed
  the iPhone's driver, left the iPad's untouched, and returned the iPad's
  hierarchy — it tears down the runner on the device it is told about, then
  talks to whatever is on 22087. A CLI run leaves nothing behind either way,
  because the driver only lives while a session holds it. So the failure mode is
  "that device now has no driver", not "its driver moved".
- **A failed Maestro run destroys it too.** Re-measured 13 Aug with three
  drivers up (iPad 22087, iPhone 16 Pro 22088, iPhone 16 22089). A `maestro
  --device <iPhone 16 Pro> hierarchy` that ended in an error left that device
  with no driver; so did the one after it that worked. The other two kept their
  ports both times.
- **The mapping is discoverable.** The runner process runs out of the
  simulator's own data container, so its command line carries the UDID, and
  `lsof -nP -a -p <pid> -iTCP -sTCP:LISTEN` gives the port it bound. Nothing has
  to be tracked in a state file. `$LDIR/drivers.owned` is not that map — it
  records what `drivers.sh up` deliberately started, so that a device missing
  from the live scan can be reported as taken rather than as never present.
  (`-a` matters: without it `lsof` ORs its
  selectors and reports other processes' sockets.)

### Why a CLI run kills the MCP session for good

`McpMaestroSessionManager` keeps a `ConcurrentHashMap<deviceId, session>`,
creates a session lazily on first use, and has no invalidation path — nothing
detects a dead XCTest client or rebuilds one. It also hardcodes
`DEFAULT_XCTEST_HOST = "127.0.0.1"` and `DEFAULT_XCTEST_PORT = 22087`, the same
port the CLI uses. So a CLI run takes the driver the server is holding, the
cached session keeps pointing at it, and every later call fails identically.
Only reconnecting the server clears it. This is the mechanism behind the rule
in the open questions: do not mix CLI runs into an MCP-driven session.

### The viewer, and why the wall replaced it

`open_maestro_viewer` returns `http://127.0.0.1:9999/`. Three things make that
unusable for watching from anywhere but the Mac. All three were measured on
15 Sep 2026; backlog 64 and 65.

**The port is not 9999.** `maestro mcp --help`: `--viewer-port` "Defaults to a
free local port". Every `maestro mcp` starts its own viewer, so every session
gets a different port — two sessions that afternoon held 9999 and 10001. Nothing
may assume the number; `bin/viewer.sh list` discovers it by asking each MCP
server's listening sockets for `/api/device/targets`.

**It attaches a device only when exactly one simulator is booted.** From the
served bundle:

```js
let e=(await(await fetch(`/api/device/targets`)).json()).devices||[];
if(e.length!==1)return;
```

With two booted it returns early, never posts `/api/device/start`, and there is
no picker for the multi-device case. The state stream sits at
`{"status":"idle","streamUrl":null}` and the page renders nothing, because the
screen needs `status === 'streaming' && streamUrl`.

**Its stream URL is an absolute loopback address.** A successful start returns
`"streamUrl":"http://127.0.0.1:55885/stream.mjpeg"` — a fresh random port each
time — which the browser fetches from its own machine. No relay reaches it.

**What a relay does carry.** The viewer's live updates are Server-Sent Events,
not websockets — the bundle opens `EventSource` against `/api/device/state` and
`/api/events/stream`, alongside `GET /api/device/targets` and `POST
/api/device/start` and `/api/device/input`. SSE is plain HTTP streaming, so a
raw TCP forwarder passes it through untouched, and `/api/device/targets` through
the relay returns every booted simulator. It is only the picture that cannot
cross, because only the picture is fetched from a second, absolute URL.

A note on an earlier claim here: the relay and the viewer coexisting on 9999 was
explained as the viewer holding an *IPv6* socket. It does not — `lsof` shows
`IPv6 … TCP 127.0.0.1:9999`, an IPv4-mapped address. They coexist because a
connection to `127.0.0.1` matches the more specific bind, not because the
families differ.

What does work is `bin/wall.sh`, which spawns the capture binary itself and
re-serves every simulator from one fixed port. `bin/viewer.sh` remains for the
viewer's command rows and device list, which a relay does carry; it discovers
the port rather than assuming one, and says plainly that the picture will be
blank.

### The capture binary

`~/.maestro/deps/simulator-server`, extracted from `maestro-cli-<v>.jar`. It is
what produces the video, and it is nothing to do with the XCUITest driver:

```
simulator-server ios --id <udid>
  -> stream_ready http://127.0.0.1:<port>/stream.mjpeg
```

MJPEG, `multipart/x-mixed-replace;boundary=NextFrame`, parts carrying
`Content-Type:image/jpeg` with **no Content-Length**, so a frame ends where the
next boundary begins. Frames are change-driven: a static screen produces almost
none. It exits the moment its stdin closes — that is the shutdown signal, and
the same pipe is how input events are written to it. Two instances can run
against one device, each taking its own port.

It loads Apple's private SimulatorKit from a path compiled into the binary,
`/Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/`.
**Xcode 27 deleted that directory** and moved SimulatorKit to
`Contents/SharedFrameworks`, so every stream fails with "simulator-server exited
before announcing stream_ready" until the path is put back:

```sh
sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks
sudo ln -s /Applications/Xcode.app/Contents/SharedFrameworks/SimulatorKit.framework \
           /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/
```

`simulator-server verify` reports which way round it is. `DEVELOPER_DIR` does
not steer the lookup — tested against a full shim Xcode tree, with
`xcode-select -p` confirmed to be honouring it, and the reported path did not
move. Upgrading Maestro does not help either: 2.10.0's copy of the binary is
byte-identical to 2.8.0's, same SHA-256, same hardcoded path. Xcode is an App
Store install, so an Xcode update removes the symlink again.

