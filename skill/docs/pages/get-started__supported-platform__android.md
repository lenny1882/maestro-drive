> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/android.md).

# Android

<figure><img src="/files/ZkvJm2hjaXNVC5CuzPC7" alt=""><figcaption></figcaption></figure>

Maestro provides a high-level abstraction for Android testing by simulating end-user interactions at the presentation layer. Unlike other frameworks, Maestro doesn't live inside your app, it pilots the device from the outside.

### A UI-centric approach

Maestro operates through the Android display stack, ensuring your tests are framework-agnostic. Whether you use Kotlin, Java, Flutter, React Native, or Compose, Maestro interacts only with the rendered UI.

* **Human-Like Simulation**: Maestro translates declarative commands into system-level inputs, mimicking genuine user behavior on the Android input pipeline.
* **Zero Instrumentation**: You don't need to add test dependencies to your `build.gradle` or compile a special "test APK."

### System-level control

Maestro drives the entire device, not just your app. If you need to change WIFI settings, read a notification, create contacts, or manage anything else that depends on device state or data, you can do so in exactly the same way a real user would, using "real human thumbs."

To manage system settings mid-test, you can interact with the OS directly or use built-in commands:

```yaml
- toggleAirplaneMode
- tapOn: "Airplane mode"
- runFlow: toggle_wifi.yaml # Use a subflow for complex system interactions
```

Android apps often cache data that can lead to flaky tests. The `clearState` command ensures a reproducible environment by clearing app data (the equivalent of`adb shell pm clear <package-name>`) before the app launches, giving the app a "just installed" state.

```yaml
- launchApp:
    appId: "com.example.app"
    clearState: true  # Resets app data for a clean launch
```

### Execution and environment setup

Maestro connects to your target via ADB (Android Debug Bridge).

* **Emulators & Physical Devices**: Maestro automatically detects and connects to running emulators or physical devices. For physical hardware, ensure "USB Debugging" is enabled in Developer Options.
* **App Identification**: Maestro targets your application using the **Package** found in your `AndroidManifest.xml` (the `appId`).
* **Installation**: Maestro assumes the application is already installed on the target device/emulator before the test begins.

### Cross-platform configuration

If your Android and iOS applications use different identifiers, we recommend using [environment variables](/maestro-flows/flow-control-and-logic/parameters-and-constants.md) to keep your [Flows](https://docs.maestro.dev/maestro-flows/) cross-platform.

You can manage these variables in three primary ways:

1. **Maestro Studio**: Configured via the [Environment Manager](/maestro-studio/environments-and-variables.md).
2. [**Maestro CLI**](/maestro-flows/flow-control-and-logic/parameters-and-constants.md#passing-parameters-via-cli): Passed as arguments during execution.
3. **Flow Configuration**: Defined directly in the [config matter](/maestro-flows/flow-control-and-logic/parameters-and-constants.md#constants) at the top of an individual Flow file.

To run a single test suite against different platforms where the App ID varies, structure your Flow to use a variable:

```yaml
# In your Flow
appId: ${APP_ID}
---
- launchApp
```

When executing locally with the [Maestro CLI](https://docs.maestro.dev/maestro-cli/), use the `-e` or `--env` flag to inject the correct identifier for that specific run:

```bash
maestro test -e APP_ID=com.example.android flow.yaml
## or
maestro test --env APP_ID=com.example.android flow.yaml
```

### Maestro Cloud

When your suite grows, local sequential execution becomes a bottleneck. [Maestro Cloud](/maestro-cloud/readme.md) spins up multiple virtual Android devices to run your tests in parallel.

| **Feature**         | **Local Android**  | **Maestro Cloud**                  |
| ------------------- | ------------------ | ---------------------------------- |
| **Parallelization** | 1 device at a time | Scale to as many devices as needed |
| **Speed**           | Slow (Sequential)  | Blazingly Fast (Parallel)          |
| **Cleanup**         | Manual             | Automatic Infrastructure Teardown  |

### Next steps

Explore the dedicated [Android Native](/get-started/supported-platform/android/android-native.md) and [Jetpack Compose](/get-started/supported-platform/android/jetpack.md) documentation for platform-specific patterns.

If you already know the Maestro solution you are going to use, access the desired documentation:

* [Maestro Studio](https://docs.maestro.dev/maestro-studio/)
* [Maestro CLI](https://docs.maestro.dev/maestro-cli/)
* [Maestro Cloud](/maestro-cloud/readme.md)

If you are new to the platform, follow the [QuickStart](/get-started/quickstart.md) guide to get up and running in minutes.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/get-started/supported-platform/android.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
