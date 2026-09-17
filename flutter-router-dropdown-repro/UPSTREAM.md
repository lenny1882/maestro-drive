# What is already on the tracker

Searched 12 Aug 2026. The root cause is known upstream and a fix is proposed
but not merged. The trigger found here is not reported anywhere.

## The existing reports

| | what it says |
| --- | --- |
| [flutter/flutter#100946](https://github.com/flutter/flutter/issues/100946) | Open since 29 Mar 2022, P2, `platform-ios` / `accessibility`. Reordering a `ReorderableListView` moves VoiceOver focus to the wrong place on iOS. The same underlying fault, described as a focus problem. |
| [flutter/flutter#189686](https://github.com/flutter/flutter/pull/189686) | Open, **not merged**, by AfzalivE. The fix. When a semantics child is reparented, the old parent unconditionally clears the child's parent pointer, which breaks the ancestor transform chain used to compute global accessibility frames. The guard only clears the relationship when the object still owns it. |
| [mobile-dev-inc/maestro#2984](https://github.com/mobile-dev-inc/maestro/issues/2984) | Open. The same symptom from the tooling side — after a reorder, element bounds come back as `[0,0][134,21]` instead of screen-absolute. Marked as an upstream Flutter problem. |
| [flutter/flutter#189902](https://github.com/flutter/flutter/issues/189902) | Open. `SemanticsNode._replaceChildren` can leave inconsistent parent/child pointers and eventually assert. Framework-side, same family. |

#189686's own description carries the numbers seen here: an expected frame of
`{{0, 286}, {402, 56}}` arriving as `{{0, 0}, {134, 18.67}}` — reduced by the
3x device pixel ratio on a simulator. `134` is exactly the container width
measured on the app under test.

## What is different about this reproduction

Every existing report needs a `ReorderableListView` and a drag gesture. This
one needs only `MaterialApp.router` and a `DropdownMenu` that has been opened
once — no gesture, no screen reader — and it affects the whole accessibility
tree rather than one list. That is a far larger set of affected apps than the
existing reports suggest, which is the argument for raising the priority of a
report that has sat at P2 since 2022.

## Not verified

This case has not been tested against the #189686 patch. "Same root cause" is
inference from matching symptoms and matching numbers, not proof. Nor has it
been tested on Android or on a physical device.

## Nothing has been posted

`DRAFT-ISSUE.md` holds a report written for the tracker. It has not been sent
anywhere and needs explicit approval of the exact text before it is.

## Searches run

`flutter/flutter` for: `DropdownMenu semantics ios`, `accessibilityFrame`,
`semantics bounds wrong ios XCUITest`, `"MaterialApp.router" semantics`,
`semantics "device pixel ratio" ios frame`, `semantics reparent ios frame`,
`OverlayPortal OR MenuAnchor semantics ios frame`. `mobile-dev-inc/maestro`
for `flutter ios coordinates wrong`.
