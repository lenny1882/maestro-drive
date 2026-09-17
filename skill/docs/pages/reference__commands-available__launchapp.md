> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/launchapp.md).

# launchApp

Launches an application on the target device (Android, iOS, or Web). By default, this command stops the running app before launching it again.

### Parameters

The `launchApp` command accepts the following parameters in a map:

| Parameter       | Description                                                                                                                                                                                    |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `appId`         | **Optional.** The package name (Android) or bundle ID (iOS) of the app to launch. If not specified, Maestro launches the app under test using the `appId` defined at the top of the YAML file. |
| `clearState`    | **Optional.** If `true`, clears the app's state before launch.                                                                                                                                 |
| `clearKeychain` | **Optional.** If `true`, clears the entire iOS Keychain.                                                                                                                                       |
| `stopApp`       | **Optional.** If `false`, the command brings a backgrounded app to the foreground without restarting it. Defaults to `true`.                                                                   |
| `permissions`   | **Optional.** A map of permissions to grant, deny, or unset. By default, all permissions are allowed.                                                                                          |
| `arguments`     | **Optional.** A map of key-value pairs to pass as launch arguments to the app. Supports `string`, `boolean`, `double`, and `integer` values.                                                   |

### Usage examples

#### Launch an app

To launch the app under test:

```yaml
- launchApp
```

To launch a different app by its ID:

```yaml
- launchApp: com.example.app
```

When testing web applications, using `launchApp` redirects the test to the website defined at the top of the Flow. In the following example, after navigating through the Maestro documentation, `launchApp` is used to return to the documentation homepage:

```yaml
url: https://docs.maestro.dev/
---
- launchApp
- openLink:
    link: https://maestro.dev/cloud
- tapOn:
    text: Start Your Free Trial
    index: 2
- launchApp
```

#### Launch with a clean state

To clear all app data before launch use `clearState: true`:

```yaml
- launchApp:
    appId: "com.example.app"
    clearState: true
    clearKeychain: true # Optional
```

#### Manage a running app

To bring a backgrounded app to the foreground without restarting it:

```yaml
- launchApp:
    stopApp: false
```

To restart an already running app, run `launchApp` without parameters, as `stopApp` defaults to `true`:

```yaml
- launchApp
```

#### Set permissions on launch

To deny all permissions:

```yaml
- launchApp:
    permissions: 
      all: deny
```

To set specific permissions, add each one independently:

```yaml
- launchApp:
    permissions:
        notifications: unset
        android.permission.ACCESS_FINE_LOCATION: deny
```

#### Pass launch arguments

This example passes arguments of various types to the application on launch.

```yaml
- launchApp:
    appId: "com.example.app"
    arguments: 
       foo: "This is a string"
       isFooEnabled: false
       fooValue: 3.24
       fooInt: 3
```

### Receiving launch arguments

The following examples show how to receive the arguments passed with the `launchApp` command in your application code.

{% tabs %}
{% tab title="Android" %}

```kotlin
intent.extras?.getBoolean("isFooEnabled")?.let {
    // Do something with isFooEnabled
}

intent.extras?.getString("foo")?.let {
    // Do something with foo
}
```

{% endtab %}

{% tab title="iOS" %}

```swift
if ProcessInfo.processInfo.arguments.contains("isFooEnabled") {
    // Do something with isFooEnabled
}

// By default all the values received here would be string
let standardDefaultsDict = UserDefaults.standard.dictionaryRepresentation()
let foo = (standardDefaultsDict["foo"] as? String) ?? "defaultValue"
```

{% endtab %}

{% tab title="React Native" %}

```typescript
import { LaunchArguments } from 'react-native-launch-arguments'

export const isFooEnabled = () => {
  try {
    const foo = LaunchArguments.value().isFooEnabled
    return !!foo
  } catch (e) {
    return false
  }
}
```

{% endtab %}

{% tab title="Flutter" %}

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

### Related content

Learn how to use [permissions](/maestro-flows/flow-control-and-logic/permissions.md) on iOS and Android apps on flows.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/launchapp.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
