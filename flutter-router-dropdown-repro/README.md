# MaterialApp.router + DropdownMenu reports iOS accessibility frames at 1/dpr

Reproduced 11 Aug 2026. Flutter 3.41.9 stable, iPhone 16 Pro simulator,
iOS 18.6, device pixel ratio 3.

## What happens

On iOS, an app built with `MaterialApp.router` reports its whole accessibility
tree at 1/devicePixelRatio once a `DropdownMenu` has been opened and closed.
Nothing on screen moves; only the frames handed to the accessibility layer
change. The same app built with `MaterialApp(home:)` is correct throughout.

`main.dart` is the whole reproduction — 60 lines, stock `flutter create`
project, no third-party packages. `kUseRouter` switches between the two.

Measured on the caption text, reading the XCUITest hierarchy:

| | `kUseRouter = true` | `kUseRouter = false` |
| --- | --- | --- |
| on launch | `68,388 265x20` | `68,388 265x20` |
| menu open | `68,388 265x20` | `68,388 265x20` |
| menu closed | **`22,129 88x6`** | `68,388 265x20` |

`22,129 88x6` is `68,388 265x20` divided by 3, the device pixel ratio.

## Why it is a real problem

Every tool that drives the app through the accessibility tree — XCUITest,
Appium, Maestro — reads those frames and taps the wrong place. It is silent:
the tap lands near the top of the screen and simply does nothing.

The direction is worth noting. Flutter's root view transform is
`Matrix4.diagonal3Values(dpr, dpr, 1)` and iOS divides by the same ratio on
the way back out, so frames at 1/dpr mean that multiply is **missing** on the
subtree rather than applied twice.

## How it was narrowed down

Each row is a separate cold launch, not a hot restart. Hot restart carries the
state over and gives misleading answers.

| app shape | flips? |
| --- | --- |
| `MaterialApp(home:)` | no |
| `MaterialApp.router` + auto_route, screen as the initial route | yes, on close |
| `MaterialApp.router` + auto_route, screen pushed as a `CustomRoute` | yes, on open |
| `MaterialApp.router` + hand-written delegate, `Navigator(pages:)` | yes, on close |
| `MaterialApp.router` + hand-written delegate, `Navigator(onGenerateRoute:)` | yes, on close |

So it needs neither auto_route, nor `provider`, nor `easy_localization`, nor
the declarative `pages:` API. `Router` on its own is enough.

## Upstream, and the draft

`UPSTREAM.md` — what is already on the tracker. The root cause is known
(flutter/flutter#100946, open since 2022) and a fix is proposed but unmerged
(flutter/flutter#189686, whose description carries these exact numbers). The
trigger found here — `MaterialApp.router` plus a `DropdownMenu`, no gesture,
no screen reader — is not reported anywhere.

`DRAFT-ISSUE.md` — a report written for the tracker. **Nothing has been
posted.** It needs approval of the exact text, and a decision on whether it
goes as a new issue or a comment on the existing PR or issue.
