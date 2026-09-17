> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/how-to-use-selectors.md).

# How to use Selectors

Selectors are the foundational logic Maestro uses to identify UI elements. By default, Maestro interacts with the Accessibility Tree, meaning it sees the application much like an end-user or an assistive device would.&#x20;

### Interaction guide

Most Maestro commands, such as `tapOn`, `assertVisible`, `copyTextFrom`, and `scrollUntilVisible`, require a selector to know which part of the screen to act upon. You can define these selectors using two distinct formats.

When you only need to match an element by its visible text, you can use a simple string. This is the fastest way to write readable tests for static content.

```yaml
- tapOn: Login # Maestro automatically interprets this as { text: "Login" }
```

For higher precision, you can combine multiple attributes into a single Selector block. Maestro will only match an element that satisfies all the provided conditions (an **AND** logic). This is essential when dealing with dynamic UIs, multiple similar buttons, or elements that change state.

```yaml
- tapOn:
    id: submit_button     # Technical ID
    enabled: true         # Only if it's clickable
    below: Password       # Located in a specific area
```

### Best practices

To ensure your test suite remains maintainable and flake-free as your app evolves, follow these strategic principles:

* **Prioritize User-Visible Text**: Whenever possible, use `text` selectors. This ensures your tests validate what the user actually sees and improves test readability by making selectors self-documenting. If the text changes and breaks the test, it usually means the user experience has changed as well.
* **Use IDs for Stability**: For icons, images, or apps supporting multiple languages (localization), use `id` (Accessibility Identifiers). These are hidden from the user but remain constant across different languages.
* **Anchor with Relational Logic**: If an element is dynamic or lacks a unique ID, find a stable "anchor" (like a section header) and use relational selectors (e.g., `below: "Personal Information"`) to pinpoint the target.
* **Handle Dynamic Values with Regex**: Since `text` and `id` are regex-based by default, use patterns like `.*` to handle strings that varies.
* **Verify State Before Action**: When tapping a button that depends on an API call or form validation, include `enabled: true` in your selector. Maestro will automatically wait for the button to become interactive before attempting the tap.

### Selector reference

Explore these specialized reference pages to find the right tool for every UI scenario:

| Category                                                             | Best for                                                                               |
| -------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| [Core Selectors](/reference/selectors/core-selectors.md)             | The essentials: `text`, `id`, `index`, `point`, and `css` (web).                       |
| [Relational Selectors](/reference/selectors/relational-selectors.md) | Finding elements based on visual position (`above`, `below`) or structure (`childOf`). |
| [Element Traits](/reference/selectors/element-traits.md)             | Filtering by physical characteristics like `square` or `long-text`.                    |
| [State Selectors](/reference/selectors/state-selectors.md)           | Verifying functional status (`enabled`, `checked`, `focused`, or `selected`).          |
| [Dimension Matchers](/reference/selectors/dimension-matchers.md)     | Targeting by physical size (`width`, `height`) with `tolerance`.                       |


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/how-to-use-selectors.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
