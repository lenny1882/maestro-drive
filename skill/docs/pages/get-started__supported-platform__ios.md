> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/ios.md).

# iOS

Black-box iOS testing via the Accessibility layer. Run on Xcode Simulators, handle permissions, test multi-app journeys, and parallelize with Cloud.

<figure><img src="https://1411608689-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FCbCMt5C3rawmE9oIus7f%2Fuploads%2FfrvcCyZXHQyzN8OmcVkc%2Fimage.png?alt=media&amp;token=5371c7d1-fcfd-4367-9e2b-0ccbc823b228" alt=""><figcaption></figcaption></figure>

Maestro provides a high-level abstraction for iOS testing by simulating end-user interactions at the presentation layer. Unlike traditional testing tools that require deep instrumentation, Maestro interacts with the iOS Accessibility layer, allowing you to test your app exactly as a user would.

### Black-box approach

Maestro analyzes the rendered frames of the iOS device, ensuring your tests are framework-agnostic. Whether your app is built with Swift, Objective-C, Flutter, React Native, or SwiftUI, Maestro interacts only with the visual output.

* **Physical Input Simulation**: Declarative commands are translated into native touch events. When you use `tapOn`, Maestro triggers the same iOS input pipeline that a physical touch would.
* [**Arm's Length**](/get-started/how-maestro-works.md): Maestro doesn't require access to your source code or bytecode. You test the same `.app` bundle (the Simulator version) that runs on your virtual testing environment.

### System-level control

Maestro’s architecture allows it to pilot the entire device, not just your application process. This enables testing for complex real-world scenarios.

iOS is known for its strict permission dialogs (Location, Camera). However, Maestro can interact with these system prompts directly:

```yaml
- launchApp:
    appId: "com.example.app"
    permissions:
      location: allow
      notifications: allow
```

Maestro also allows you to create multi-app journeys. You can test flows that leave your app, such as opening a link in Safari or checking an email, and then return to your application:

```yaml
- tapOn: "Open Website"
# Maestro follows the link into Safari
- assertVisible: "Welcome to our site"
- tapOn:
    id: "breadcrumb" # Native iOS 'Back' button to return to your app
```

### Execution and environment setup

Maestro connects to your target via native Apple development tools.

* **Simulators**: Run tests on any iOS Simulator managed by Xcode. Ensure you have the Xcode Command Line Tools installed (`xcode-select --install`).
* **App Identification**: iOS apps are targeted using the Bundle ID (e.g., `com.example.app`).

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
maestro test -e APP_ID=com.example.app.ios flow.yaml
## or
maestro test --env APP_ID=com.example.app.ios flow.yaml
```

### Parallelization for iOS

Scaling iOS tests locally can be difficult due to macOS hardware requirements. [Maestro Cloud](/maestro-cloud/readme.md) provides instant access to a fleet of iOS Simulators, allowing you to run your entire suite in parallel.

* **Speed**: Reduce test time drastically.
* **Reliability**: Eliminate "flaky" results caused by local machine resource contention.
* **CI/CD Integration**: Automatically trigger parallel iOS runs on every Pull Request.

### Next steps

Explore the dedicated [UIKit](/get-started/supported-platform/ios/uikit.md) or [SwiftUI](/get-started/supported-platform/ios/swiftui.md) documentation, or access the [QuickStart](/get-started/quickstart.md) guide to get up and running in minutes if you do not know how to create tests with Maestro.

If you already know which Maestro solution you are going to use, access the relevant documentation:

* [Maestro Studio](https://docs.maestro.dev/maestro-studio/)
* [Maestro CLI](https://docs.maestro.dev/maestro-cli/)
* [Maestro Cloud](/maestro-cloud/readme.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/get-started/supported-platform/ios.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
