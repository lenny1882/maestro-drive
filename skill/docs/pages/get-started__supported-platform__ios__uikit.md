> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/ios/uikit.md).

# UIKit

Black-box testing for UIKit via the accessibility layer. Use accessibilityLabel for text and accessibilityIdentifier (gold standard) for id selectors.

<figure><img src="https://1411608689-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FCbCMt5C3rawmE9oIus7f%2Fuploads%2FfrvcCyZXHQyzN8OmcVkc%2Fimage.png?alt=media&amp;token=5371c7d1-fcfd-4367-9e2b-0ccbc823b228" alt=""><figcaption></figcaption></figure>

Maestro provides native, transparent support for iOS applications built with UIKit. Operating at the visual interaction layer rather than the implementation layer, Maestro interacts with rendered UI components regardless of underlying class hierarchies such as `UIButton`, `UITableView`, and `UILabel`.

### Technical advantages

* **Zero Instrumentation**: Maestro does not require test libraries, delegates, or ViewController exposure. You test the built `.app` binary, nothing else.
* **Implementation Agnostic**: Because Maestro validates user-facing features rather than internal code, you can refactor UIKit components to SwiftUI without breaking your tests, provided the visual output remains consistent.
* **Black-Box Model**: Maestro adopts an [arm's length](/get-started/how-maestro-works.md) approach, simulating authentic user interactions with the rendered UI without needing access to internal source code.

### Element interaction strategies

Maestro interacts with UIKit components by simulating authentic user interactions through the accessibility layer.

#### **Interacting with views by text**

Primary interaction in UIKit is often done via visible UI text. Any view with text content (like a `UIButton` title) can be targeted directly.

```swift
// In your UIKit Swift code
let button = UIButton()
button.setTitle("Submit Order", for: .normal)
```

You can tap this button in your Flow using the visible text:

```yml
- tapOn: "Submit Order"
```

#### **Using accessibility labels and IDs**

For non-textual elements like icons, or for disambiguating duplicate elements, leverage iOS accessibility metadata. Maestro translates these properties into specific selectors:

* `accessibilityLabel`: Maestro translates this to the `text` selector.
* `accessibilityIdentifier`: Maestro translates this to the `id` selector. This is the gold standard for reliable tests.

```swift
// In your UIKit Swift code
let button = UIButton()
button.accessibilityIdentifier = "login_button_id"
```

The corresponding tap command in your Flow would use the `id`:

```yaml
- tapOn:
    id: "login_button_id"
```

### Handling lists and complex components

Maestro abstracts away the complexity of coordinate calculations and cell enumeration in `UITableView` and `UICollectionView`.

#### **Intelligent scrolling**

Instead of manual index or offset calculations, use `scrollUntilVisible`. Maestro combines visibility detection with continuous swiping to find elements that are currently off-screen.

```yaml
- scrollUntilVisible:
    element:
        text: "List Item 50"
    direction: DOWN
```

### Known limitations

* **Simulators**: Full support for local execution on iOS Simulators.
* **Physical Devices**: Executing tests on physical iOS devices is not supported yet.

### Next steps

If you don't know how to create tests with Maestro, access the [QuickStart](/get-started/quickstart.md) guide to get up and running in minutes.

To learn how to create tests, refer to the [Flows](https://docs.maestro.dev/maestro-flows/) documentation. If you want to explore Maestro solutions, consult the appropriate documentation:

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
GET https://docs.maestro.dev/get-started/supported-platform/ios/uikit.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
