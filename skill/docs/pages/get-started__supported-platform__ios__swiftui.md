> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/ios/swiftui.md).

# SwiftUI

<figure><img src="/files/FqvNwDphuDkPOwMKqP91" alt=""><figcaption></figcaption></figure>

Maestro offers transparent support for SwiftUI applications. Because SwiftUI is declarative and content-centric, Maestro’s architecture-agnostic approach is perfectly suited for it—treating components like `List`, `LazyVStack`, and `Picker` as interactive visual elements rather than complex code objects.

### The SwiftUI workflow

While Maestro can find SwiftUI elements by their displayed text, using identifiers is the most resilient way to build your test suite.

#### **Implementing accessibility identifiers**

For icons, custom controls, or to avoid breaking tests when text is translated, apply the `.accessibilityIdentifier()` modifier in your Swift code. By adding the `.accessibilityIdentifier` modifier, you are explicitly tagging a component in the underlying iOS Accessibility Tree.

```swift
// Step 1: In your SwiftUI View
NavigationLink(value: Panel.donutEditor) {
    Label("Donut Editor", systemImage: "slider.horizontal.3")
}
.accessibilityIdentifier("donut_editor")
```

This ID is invisible to the end-user but is broadcast to any tool interacting with the system's accessibility layer. Thus, Maestro can interact with it using the `id` selector.

```yaml
# Step 2: In your Maestro Flow
- tapOn:
    id: "donut_editor"
```

### Examples

These snippets demonstrate how Maestro handles common SwiftUI patterns and system behaviors.

#### **Native controls (pickers and toggles)**

SwiftUI controls like `Picker` often require specific targeting, especially when multiple options are present.

```yaml
appId: com.swiftui.kit
---
- launchApp:
    clearState: true
- tapOn:
    id: "controls_item"
- tapOn:
    point: "84%,23%" # Precise coordinate tap for complex toggles
- tapOn:
    text: "Chocolate"
    index: 0
- tapOn:
    id: "flavor_picker_segmented_Strawberry" # Target specific segments by ID
```

The examples above use a mix of IDs, Text, and Coordinates to navigate complex SwiftUI layouts. While the `id` selector is the most reliable way to target elements, you can also use `index` to handle duplicate text or `point` for precise taps on small system controls like Toggles.

#### **System navigation and app switching**

Maestro can handle "Inter-App" communication, such as following a link into Safari and using the system breadcrumb to return.

```yaml
appId: com.swiftui.kit
---
- launchApp
- tapOn: "link_item"
# Maestro follows the link into the Browser...
- tapOn:
    id: "breadcrumb" # Returns to your app via the native iOS 'Back' link
```

#### Refactoring resilience

A major advantage of using Maestro with SwiftUI is migration safety. If you rewrite a legacy UIKit screen entirely in SwiftUI, as long as the visual output and accessibility identifiers remain the same, your Maestro tests will require zero changes.

#### Tips and known issues

* **Hierarchy Quirks**: Some specific styles (like `WheelPickerStyle`) may not return a full hierarchy to the accessibility layer, making text-based selection preferred over ID selection in those cases.
* **Merged Elements**: When a `Toggle` is initialized with text, iOS often merges the text and the switch into a single accessibility element.
* **Maestro Studio**: Always use [Maestro Studio](https://docs.maestro.dev/maestro-studio/) to inspect SwiftUI views. It helps you see exactly how the nested view composition is resolved by the accessibility tree before you write your YAML.

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
GET https://docs.maestro.dev/get-started/supported-platform/ios/swiftui.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
