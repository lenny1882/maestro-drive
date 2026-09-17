> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/android/android-native.md).

# Android Native

<figure><img src="/files/y0tgG9VVQjMkqSwcdIhN" alt=""><figcaption></figcaption></figure>

Maestro provides a black-box testing approach for native Android applications. By interacting with the app through the Android Accessibility layer rather than internal code instrumentation, you can test production-ready binaries without modifying your source code.

### Technical advantages

* **Zero Instrumentation**: No custom Gradle configurations, `build.gradle` dependencies, or test-specific APK builds are required. You test the exact binary your users receive.
* **Refactoring Resilience**: Migrating your UI implementation will not break your tests as long as the user-visible text or semantic IDs remain consistent.
* **UI-Layer Interaction**: Maestro interacts with rendered UI elements, ensuring that tests validate the actual user experience rather than internal component states.

### Element interaction strategies

In Android development, Maestro leverages the accessibility layer of the device to identify and interact with elements via primary methods:

* **Text Selection**: Target any view with a `text` property (e.g., `Button`, `TextView`).

  ```yaml
  - tapOn: "Login"
  ```
* **Resource ID**: Access views by their `android:id`. This is ideal for disambiguating identical text elements.

  ```yaml
  - tapOn:
      id: "login_button"
  ```
* **Content Description**: The `android:contentDescription` attribute is surfaced as a text property, making it the "gold standard" for automating icons and image-based buttons.

  ```yaml
  - tapOn: "Settings Icon"
  ```
* **Hints**: For input fields that have not yet been filled, the `android:hint` attribute is also exposed to the text selector.

#### Handling lists and dynamic content

Native Android often uses `RecyclerView` or `LazyColumn` for long lists. Maestro abstracts the complexity of view recycling through intelligent scrolling.

Instead of calculating scroll offsets, use the built-in intelligence of Maestro to find elements that are currently off-screen:

```yaml
- scrollUntilVisible:
    element:
        text: "Item #50"
    direction: DOWN
```

Maestro will automatically swipe down, wait for the next items to load, and stop only when the target element is detected in the view hierarchy.

### Known limitations

While Maestro can detect and tap on views containing Unicode characters, direct inputting (typing) of Unicode text via the `inputText` command is currently not possible.

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
GET https://docs.maestro.dev/get-started/supported-platform/android/android-native.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
