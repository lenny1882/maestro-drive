> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/flutter.md).

# Flutter

<figure><img src="/files/NJlBxI0H5eATCEB2nHrb" alt=""><figcaption></figcaption></figure>

Maestro treats Flutter as a first-class citizen, supporting both pure and hybrid ([add-to-app](https://docs.flutter.dev/add-to-app)) mobile applications. Unlike internal tools that inject Dart code, Maestro interacts with the device elements that Flutter exposes through its Semantics Tree, ensuring your tests reflect the actual experience of an end-user.

### Black-box approach

Maestro operates externally, orchestrating input events and validating outcomes based on the actual pixels and accessibility labels rendered on the device.

* **Zero Framework Dependencies**: No `pubspec.yaml` integration is required. Maestro tests the compiled APK or IPA directly.
* **Stability Across Upgrades**: Your tests remain stable across Flutter version updates because Maestro does not depend on the internal widget tree.
* **System-Level Automation**: Since Maestro lives at the OS level, it can handle system-level flows, like push notifications or permission dialogs, that in-app Dart frameworks cannot reach.

### Element interaction strategies

To interact with a widget, Maestro needs it to have semantic information. By default, widgets that display text (like `Text` or `TextField`) provide this implicitly.

#### **Interacting by semantics label (text)**

Maestro can target any widget that displays text content. For widgets without implicit text, such as an `Icon`, you can manually provide a `semanticLabel`.

To target Icon, for example, in this Dart code, you need to add a label to an Icon so Maestro can "see" it. For more details, see the official [Flutter Icon documentation](https://api.flutter.dev/flutter/widgets/Icon-class.html). In the following example, `semanticLabel` is being used to add a label.

```dart
FloatingActionButton(
  onPressed: _incrementCounter,
  child: Icon(Icons.add, semanticLabel: 'fabAddIcon'),
)
```

This way, you can easily identify the element when creating a flow:

```yaml
- tapOn: "fabAddIcon"
```

#### **The semantics widget**

You can wrap any layout component, such as a `Container` or `SizedBox`, with a [Semantics widget](https://api.flutter.dev/flutter/widgets/Semantics-class.html) to make it inspectable by Maestro.

When you add semantics to a layout, it allows you to perform actions such as tapping on a visual area that does not inherently contain text. The following example adds a label using semantics, allowing Maestro to target the element during testing.

```dart
Semantics(
  label: 'yellow_box',
  child: Container(color: Colors.yellow, width: 100, height: 100),
)
```

This way, you can easily interact with the element by referring to the label:

```
- tapOn: "yellow_box"
```

### Semantics identifiers

As your app adds multi-language support or A/B tests, text-based labels can become brittle. The best practice is to use Semantic Identifiers.

{% hint style="info" %}
This feature was [contributed by the Maestro team to Flutter](https://github.com/flutter/engine/pull/47961) and is available in Flutter 3.19+.
{% endhint %}

This pattern creates a permanent link between your Dart code and your YAML [Flow ](https://docs.maestro.dev/maestro-flows/)that never changes, even if you translate your app into 20 languages.

To use the pattern, the developer needs to assign a unique `identifier` that is invisible to the user but exposed to Maestro.

```dart
Semantics(
  identifier: 'login_button',
  child: ElevatedButton(onPressed: _login, child: Text('Sign In')),
)
```

This way, the test can target that identifier using the `id` [selector](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md).

```yaml
- tapOn:
    id: "login_button"
```

### Why not use Flutter Keys?

Flutter [Keys](https://api.flutter.dev/flutter/foundation/Key-class.html) are designed for the Flutter engine to manage widget identity during state changes (like reordering a list). They are not exposed to the system's accessibility layer. Because Maestro lives outside the Flutter runtime, it cannot "see" Keys. Always use Semantics for automation.

### Known limitations

* **Flutter Desktop**: Maestro does not yet support Flutter for Desktop.
* **Flutter Web**: It is fully supported by Maestro. It works identically to standard [Web Testing](/get-started/supported-platform/web-browser.md). However, Flutter web renders to `<canvas>` and does **not** enable the DOM accessibility/semantics overlay by default. Maestro relies on this overlay to find elements, so you must explicitly enable it in your app's `main()`:

```dart
import 'package:flutter/rendering.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics(); // required for Maestro on web
  runApp(const MyApp());
}
```

Without this call, Maestro cannot find any elements — `assertVisible` and `tapOn` will fail silently even though the app renders correctly. Once semantics are enabled, use Semantics widgets to make your web elements addressable.

### Next steps

If you don't know how to create tests with Maestro, access the [Quickstart](/get-started/quickstart.md) guide to get up and running in minutes.

To learn how to create tests, refer to the [Flows](https://docs.maestro.dev/maestro-flows/) documentation. If you want to explore Maestro solutions, consult the appropriate documentation:

* [Maestro Studio](https://docs.maestro.dev/maestro-studio/)
* [Maestro CLI](https://docs.maestro.dev/maestro-cli/)
* [Maestro Cloud](/maestro-cloud/readme.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/get-started/supported-platform/flutter.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
