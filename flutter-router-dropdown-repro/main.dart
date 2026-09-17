// Minimal reproduction: on iOS, an app built with MaterialApp.router reports
// its whole accessibility tree at 1/devicePixelRatio once a DropdownMenu has
// been opened and closed. The same app built with MaterialApp(home:) does not.
//
// Flutter 3.41.9 stable, iPhone 16 Pro simulator, iOS 18.6, dpr 3.
//
// Read the accessibility frames before and after opening and closing the menu
// (Xcode's Accessibility Inspector, or any XCUITest hierarchy dump). The
// caption starts at (68, 307) 265x20 and ends at (22, 102) 88x6 — exactly a
// third — while nothing on screen has moved.
//
// Set kUseRouter = false and the frames stay correct all the way through.

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
