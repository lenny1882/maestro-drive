# Driving an app on a remote simulator

The method, and the rules that earn their place by having been paid for. App
specifics live in `reference/apps/`; Maestro's own surface is in
`reference/maestro-notes.md`; the connection is in `reference/connection.md`.

## The shape of the problem

Remote control over SSH is the approach. Everything here is about making the
round trip cheap and making each one count, because **the round trip is the unit
of cost** — not the tap, not the assertion, not the thinking.

For scale: the original session ran 2 h 58 m across 289 tool calls, 46 minutes
of which was pure remote execution. The worst stretch, "restart everything and
create a request", took 15.4 minutes across 37 sequential round trips. That is
not slow thinking; it is 37 trips where 3 would have done.

## Two sessions on one Mac

This is routine now, not exceptional: on 16 Sep 2026 two sessions drove the same
Mac all afternoon, and it worked entirely by improvisation. The rules below are
what they invented, written down.

**Claim your devices on the wall before you drive them.** `bin/wall.sh label`
records which session wrote it (`by=<colour> · <session>`), so "whose device is
this?" is answerable. `bin/drivers.sh rig status` prints that column beside the
driver and relay ports.

**Never run bare `drivers.sh up`.** It walks every booted simulator — a ~30 s
xcodebuild each, and a peer's driver restarted under them mid-journey. Name
yours: `drivers.sh up <udid>`. It now lists the devices another session has
labelled before it does this, but the warning is not a substitute for naming the
device.

**Read the relay port on every call, never cache it.** Ports are pinned per
device since 17 Sep (item 73), but a Mac whose `$RDIR` has been cleared starts
the numbering again. `drivers.sh` prints the live table; `drivers.sh ports adopt`
writes down what is already running without restarting anything.

**Say so before you restart a driver.** The 16 Sep pair did: *"Told them to go
ahead — my measurements are finished, so there's nothing for them to
interrupt."* A driver torn down mid-journey costs the peer the run, not a call.

**Split the test data.** Those two sessions took store 4002 and store 4001 and
confirmed the split between themselves. Two sessions seeding and cancelling in
one store poison each other's evidence, and neither can tell.

**Share a toolkit finding immediately.** The `/swipeV2` finding (item 69) crossed
between them within minutes of being measured, which is why both days' sweeps
were re-examined rather than one.

## Read state from the app, not from pixels

Ranked by usefulness. Work down the list, not up it.

**1. The network layer.** A debug build exposes the Dart VM Service, and
`ext.dart.io.getHttpProfile` gives every request and response body. This is the
actual truth about what the app fetched and what the server said. In the session
it was not used until 12:22 — and only because the user suggested it. It should
be the first thing set up.

Discover the service URI *dynamically each time*; do not hardcode it. The
session baked `http://127.0.0.1:60895/5aWHtQPbv6o=` into `net.sh`, the app
restarted, and re-discovering the new port cost a whole cycle at 13:47.

```sh
xcrun simctl spawn "$DEV" log show --last 3m --style compact 2>/dev/null \
  | grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=+/-]+' | tail -1
```

**2. The view hierarchy.** `bin/driver.sh nodes` gives element text, resource
ids, frames and state flags in ~0.3 s, for whichever device `DEV` names. Use it
to choose the next action, and re-read it after any UI change.

`inspect_screen` on the MCP server reads the same thing at a similar speed, but
it can only ever address **the device on port 22087** — it ignores the
`device_id` you pass and returns whatever is there. With one simulator booted
that is harmless; with two it silently answers about the wrong one. Prefer
`driver.sh`.

**2b. The driver's own HTTP API.** The XCUITest driver serves the hierarchy and
screenshots itself, and it is readable from a plain `curl` here — no MCP call,
no JVM, no SSH. See "Reading the screen without Maestro" below. Use it when you
want the *raw* frames rather than Maestro's converted bounds, or when the MCP
server is not connected.

**3. Source code.** Reading the widget usually answers "why is this button
disabled" faster than any number of taps.

**4. Screenshots.** Only for questions genuinely about appearance — colour,
contrast, overflow, status-bar styling. `take_screenshot` is cheap now, but the
cost was never the transfer: measured across the original session, deciding the
next action took a median 17.9 s after reading an image against 6.6 s after a
hierarchy dump. An image is also where hallucinated selectors come from (reference/driving.md).

When one is warranted, take it with `driver.sh shot` and crop it to what the
question is about — `--on "^SCAN$"` cuts the picture to that element, `--scale`
shrinks it, and both cut the reading cost as well as the transfer. It also
arrives the right way up: a landscape iPad's raw picture is on its side, and
turning it by hand cost one session eight `sips` calls.

## Rules for driving

`maestro mcp` is registered as a user-scope MCP server (`maestro-mac`), running
over SSH. The harness holds one session open for the whole conversation, so one
JVM and one driver session serve every call. Measured on that Mac:

| operation | via MCP | as a fresh CLI call |
| --- | --- | --- |
| `inspect_screen`, first call | 4.1–5.1 s | — |
| **`inspect_screen`, thereafter** | **0.19–0.36 s** | 7.7 s (`maestro hierarchy`) |
| `run`, one action | 1.1–2.7 s | — |
| `run`, three actions | 3.6 s (~1.2 s each) | — |
| two-action flow | ~2.2 s | 17.6 s (`flow.sh`) |
| flow + hierarchy | ~2.4 s | 22.5 s |

Reading the screen is roughly 40x cheaper than it was. The 100 Maestro-bearing
calls that cost 35.3 minutes in the original session would now be 3–4 minutes.

The CLI path (`bin/flow.sh`, `bin/hier.sh`) still works, and unlike the MCP
server it honours `--device`. Everything below applies to all three paths.

### The loop

`bin/drivers.sh up` → `driver.sh nodes` → `driver.sh tapon` → re-read, once per
UI change, with `DEV=<udid>` selecting the device.

The MCP loop `list_devices` → `inspect_screen` → `run` still works for a real
Maestro flow, but every one of those tools resolves to the device on port
22087 whatever `device_id` it is handed. Take the UDID from `bin/drivers.sh`
rather than a remembered one either way.

### Still batch

Cheap calls are not free, and Maestro's own guidance says the same: prefer one
full flow over many single-command calls. A `run` of three actions costs 3.6 s
against 1.1–2.7 s for one. Put a journey in a flow, not a tap.

### Reading `inspect_screen` output

It returns compact JSON with two top-level keys: `ui_schema` (abbreviations and
per-platform defaults) and `elements` (the tree, nested via `c`). Keys are
abbreviated — `b` bounds, `txt` text, `rid` resource-id, `a11y` accessibility
text, `hint`, `cls`, `val`, `scroll`. Boolean flags (`clickable`, `checked`,
`focused`, `selected`, `enabled`) appear only when they differ from the default,
so read `ui_schema.defaults` before concluding a button is enabled. Zero-size
and empty-container nodes are filtered out.

**Those abbreviated keys are not selectors.** Map `a11y` onto `text:` when
authoring a selector; never pass `a11y` or `accessibilityText` as one.

The selector language is far larger than the cheat sheet implies. The full set,
from `docs/pages/reference__selectors__*.md`:

| kind | matchers | notes |
| --- | --- | --- |
| core | `text`, `id`, `index`, `point`, `css` | `text` is full-string regex, IGNORE_CASE. `id` is `accessibilityIdentifier` on iOS. `index` is 0-based. `css` is web only and takes no regex. |
| state | `enabled`, `checked`, `focused`, `selected` | booleans, combine with any core matcher. `focused: true` answers "did my tap land in the field I meant?" |
| traits | `traits: text` / `long-text` / `square` | `long-text` is 200+ characters. `square` is width and height within 3% — made for icon buttons |
| dimension | `width`, `height`, `tolerance` | pixel sizes from the accessibility tree, with a +/- buffer. Pair with `traits: square` when you know an icon's rough size but not its label |
| relational, screen | `above`, `below`, `leftOf`, `rightOf` | **computed from screen bounds**, so they inherit any bounds error |
| relational, tree | `childOf`, `containsChild`, `containsDescendants` | walk the accessibility tree; `containsChild` matches the *parent* of a known child |

`point:` accepts **absolute pixels as well as percentages** — `point: "200, 563"`
as readily as `point: "50%,64%"`. Percentages must be whole numbers (`59.5%`
fails with `For input string: "59.5"`), so absolute points are the more precise
of the two and are what you want when converting from hierarchy bounds.

### The hierarchy is a window, not an inventory

Flutter builds list children lazily, so anything scrolled out of a `ListView` or
a horizontal chip row is simply not in the tree. This is a Flutter property, not
a Maestro one — `inspect_screen` does not fix it. Seen in practice: a row of
size chips reported one range on the first read and a different one on the next,
because the scroll position had moved. Stating either as the full list is a
mistake; scroll the row and read again before claiming what it contains.

- Never state "the options are X" from a single read.
- To enumerate a scrolling list: scroll to one end, then step across collecting
  labels until nothing new appears — or better, read the list from the network
  response that populated it (the state-reading section).

### Two traps that cost real time

**`text:` is a full-string regex, case-insensitive.** A partial string does not
match. `text: "RNR 352"` misses an element whose real text is
`"RNR 352 - Expo Launch"`. Use the whole on-screen string or anchor it —
`"RNR 352.*"`. This is why the session's working selectors all looked like
`".*50532287.*"`.

**Copy `txt` values verbatim from `inspect_screen`. Never author them from a
screenshot.** An element showing a heart icon looks like a "Favorite" button in
an image and has no such text in the hierarchy. 74 of the 125 taps in the
original session were percentage coordinates eyeballed off a screenshot; every
mis-estimate cost a full round trip and failed silently, because a tap
"succeeds" on whatever happens to be under the finger.

Coordinates remain a last resort for genuinely unlabelled targets — and then
take `b` from the hierarchy rather than guessing.

### When the bounds themselves are wrong

Maestro is strictly black-box: it reads whatever the accessibility layer reports
and applies no transform of its own
(`docs/pages/get-started__supported-platform__flutter.md`, and confirmed from
the code in `reference/driver-api.md`). So when bounds are wrong, they are wrong
in the app — and *every* selector that resolves to an element taps the wrong
place, `text:` included. **`tapOn: "<some label>"` is not an alternative to
coordinates.** It is a tree lookup followed by a tap on that element's bounds
centre. The rule "address elements by text, never coordinates" silently assumes
the tree is trustworthy.

Where that assumption fails, the whole selector language fails with it —
`childOf`, `index`, traits, relational matchers all end at the same wrong
coordinate — and the only way through is to compute the true point from the
hierarchy and tap it directly.

**The rule.** A container's first child may be a **marker**: a node whose frame
is the whole screen divided by some factor `k`. It defines the coordinate space
for that container's children:

```
absolute = reported * k - markerOrigin * k
```

Two very different-looking faults are that one expression. A marker of
`0,0 134x291` on a 402x874 screen gives `k = 3`, so its siblings are at a third
scale and get multiplied by three. A marker of `-47.6,-363 402x874` gives
`k = 1` with an offset, so its siblings are local coordinates inside an overlay
and get the origin subtracted.

Three things about it are easy to get wrong:

- **The marker is a sibling of the content, not an ancestor.** Walking up the
  parent chain from a mis-placed element finds nothing but full-screen
  containers. That is why this resists arithmetic and pushes you towards
  measuring a screenshot.
- **Markers replace rather than compose.** An overlay marker inside a 1/3-scale
  space has a full-scale frame of its own, so the outer factor is discarded
  rather than multiplied in.
- **Screen width alone does not make a marker; the height must divide by the
  same factor.** That is what stops a status bar (`402x54`) or a keyboard's
  scroll extent (`402x1245`) from shifting its subtree.

**You do not have to apply this by hand.** `bin/resolve.py` implements it and
`bin/driver.sh` uses it for `find`, `point`, `tapon`, `type`, `expect` and
`expect-not`. When an answer looks wrong, `driver.sh find <pattern> --explain`
prints every marker it applied, so the rule stays checkable rather than trusted.

**Never carry a transform between reads.** Whether it applies can change as a
journey proceeds — the same screen can report correctly on a cold launch and at
a third scale a few taps later. Derive it from the tree on every read, which is
what the resolver does.

**Work it out; do not eyeball it.** Every tap derived by arithmetic in the
original session worked, and every tap estimated by eye off a screenshot missed.
Screenshots are ground truth for *what* a thing is, never for *where* it is.

**If you find yourself measuring a screenshot, your hierarchy dump is hiding
something.** `driver.sh tree` prints only nodes carrying a label or an
identifier, which throws away every unlabelled container — and the containers
are exactly what carry the origins the arithmetic needs. `driver.sh nodes`
prints every node. Reach for it the moment a position does not add up.

A worked case, with the measurements, is in `reference/apps/example-app.md`.

### When there is no selector at all

The section above is for a control the tree reports at the wrong place. This one
is for a control the tree does not report *at all* — no label to match, or no
frame to tap. Three shapes of it have turned up:

- **A container with no frames in the hierarchy.** An iPad navigation rail can
  carry nothing in the accessibility tree — no node, so no selector of any kind
  reaches it. It taps only by coordinate.
- **An unlabelled icon button.** A pencil, trash, tick, cross or gear with no
  `txt` and no identifier. `tapon` has nothing to resolve.
- **An unlabelled free-text field.** A sheet's text box with no accessibility
  label; the field is there but no selector names it.

For all three the only way in is a raw `driver.sh tap <x> <y>`, and the point is
fragile on four independent axes — each has cost a real session:

- **Keyboard.** A point read with the keyboard down moves once it is up.
- **Text size.** A larger dynamic-type setting shifts the layout under the point.
- **Orientation.** On the iPad rail the safe-area inset moves between
  orientations — the numbers hold in `landscapeLeft`/`landscapeRight` and miss
  the top item in `portrait`. Set the device to the app's orientation first
  (`driver.sh orient …`), the same discipline as item 57.
- **Device size.** A point tuned on one screen misses on another: a journey
  calibrated on an iPhone 16 Pro had nothing past the opening swipe land on a
  16 Pro Max. **A raw-coordinate journey is device-specific unless proven
  otherwise** — one that must run on several sizes has to resolve by `tapon` at
  run time, or carry a per-device coordinate set.

And the failure is **silent**: a `tap` on the wrong point reports success, so a
mis-derived coordinate reads as "the control did nothing" rather than "I missed".

**So, when a target has no selector:**

1. Derive the point from `driver.sh nodes`, not a screenshot — `nodes` prints the
   unlabelled containers `tree` hides, which is exactly where the origins are.
2. Re-read and re-derive on every session and every device; never trust a stored
   coordinate. Tag any value you carry **DERIVED, NOT MEASURED** until a real tap
   confirms it moved the state.
3. Assert the state moved (`expect`), because the tap alone will not tell you.

The measured values for a given app are the project's and live in its own notes,
not here; `reference/apps/example-app.md` shows the shape with worked numbers.
This is the case item 57's raw-`tap` fallback exists for, and the one the
journey-first hook (item 51) exempts — a raw tap is legitimate exactly where the
tree carries nothing to match.

### `enabled: true` does not mean tappable

Two failure modes that look identical in the tree:

- A control that renders differently when it is not selectable but reports the
  same `elementType`, the same `enabled: true`, the same `selected: false`, no
  trait and no identifier. The only thing separating it from a working one may
  be its frame height. Compare frames within a row of peers and treat an outlier
  as a different control.
- A button with no handler attached, which reports enabled and swallows the tap.

Neither is visible to a Maestro matcher, so `enabled:` is worth less than it
looks. Where a tap should have caused a network call, look for the call rather
than re-reading the UI:

```sh
./bin/mac.sh 'xcrun simctl spawn <udid> log show --last 90s --style compact \
  --predicate "processImagePath CONTAINS \"Runner\"" | tail -40'
```

That is the fallback when the Dart VM Service is not available — it only exists
when the app is started by `flutter run`, and an app launched any other way
(including by `launchApp`) has none, so `bin/net.sh` and `bin/publish.sh` come
back empty. The simulator log is coarser, but it distinguishes "the app tried
and failed" from "nothing happened", which is usually the question. Check
whether the app polls on a cycle before treating any traffic as yours.


### A resolved point is not always a reachable one

Two ways a frame reported as an ordinary visible element cannot be tapped:

- **It is underneath the keyboard.** A dropdown attached to a search field
  raises the keyboard over the bottom third of the screen. The list rows below
  that line are still reported with their real frames, enabled and unflagged. A
  tap on one lands on the typing-prediction bar instead. Seen on 11 Aug 2026: a
  tap aimed at a list row at y=543, with the keyboard's top edge at y=538, typed
  `The ` — the middle QuickType suggestion — into the field.
- **It is below the fold.** A button under a section that has just expanded
  reported y=1012 on an 874-point screen. The tap is accepted and goes nowhere.

`bin/resolve.py` now refuses both rather than tapping: a point outside the
screen, or one at or below the top of the keyboard, exits 5 with the reason,
and `find` prints `!!` against the offending match. `--anyway` overrides it.
Deriving the keyboard's top edge needs one filter — the prediction bar carries
a scroll extent of `402x1245` at `y=-62`, and taking the minimum without
discarding frames taller than the screen puts the "keyboard" over everything.

**The refusal shows its working, because one was disbelieved.** On 12 Aug a
refusal was read as a false positive and overridden, and the tap typed a stray
character into the field underneath. It had been correct: the keyboard was over
a dropdown that looked, in the screenshot, as though it sat above it. So the
message now gives the edge, the distance, and where the edge came from:

```
resolve: /^SETTINGS/ is at [40.2, 804.5], which is UNDER THE KEYBOARD — the tap
will hit the keyboard instead
  the keyboard's top edge is y=569 and this centre is 235.5 points below it
  569 is the 874-point screen less the keyboard's thickness of 305, measured
  from SystemInputAssistantView 402x72 and keyboard 402x233 — sizes, not
  positions, because the keyboard reports its position in the device's own
  space rather than the app's
```

That last clause is the one that matters. The containers' *positions* are in
the device's space and cannot be compared with the element's, which is what
made the guard wrong in both directions until 12 Aug — so a message quoting a
position next to an app-space edge would invite exactly the mistake it is
trying to prevent. Only the size is used.

The off-screen refusal says which way and how far rather than "scroll it into
view", and warns that a node reported `0,0 0x0` is off a scrolling container's
viewport, where dismissing the keyboard does not bring it back.

The fix in a journey is `dismiss` (below) or a `swipe` before the `tapon`, and
then an `expect` on what the tap actually did. **Not** typing to filter a list
and pressing return to commit the match: that was recorded as the working
method for this exact situation and measured wrong on 13 Aug — the list does
not always filter, and return can commit the first row rather than the one that
was typed. `reference/apps/example-app.md` has the correction.

### Putting the keyboard away

There is no route for it. The driver's client names eighteen and not one of
them hides the keyboard, because iOS exposes no API to do it. Maestro's own
`hideKeyboard` is Kotlin in the client — swipes from the middle of the screen,
then a check — which upstream documents as flaky, recommending a tap on
something non-interactive instead.

`driver.sh dismiss` tries both things that can work, harmless one first, and
reads the keyboard back after each:

1. **A tap on the emptiest point on the screen.** `resolve.py --blank` picks
   it: the point furthest from anything carrying text, anything whose element
   type reacts to a tap, anything iOS drew, the keyboard's own band, and the
   edges of the screen. `driver.sh blank --explain` prints the point, how much
   room it had and what the nearest thing was.
2. **`key return`**, if the keyboard is still up. This one submits whatever had
   focus, so `dismiss` says when it was the method that worked — on a dropdown
   with its list open the app may have committed a row. `--no-key` stops
   before it.

**Which of the two works is a property of the app, not of iOS.** Measured on
the app under test on 13 Aug 2026: six taps on different blank parts of the
sign-in screen and one swipe left the keyboard up every time, and `key return`
put it away every time — the exact opposite of what upstream recommends. A
Flutter app only unfocuses on a background tap if it was written to; most are
not. So neither method can be assumed, and the verb reports which one it used.

Two things `dismiss` cannot do. It cannot see a tap target the accessibility
tree does not report — a Flutter gesture detector with no semantics node, an
invisible scrim — so the tap it calls harmless may not be. And on a screen the
app fills edge to edge with tappable rows there is no blank point at all, which
it says rather than tapping something anyway.

One correction it also settles: on 13 Aug a session concluded from three
attempts that this keyboard would not drop at all. Each reading was taken after
a command that had already re-tapped the field and raised it again. `key
return` had worked.

### A field's placeholder is not a stable selector

An empty text field's only text is its placeholder; once it holds a value the
placeholder is gone. So `type "^Search$" "..."` works on the first search of a
session and matches nothing on the second, because the field now reads
`5012345678900`. Either match both states and clear first —

```
clear "^(Search|[0-9]{8,})$"
text "${BARCODE}"
```

`clear` long-presses the element, taps "Select All" from the iOS edit menu,
and deletes the selection — the only reliable way to empty a field whose caret
position is unknown. `erase [n]` deletes backwards from the caret and leaves
anything ahead of it; `erase --all` sends 9999 backspaces, which helps only
when the caret is already at the end. Prefer `clear` for replacing a field's
contents.

Keep two units and pick by situation when the cost matters. Measured on 11 Aug
2026 the clearing version costs about 7 seconds a run: `erase` is 2.9s on its
own (roughly 2.2s fixed plus 0.03s a character), `clear` adds a long-press and
a resolve, and splitting one `type` into tap/clear/type adds settle waits. That is why this journey has both a
`03-search.journey` for the first, empty visit and a `03-search-again.journey`
for later ones, rather than paying for the clear every time.

### `isScreenStatic` is false while a spinner turns

The settle wait is not only about animation finishing — a screen loading from
the backend keeps reporting movement, so the timeout has to cover the request.
A screen waiting on a slow request came back late on 11 Aug and failed a run at
the old 10-second limit. `_settle` now defaults to 20s, overridable for a whole run with
`SETTLE=<seconds>`. A longer limit costs nothing when things are quick, because
it returns the moment the screen is still.

### Forcing a timed state

When a feature fires on a timer (idle logout, session expiry, a refresh
interval), force the timing through the app's configuration (Remote Config,
environment variables, a feature flag) rather than editing the source. A
source edit means a rebuild on all target devices, and the round-trip latency
of driving over SSH eats into short timers — a 45-second fudge lost 15 seconds
to driving overhead and the modal arrived before the shot.

If only a source change works: give the timer enough headroom for driving
latency (~30 seconds minimum), rebuild from clean source before any real
verification afterwards, and note in the journey what the original value was.

### Read the app's supported orientations before choosing a device

`preflight.sh` now prints the app's `UISupportedInterfaceOrientations` and
`~ipad` arrays from its `Info.plist`. A landscape-locked app has no portrait
iPad layout: chasing one wastes time and produces wrong coordinates (the newer
iPad letterboxes a landscape-locked app, making its coordinate space narrower
than the device). Check the preflight output before choosing an iPad simulator.

### Reading the app's persisted preferences

`bin/prefs.sh` reads `NSUserDefaults` from the simulator's data container.
It backgrounds the app first — iOS flushes lazily, so freshly-written keys
are not on disk until the app leaves the foreground. Without that step the
read comes back missing keys that are really there, which looks like an app
bug rather than a timing artefact.

```
bin/prefs.sh                    # flutter.* keys (the default filter)
bin/prefs.sh idle_logout        # keys matching a pattern
bin/prefs.sh --all              # everything
```

`defaults read` cannot see the app's container domain; the plist is read as
a file from the container path. On a physical device, `devicectl device copy
from` pulls the file — the syntax is easy to get wrong, and a helper that
owns the exact invocation removes that.

### "From scratch" rarely means relaunched

Check what a relaunch actually restores before treating it as a reset. One app
here restores its whole session, so a journey starting with `kill` / `launch`
and expecting the login screen passes once and fails every run after it; the
only route back was signing out through the settings screen. Put the reset in
its own journey file, and say in a comment what state it assumes.

### Assert, do not assume

Maestro reports success for a tap that landed on nothing useful. Follow every
screen change with `assertVisible` / `assertNotVisible` / `extendedWaitUntil`
**inside the same flow**, so a wrong assumption fails within the batch. Seen at
12:16 in the session this came from: a `tapOn:` on a size chip reported
COMPLETED, the button behind it stayed disabled, and the run carried on
regardless.

### Flows through the MCP server

`run` takes exactly one of `yaml` (inline — best for exploration), `files`, or
`dir`. Pass `env` for flow variables. Mobile flows must declare `appId` and
normally start with `launchApp`.

Two gotchas found by hitting them: the inline argument is `yaml`, not
`flow_yaml`; and the YAML must include the `appId:` header and the `---`
separator, or it fails with "Config Section Required".

The MCP server's working directory on the Mac is the login account's home
directory, not the repo, so `files`
and `dir` need **absolute** paths. Keep the flow library in the repo and
reference it fully:

```
<absolute path to the flow on the Mac>/setup.yaml
```

### Stop reading and deciding between calls

Making each call fast does nothing if the number of calls stays the same. A
full run on 11 Aug 2026 took seventeen minutes and about forty-five tool calls,
of which the device work was **under a minute**: 25 actions at 0.3–1.1 s and a
dozen hierarchy reads at 0.28 s. The rest was ninety seconds of blind `sleep`,
six minutes of a side investigation, and — mostly — one action per round trip,
each round trip spent reading a tree, doing arithmetic and choosing the next
tap. The tooling had stopped being the bottleneck several passes earlier.

So the resolution above is only half the fix. The other half is that
`driver.sh` now takes whole sequences:

```sh
./bin/driver.sh tapon "^CONTINUE$"        # resolve, tap, wait for settle
./bin/driver.sh type "^Search$" "some text"
./bin/driver.sh expect "^Home$"
./bin/driver.sh script login.journey search.journey
```

Journeys cover the sequences you already know. Exploration is where the time
actually went, and there the shape of a call is act, then look. `--tree` or
`--nodes` directly after the verb does both in one invocation:

```sh
./bin/driver.sh tapon --tree "^CONTINUE$"
./bin/driver.sh tap --nodes 200 483
```

It is read only in that position. `type` takes the rest of its line as the text
to type, so a flag on the end would be typed rather than obeyed, and the tests
hold that both ways round. The screen prints whether the action succeeded or
not: a failed resolve is exactly when you want to see what is actually there.

A journey is a text file of those lines, `include` chains one into another, and
`${VAR}` comes from the environment — format in `reference/journeys.md`. A
login sequence that was re-derived tap by tap three times in the original
session, at roughly fifteen round trips each, became one call of about nine
seconds. A whole end-to-end journey on the same app — sign out, sign in,
configure it, search, choose from the results, add to a basket — is 34 steps and
about 48 seconds, six runs inside a 2.4 s spread.

Be clear about where that saving comes from, because it changes what to
optimise. The same 34 actions issued as 42 separate `driver.sh` invocations
took 55.3 s against 47.8 s for the journey: **one process instead of many is
worth 7.5 seconds**, about 0.18 s an invocation. Everything else — the other
fourteen and a half minutes — was the model reading a tree and deciding the
next action between each call. The device work was already under a minute
before any of this. So batching is not about saving process startup, and making
the calls faster still would buy almost nothing. It is about not being in the
loop for a sequence whose shape is already known.

Two rules that make this safe rather than merely fast:

- **Never add a `sleep`.** Every action verb waits for the screen to go still
  before it returns — `isScreenStatic` costs 0.15 s and answers the actual
  question. A fixed sleep on top is either too short, and you read a half-drawn
  screen, or too long, and you paid for nothing. Counted across the four
  sessions in `BACKLOG.md`: 154 sleeps, 88 of them in one session. `SETTLE=0`
  is the escape hatch for a screen that never stops moving.
- **Assert inside the batch.** `expect` / `expect-not` between the actions is
  what stops a batch becoming a longer version of the original session's
  failure mode, where a tap reported COMPLETED and the run carried on. A
  journey stops at the first failure and prints the tree as it stood.

Measured from the sandbox: `/deviceInfo` 0.15 s, `/viewHierarchy` 0.28 s,
`/screenshot` 0.27 s, `driver.sh tree` 0.33 s end to end. That is as fast as
`inspect_screen` through the MCP server and 25x faster than `maestro hierarchy`
over SSH, with no JVM start.

`/viewHierarchy` needs a POST body of `{"appIds":[...],"excludeKeyboardElements":
true/false}` — a GET, or a POST with an empty object, returns `incorrect request
body provided`. The field names came out of the driver binary's Swift symbols
(`ViewHierarchyRequest`), not the documentation; none of this API is documented.

Two reasons to reach for it rather than `inspect_screen`:

- **It returns the raw `XCUIElementSnapshot` tree**, with `frame` in device
  points, plus `elementType`, `hasFocus`, `windowContextID`, `displayID` and
  size classes. That is the input Maestro converts into the bounds it reports,
  so comparing the two separates an app problem from a Maestro problem.
- **It does not need the MCP server, and it is per device.** Each simulator has
  its own driver on its own port (`bin/drivers.sh`), so `DEV` selects the
  device and several can be driven at once — which the MCP server cannot do at
  all.

## Preflight

**First, start the wall and post its URL.** Asked for explicitly on 11 Aug
2026: whenever remote testing starts, put a watchable URL into the session on its
own line, somewhere obvious, so the work can be watched rather than taken on
trust. Do this before anything else, not when asked.

```sh
./bin/wall.sh                 # -> http://<mac>.local:9990/
```

Every booted simulator, live, on one page, from a port that does not move. It
spawns Maestro's capture binary per device and leaves the XCUITest drivers
alone, so starting it mid-run is safe.

This replaced `./bin/viewer.sh` on 15 Sep 2026. Maestro's own viewer cannot be
watched from anywhere but the Mac: the stream URL it gives the browser is an
absolute `http://127.0.0.1:<random>/stream.mjpeg`, and it attaches a device only
when exactly one simulator is booted. Both were measured; backlog 64 and 65.


Before any testing, one SSH call should answer all of this. The session
discovered each fact separately, at cost.

```sh
./mac.sh '
  echo "== git ==";     git rev-parse --abbrev-ref HEAD; git status --short | head
  echo "== booted ==";  xcrun simctl list devices booted
  echo "== flutter ==";  pgrep -fl flutter_tools | head -2
  echo "== maestro ==";  maestro --version
  echo "== drivers =="; pgrep -f maestro-driver-iosUITests-Runner | wc -l   # or: bin/drivers.sh
  echo "== vmservice =="; cat /tmp/hb_iso 2>/dev/null
'
```

Then `./bin/drivers.sh up`, which starts a driver per simulator (~30 s each,
once) and gives hierarchy and screenshot reads at 0.3 s each for the rest of the
session, on any of them, MCP server or not.

Note that Maestro needs `JAVA_HOME` and its own bin on `PATH`, and a
non-interactive SSH shell has neither. Every remote call must export them —
that is what `mac.sh` is for. A login shell (`zsh -ic`) works for Flutter/fvm
but is slower and noisier; use it only where fvm shims are actually needed.

## Traps worth knowing before you meet them

- **The Mac's network config.** The whole of 10 Aug 15:20 → 11 Aug 11:00 — 119
  tool calls, 74 SSH attempts, roughly four hours of the user's time across two
  days — went on getting a connection. Root cause was a netmask of
  `255.255.255.0` on a `/22` network, so the Mac's replies never reached the
  Linux box. **Rule: when SSH times out at banner exchange but ARP resolves and
  packets arrive, get `ifconfig en0 | grep "inet "` from the Mac immediately and
  compare the mask against the Linux side's prefix.** One question would have
  replaced hours of guessing.
- **Do not re-propose an option the user has rejected.** At 15:47 on 10 Aug:
  "I'm not doing option a, stop asking."
- **App restarts invalidate the VM service URI and the isolate id.** Re-discover
  both after any `flutter run`, install, or relaunch.
- **`git stash` around branch switches** for `ios/Podfile.lock` and
  `pubspec.lock` — switching branches to compare against `development` needs
  them stashed, and the rebuild afterwards is ~1 minute each way.
- **Read the tooling before driving it, and finish reading.** Three times in one
  session the pattern was: read a little, find something genuinely useful, and
  go straight back to tapping without finishing the sweep. Each early stop left
  a fix on the table — `cheat_sheet` unread while fighting selectors, the docs
  index unopened while inventing workarounds for documented problems, the app's
  own source unread while reverse-engineering its coordinate spaces from
  screenshots. One pass is not enough; the second and third passes both found
  more than the first.
- **The tools that answer a question are often not the ones being used.** The
  network layer is ranked top in the state-reading section and tooling for it was written, tested and
  then ignored for an entire run. Before the next long journey, check the list
  in reference/maestro-notes.md against the problem actually at hand.
- **A fifth pass still found new things, and the biggest one yet.** Each of the
  first three sweeps claimed to be complete. The fourth turned up the driver's
  HTTP API, the artifact bundle every run already writes,
  `snapshotKeyHonorModalViews`, and CLI flags the documentation does not
  mention. The fifth found that the same driver API *writes* as well as reads —
  taps, text, keys, swipes at raw coordinates — which sidesteps the coordinate
  problem that had absorbed most of two sessions. It also found that the
  published default for `MAESTRO_DRIVER_STARTUP_TIMEOUT` is simply wrong.
  Diminishing returns have not set in yet. Treat "I have read
  it all" as a hypothesis.

### Home-directory dotfiles appearing at the repo root

Two sessions independently found `.bashrc`, `.zshrc`, `.profile`, `.gitconfig`,
`.bash_profile`, `.gitmodules` and `.idea` appearing untracked at the checkout
root during driven reviews. The cause is unknown — it may be the sandbox, GSD,
or an IDE. The hazard: `git add .` or `git commit -a` sweeps them into a PR
branch. Stage only named files during a review, and add these to the project's
`.gitignore` or the global gitignore (`~/.config/git/ignore`):

```
.bashrc
.zshrc
.profile
.bash_profile
.gitconfig
.gitmodules
.idea/
.mcp.json
```
