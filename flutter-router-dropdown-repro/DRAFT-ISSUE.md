# DRAFT — not posted, not approved

Written 12 Aug 2026 for the flutter/flutter tracker. Nothing has been sent.
Posting it needs explicit approval of the exact text, and a decision on where
it goes — a new issue, a comment on PR #189686, or a comment on issue #100946.
See `UPSTREAM.md` for what is already there.

The caption and the dropdown labels below are carried over from the app this
was found in. They are harmless but not generic; swap them if that matters.

---

**Title:** `[iOS] MaterialApp.router + DropdownMenu reports the whole accessibility tree at 1/devicePixelRatio`

On iOS, an app built with `MaterialApp.router` reports its entire accessibility
tree at 1/devicePixelRatio once a `DropdownMenu` has been opened and closed.
The same app built with `MaterialApp(home:)` is correct throughout. Nothing on
screen moves — only the frames handed to the accessibility layer change.

This looks like the same fault as #100946, and #189686 describes the mechanism
and the identical numbers. What is different here is the trigger: no
`ReorderableListView`, no drag, no screen reader, and it affects the whole tree
rather than one list. Any Router-based app with a dropdown appears to be
affected, which is a much wider set of apps than the existing reports suggest.

## Reproduction

Stock `flutter create` project, no third-party packages. Full file:

```dart
import 'package:flutter/material.dart';

const bool kUseRouter = true;

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => kUseRouter
      ? MaterialApp.router(routerDelegate: _Delegate())
      : const MaterialApp(home: Screen());
}

class _Delegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const Screen()),
      );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

class Screen extends StatelessWidget {
  const Screen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please choose the store and enter PIN.'),
              const SizedBox(height: 22),
              DropdownMenu<String>(
                hintText: 'Select Store',
                width: 306,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: '1901', label: '1901 - First Store'),
                  DropdownMenuEntry(value: '1902', label: '1902 - Second Store'),
                ],
              ),
            ],
          ),
        ),
      );
}
```

1. Run on an iOS simulator with a device pixel ratio of 3.
2. Read the accessibility frames — Accessibility Inspector, or any XCUITest
   hierarchy dump.
3. Open the dropdown and select an item.
4. Read the frames again.

**Expected:** the frames are unchanged, since nothing on screen has moved.

**Actual:** every frame is divided by the device pixel ratio. Measured on the
caption text:

| | `kUseRouter = true` | `kUseRouter = false` |
| --- | --- | --- |
| on launch | `68,388 265x20` | `68,388 265x20` |
| menu open | `68,388 265x20` | `68,388 265x20` |
| menu closed | **`22,129 88x6`** | `68,388 265x20` |

`22,129 88x6` is `68,388 265x20` divided by 3.

## What is and isn't needed

Each row is a separate cold launch. Hot restart carries the state over and
gives misleading results.

| app shape | reproduces? |
| --- | --- |
| `MaterialApp(home:)` | no |
| `MaterialApp.router` + auto_route, screen as the initial route | yes, when the menu closes |
| `MaterialApp.router` + auto_route, screen pushed as a `CustomRoute` | yes, when the menu opens |
| `MaterialApp.router` + hand-written delegate, `Navigator(pages:)` | yes, when the menu closes |
| `MaterialApp.router` + hand-written delegate, `Navigator(onGenerateRoute:)` | yes, when the menu closes |

So it needs no third-party packages, and not the declarative `pages:` API
either. `Router` alone is enough.

## Impact

Any tool that drives the app through the accessibility tree — XCUITest,
Appium, Maestro — reads those frames and taps the wrong place. It fails
silently: the tap lands near the top-left and does nothing. Tracked from the
tooling side as mobile-dev-inc/maestro#2984.

## Version

```
Flutter 3.41.9 • channel stable
Framework • revision 00b0c91f06 • 2026-04-29
Engine • hash 9161402dc0e134b3fb5adee5046b6e84b1a5e1c1 (revision 42d3d75a56)
Tools • Dart 3.11.5 • DevTools 2.54.2
Xcode 26.6, iPhone 16 Pro simulator, iOS 18.6
```

Not tested on Android or on a physical device.
