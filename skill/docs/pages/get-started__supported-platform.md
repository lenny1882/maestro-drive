> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform.md).

# Supported platforms

<figure><img src="/files/C8efUjjvaaggaZ4WsEc1" alt=""><figcaption></figcaption></figure>

Maestro operates on the principle of UI-layer automation rather than code instrumentation. Like a test driver interacting with any vehicle through its controls (steering wheel, pedals), Maestro interfaces with applications through their visual and accessibility layers, regardless of the underlying technology stack.

### Mobile operating systems (core)

Maestro provides comprehensive automation support for major mobile platforms:

* **Android:** Full support for emulators and physical devices
* **iOS:** Full support for simulators

Both platforms pass validation at scale by enterprise teams at Microsoft, DoorDash, and others for complex automation scenarios.

### Framework agnosticism

Maestro decouples test automation from framework implementation by interacting directly at the UI layer. This removes the need for framework-specific instrumentation, which is a departure from tools like Detox or Appium, which depend on complex native drivers and in-app code injection.

Supported technology stacks include:

* **Native:** Swift, Kotlin, Java, Objective-C.
* **Cross-platform:** React Native, Flutter.
* **Other hybrid frameworks.**

### Web automation

* **Status:** Functional with ongoing development.
* **Approach:** Maestro extends support to web applications, enabling cross-platform test consolidation using consistent automation syntax.
* **Use Case:** Unified testing strategy across mobile and web surfaces.

### System-level interaction

Maestro supports device-level automation beyond app boundaries:

* **System Interaction:** Navigate to Settings, modify permissions, toggle Wi-Fi, and monitor app behavior in response to system state changes.
* **Real-world Scenarios:** Automated testing of notification handling, permission flows, and inter-app interactions.

### Next steps

Explore the details on how to use Maestro in each one of the supported operating systems and frameworks:

* [Android](/get-started/supported-platform/android.md)
* [Android Native](/get-started/supported-platform/android/android-native.md)
* [Jetpack Compose](/get-started/supported-platform/android/jetpack.md)
* [iOS](/get-started/supported-platform/ios.md)
* [SwiftUI](/get-started/supported-platform/ios/swiftui.md)
* [UIKit](/get-started/supported-platform/ios/uikit.md)
* [React Native](/get-started/supported-platform/react-native.md)
* [Flutter](/get-started/supported-platform/flutter.md)
* [Web Browsers](/get-started/supported-platform/web-browser.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/get-started/supported-platform.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
