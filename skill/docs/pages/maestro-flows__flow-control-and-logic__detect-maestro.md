> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/detect-maestro.md).

# Detect Maestro

There are times when your application needs to behave differently during a test. Whether you want to bypass a 2FA screen, disable analytics to avoid polluting production data, or point to a mock server, detecting Maestro within your app's code is a common requirement.

### **Why detect Maestro?**

Detecting when your app is under test is a way to handle scenarios that are otherwise difficult to automate:

* **Bypassing 2FA:** Modify authentication flows to use fixed codes, avoiding the need for a physical SIM card or email inbox.
* **Controlling Content Persistence:** Keep short-lived messages (like temporary banners) on the screen longer so Maestro has enough time to detect and interact with them.
* **Environment Switching:** Automatically point your app to a mock server or a staging database to keep production data clean.
* **Disabling Custom Animations:** If your app uses specialized animations that aren't caught by the [`waitForAnimationToEnd`](/reference/commands-available/waitforanimationtoend.md), you can turn them off manually to prevent "ghost taps."

### Mobile (iOS and Android)

The gold standard for detecting Maestro on mobile is using [`launchApp arguments`](/reference/commands-available/launchapp.md#pass-launch-arguments). This approach is reliable, explicit, and works seamlessly in both local environments and [Maestro Cloud](https://docs.maestro.dev/cloud/run-maestro-tests-in-the-cloud).

{% stepper %}
{% step %}

#### **Pass the argument in your Flow**

In your Maestro Flow, use the `arguments` parameter within the `launchApp` command to send a custom flag.

```yaml
- launchApp:
    appId: "com.example.app"
    arguments:
      isMaestro: "true"
```

{% endstep %}

{% step %}

#### **Detect the argument in your code**

Your application can then check for this flag during its initialization phase.

{% tabs %}
{% tab title="Android (Kotlin/Java)" %}

```kotlin
val isMaestro = intent.getStringExtra("isMaestro") == "true"
if (isMaestro) {
    // Disable analytics or use mock data
}
```

{% endtab %}

{% tab title="iOS (Swift)" %}

```swift
if ProcessInfo.processInfo.arguments.contains("isMaestro") {
    // Apply test-only configurations
}
```

{% endtab %}

{% tab title="React Native" %}
For React Native, you can use a library like `react-native-launch-arguments` to retrieve the parameters passed during startup.

```javascript
import { LaunchArguments } from 'react-native-launch-arguments';

if (LaunchArguments.value().isMaestro === "true") {
    // Apply test-only configurations
}
```

{% endtab %}

{% tab title="Flutter" %}
For Flutter, the most straightforward approach is to use a package like `flutter_launch_arguments` to retrieve the parameters passed from Maestro without having to manually set up platform channels:

```dart
import 'package:flutter_launch_arguments/flutter_launch_arguments.dart';

Future<void> getArguments() async {
  final fla = FlutterLaunchArguments();

  final foo = await fla.getString('foo');
  final isFooEnabled = await fla.getBool('isFooEnabled');
  final fooValue = await fla.getDouble('fooValue');
  final fooInt = await fla.getInt('fooInt');
}
```

{% endtab %}
{% endtabs %}

{% hint style="danger" %}

#### Checking for open ports (Deprecated)

In the past, developers checked if ports `7001` (Android) or `22087` (iOS) were open. These were Maestro-specific ports that were used to detect Maestro.

**This method is now deprecated**. It is unsupported in Maestro Cloud and may be removed in future updates. Maestro strongly recommends using the [`launchApp arguments`](/reference/commands-available/launchapp.md#pass-launch-arguments) approach.
{% endhint %}
{% endstep %}
{% endstepper %}

### Web

For Web apps, Maestro simplifies detection by injecting a property directly into the global execution context.

Maestro automatically defines `window.maestro` while a test is running. You can check for this property anywhere in your frontend code using `window.maestro`:&#x20;

```javascript
if (window.maestro) {
  console.log("Maestro test is running!");
}
```

#### Related content

* [`launchApp`](/reference/commands-available/launchapp.md): Full technical reference for passing launch arguments.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/detect-maestro.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
