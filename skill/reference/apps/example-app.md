<!--
  A WORKED EXAMPLE, not a real app. Every name, code and number that identifies
  an app is invented — the same fictional retail app used in
  reference/journeys.md, so the two read together. The measurements are real:
  they were taken on an iOS app whose accessibility tree could not be trusted,
  and they are what notes like these are for.

  A real project's notes live in the project, at maestro/app-notes.md, made from
  reference/app-notes-template.md. Nothing app-specific ships with this skill.
  This file exists only so you can see what a filled-in one looks like after two
  days of work, before writing your first.

  Notes written from day 4 carry a confidence marker — measured, seen once,
  inferred — which bin/notes.sh add now requires. The earlier ones predate the
  convention and should be read as `seen once`, which is exactly the trouble:
  two of them below were relied on for two days and were wrong. The day-4
  entries show what correcting a note looks like — the wrong one stays, marked,
  with the measurement beside it.
-->

# App notes — example-retail

App: `com.example.retail`
Started: day 1

Devices these notes were measured on:

| device | UDID | iOS | space the app reports in |
| --- | --- | --- | --- |
| iPhone 16 Pro | `<udid>` | 18.6 | 402x874 points at scale 3 |
| iPad Pro 11-inch | `<udid>` | 16.4 | 1194x834 landscape, on a portrait 834x1194 device |

## Known test data

- (day 1) Stores known to exist: 42, 77, 108. The PIN is 1234 on all of them.
- (day 1) A product with stock: code `0001`. Ask for data rather than hunting for a product that happens to have stock — that hunt cost 55 minutes.
- (day 2) A scanned code identifies a PRODUCT, not a requestable variant. `0002` resolves to a real item whose sizes all sit in a range with no stock anywhere, so it cannot be selected. A code scanning successfully is not evidence that anything can be ordered from it.

## Journeys

| journey | starts on | leaves you on | notes |
| --- | --- | --- | --- |
| `01-signin.journey` | cold launch | Home | takes `STORE`, `PIN` |
| `02-search.journey` | Home | product detail | takes `CODE`; field submits on return |
| `03-add.journey` | product detail | My Basket | two swipes — sizes start below the fold |

- (day 2) What batching buys, measured: signed-out app to a populated basket is 34 steps and about 48 seconds in ONE `driver.sh script` call, six runs inside a 2.4 s spread. The same sequence by hand took 15.4 minutes. Of the saving, 7.5 s is process startup and the rest is not stopping to think between steps.

## Does this app report bounds correctly?

**No, and that decides everything else.** Establish this first on any app.

- (day 1) Three coordinate spaces on iPhone alone. The status bar and most screens are correct. The sign-in screen reads at **1/3 scale** — a content box `[0,0][134,291]` against a 402x874 screen, so multiply by 3. `DropdownMenu` overlay items read in the overlay parent's local space, so subtract the parent's origin. The iPad adds a fourth: the app is landscape-locked at 1194x834 while taps go to the device in portrait, so `device_x = 834 - app_y`, `device_y = app_x`. **(See the correction below — do not hand-apply this on a `tapon`.)**
- (correction, from the driver source — not a device measurement) The iPad clause above is wrong as an instruction. `/touch` coordinates are portrait-referenced and the driver rotates them itself in landscape — `ScreenSizeHelper.orientationAwarePoint` is the identity in portrait and rotates the point in landscape (`reference/driver-api.md`, the driver-API routes). So resolve and tap with `tapon` and send app-space (portrait) coordinates; do **not** hand-apply `device_x = 834 - app_y` on top, because that transforms a point the driver then rotates again. That double transform is the likely reason a hand-converted `tap 599 962` did nothing on two attempts on 19 Aug (`2696b9ae`) while `tapon "4001-55368"` opened the same card first time. Set the device to the app's orientation first (`driver.sh orient landscapeLeft`), then `tapon`. Measured 11 Sep on a `landscapeLeft` iPad Pro 11-inch: a raw `tap` at the resolver's app-space point selected the target, the hand-rolled `834 - app_y` point missed, and `find --explain` showed the true transform is a pure offset with no rotation term. So the hand-transform is not a fallback either — it lands nowhere in this state. The raw mapping `device_x = 834 - app_y`, `device_y = app_x` is kept only as the historical note that started this (item 57).
- (day 2) **The scale is a state, not a property of a screen.** On the sign-in screen the state is whether the dropdown overlay is open: full scale on a fresh launch and while the menu is open, 1/3 once the menu has been opened and closed even once, full scale again when it is reopened. Relaunching with a value already saved reads 1/3 straight away. Never carry a scale factor between reads — re-derive it from the tree every time, or compare a reported bound against the screen size, because a content box narrower than about a third of the screen means the tree is scaled.
- (day 2) Worked example. The menu item `English` sits at local `[0,64][326,112]` under a parent at `[-37,-475][364,398]`. Absolute is `[37,539][363,587]`, centre `(200, 563)`, and `point: "200, 563"` selected it first time. The raw bounds centre `(163, 88)` is near the top of the screen, which is exactly where `tapOn: "English"` had been landing and silently failing. Note the sign: absolute = reported **minus** the parent's origin.
- (day 2) The marker node is a **sibling** of the content, not an ancestor — walking up the parent chain finds nothing but full-screen containers, which is why this took so long to see. Markers replace rather than compose: an overlay marker inside the 1/3 space has a full-scale frame of its own, so the outer factor is discarded, not multiplied in. And screen width alone is not enough to identify a marker — the height must divide by the same factor, which is what stops the status bar and the keyboard's scroll extent from shifting their subtrees.
- (day 2) Maestro is not the source. The same screen read by `driver.sh tree` and by `inspect_screen` agreed element for element on a normal screen, on the overlay's offset space and on the 1/3 state. The wrong numbers are already in the tree the driver reads, so there is no conversion bug to file and no reason to repeat the comparison.

## Controls that lie about themselves

- (day 2) The size chips come in two renderings. The ones backed by stock are 48 points high and select when tapped; the rest are 25 points high and do nothing. In the tree they are IDENTICAL — same `elementType`, same `enabled: true`, same `selected: false`, no trait, no identifier. Only the frame height separates them. So `enabled:` as a matcher is worth nothing here; compare frames within a row of peers and treat an outlier height as a different control.
- (day 2) The `CHECKOUT` button reports `enabled: true`, accepts a tap inside its frame and does nothing, because the request it builds is missing a field the backend needs. A control that reports fine and has no working handler behind it looks exactly like a tap that missed.
- (day 2) When a tap should have caused a network call, look for the call rather than re-reading the UI. The Dart VM Service only exists when the app was started by `flutter run` — an app launched any other way, including by `launchApp`, has none, and `bin/net.sh` comes back empty. The fallback is `xcrun simctl spawn <udid> log show --last 90s --style compact --predicate 'processImagePath CONTAINS "Runner"'`, which is coarser but distinguishes "the app tried and failed" from "nothing happened". This app polls on an 8-second cycle, so read timing against that baseline rather than treating any traffic as yours.

## Screen quirks

- (day 1) Sign-in: the store and location fields are SEARCHABLE textfields. Tapping one raises the keyboard AND opens the list, and the list renders UNDER the keyboard, not over it. The resolver's "under the keyboard" refusal is correct here — overriding it with a coordinate tap hit the keyboard and typed a character into the field.
- (day 2, seen once, **wrong — see day 4**) Working method for those fields: tap the field, `driver.sh text "<exact value>"` to filter, then `driver.sh key return`. Return commits the filtered match and dismisses the keyboard in one go. Tapping the list item never works.
- (day 4, measured) On a clean install, every clause of the day-2 note is wrong, and it was written from one observation that happened to land on a value the app did commit. Measured on the same screen, same build: **the user field filters as you type; the location field, built from the same widget, does not filter at all** — seven entries in, seven entries still showing. `key return` dismisses the keyboard, commits nothing and leaves the list open. Tapping the row is the thing that always works. The failure this caused reads as an app bug and is one: with the list unfiltered, `return` takes the first entry, so asking for `LOC1` set the device to `4001` and the run reported success.
- (day 5, measured) The day-4 note says `key return` dismisses the keyboard, and that is right — but it was written as though it were general, and it is not. Measured on the same screen: a tap on six different blank areas and a swipe from the middle all left the keyboard up, and `key return` put it away every time. So on this app the method upstream recommends does not work and the one it warns about does. `driver.sh dismiss` tries them in that order and says which one it used.
- (day 5, measured) A day-4 reading that said the keyboard would not drop at all was wrong, and the mistake is worth naming because it is easy to repeat: each check ran `tapon` on the field again before reading the keyboard, so it was measuring a keyboard that had just been raised. Read the state in a call that does nothing else.
- (day 4, measured) Two consequences for anyone driving a list like this. Assert the committed value with `expect` after the step — `type` reads back what landed in the *field*, which was correct here, and cannot know what the app then did with it. And do not generalise from one field to the field beside it.
- (day 2, and see day 4 above — it is worse than this) The same-looking dropdowns on the Settings screen behave DIFFERENTLY — the list opens with no keyboard and rows are tappable directly. Only the first-run screen raises the keyboard over the list. Two screens that look identical are not evidence that they behave identically.
- (day 2, seen once, **not reproduced — see day 4**) A dropdown left open in one `driver.sh` invocation is CLOSED by the time the next one runs. Open-then-tap has to happen inside a single call or a single journey, otherwise the tap lands on the closed field and the value never changes.
- (day 4, measured) Tried again deliberately: a dropdown opened in one invocation was still open across four more, including two `tree` reads. Whatever closed it that day, it was not the invocation boundary. Batching into one call is still the right habit for speed, but not for this reason.
- (day 2) Tab-bar buttons carry trailing accessibility text (`SETTINGS` plus `Tab 1 of 4`), so a both-ends anchor like `^SETTINGS$` never matches. Anchor the start only: `^SETTINGS`.
- (day 2) The list card is ONE node whose label is the whole card, newline-joined: `Order ID\n42-98066\nOpen\nA Name\n11:37`. Match a substring; a both-ends anchor cannot work.
- (day 3) The iPad nav rail is INVISIBLE to the accessibility tree. A screenshot shows five tabs down the left 322pt strip; `driver.sh nodes` reports nothing at all in `x=0..322`. There is no selector for any tab on iPad — reach a different one by resetting state and re-running the setup journeys.

## What a reset actually means

- (day 1) `launchApp: clearState: true` clears the store and PIN, so every run starts from sign-in. It does NOT clear the "Open in ..." choice iOS remembers for a deep link, and it does not clear the keychain — copying prefs to a second simulator without the keychain leaves the app resetting them on launch.

## Open questions

- (day 3) Deep links: `Info.plist` declares a URL scheme, but which paths the generated router accepts is unknown. If `openLink:` can reach the main screen directly, the whole sign-in journey collapses to one command. Expect a system dialog on the first deep-link launch — the choice is permanent for that simulator and `clearState` does not reset it, so guard it with `runFlow: { when: { visible: 'Open in' }, commands: [ tapOn: Open ] }`.
- (day 3) `integration_test` runs inside the app process and can assert on state directly. For "is this button enabled and why", that is likely faster than reading the UI from outside. Untested.
