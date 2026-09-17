> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/android/jetpack.md).

# Jetpack Compose

<figure><img src="/files/w1xWBjwBcDR8HYuyjNWD" alt=""><figcaption></figcaption></figure>

Maestro follows a fundamental principle: **UI-level automation without framework intrusion**. Unlike instrumentation-based tools such as Espresso or Robolectric, which execute inside the app process and depend on framework-specific APIs, Maestro operates externally using Android’s system automation interfaces. This allows Maestro to perform reliable black-box testing regardless of whether your UI is implemented with XML Views, Jetpack Compose, or other UI frameworks.

### Architecture-agnostic testing philosophy

Maestro interacts with your application the same way the Android system and users do, using accessibility metadata and system-level automation. This provides several key advantages:

* **Framework independence:** Maestro does not depend on Compose internals such as composition state, recomposition cycles, or render tree structure. Tests remain valid regardless of UI implementation details.
* **System-level element discovery:** Maestro locates elements using accessibility metadata, visible text, resource identifiers, and other stable attributes exposed by the Android system. This ensures compatibility with Compose, XML Views, and hybrid applications.
* **Stable selector model:** Element identification relies on externally observable properties such as visible text, accessibility labels (`contentDescription`), and resource IDs, rather than internal framework constructs.

### Refactoring resilience

Maestro tests are designed to validate user workflows rather than internal implementation details. This provides strong resilience during UI refactoring, including migration from XML-based layouts to Jetpack Compose.

* **Semantic stability:** As long as visible text, accessibility metadata, or resource identifiers remain consistent, existing Maestro tests typically continue to work without modification.
* **Implementation independence:** Tests verify behavior from the user’s perspective, protecting against failures caused by internal architectural changes that do not affect the user experience.

### Element interaction patterns

Maestro interacts with UI elements using selectors based on system-exposed properties rather than framework-specific APIs.

#### Element selection strategy

Maestro supports multiple stable selector types, including:

* **Visible text**

  ```yaml
  - tapOn: "Login"
  ```

  Matches elements displaying the specified text.
* **Accessibility labels**

  Elements with accessibility metadata such as:

  ```kotlin
  Modifier.semantics {
      contentDescription = "Login Button"
  }
  ```

  can be targeted directly:

  ```yaml
  - tapOn:
      description: "Login Button"
  ```
* **Resource identifiers**

  When available, resource IDs provide highly stable selectors:

  ```yaml
  - tapOn:
      id: "login_button"
  ```

These selector strategies work consistently across Compose and View-based interfaces.

### Compatibility with Jetpack Compose semantics

Jetpack Compose exposes accessibility metadata through its semantics system. Maestro automatically uses this information when available, including:

* Visible text from composables such as `Text` and `Button`
* Accessibility descriptions defined with `contentDescription`
* Resource identifiers when provided

This enables reliable interaction without requiring Compose-specific test APIs or instrumentation.

### Comparative advantages

| Aspect                     | Maestro                             | Instrumentation Tools  |
| -------------------------- | ----------------------------------- | ---------------------- |
| Execution model            | External (black-box)                | In-process (white-box) |
| Framework dependency       | None                                | High                   |
| Compose internals required | No                                  | Yes                    |
| Test infrastructure in app | Not required                        | Required               |
| Refactoring resilience     | High (when semantics remain stable) | Moderate to low        |
| Accessibility usage        | Recommended for reliability         | Optional               |

Maestro eliminates the need for app-side test infrastructure code, lowering barriers for QA practitioners lacking native Android development expertise.

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
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/get-started/supported-platform/android/jetpack.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
