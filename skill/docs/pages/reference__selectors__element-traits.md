> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/selectors/element-traits.md).

# Element Traits

Filter elements by traits like square, long-text, and other physical characteristics.

Element traits allow you to identify or filter UI components based on their inherent characteristics, physical properties, or functional roles. These are especially useful when text or IDs are absent, or when you need to target generic elements like icons or containers based on their shape.

### **Overview**

| **Trait**           | **Description**                                                       |
| ------------------- | --------------------------------------------------------------------- |
| `traits: text`      | Selects any element that contains any text or accessibility label.    |
| `traits: long-text` | Selects an element containing at least 200 characters.                |
| `traits: square`    | Selects an element where the width and height differ by less than 3%. |

### `traits: text`

This trait is a broad filter that matches any element that contains some text. You can use it when you want to interact with a container or a button that is guaranteed to have a label, regardless of what that specific label says.

```yaml
# Taps the first element it finds that contains any text
- tapOn:
    traits: text
```

### `traits: long-text`

Maestro specifically identifies blocks of text that are longer than 200 characters. This is useful for identifying article bodies, terms and conditions screens, or long descriptions without needing to match the specific content.

```yaml
# Asserts that a long description block is visible on the page
- assertVisible:
    traits: long-text
```

{% hint style="success" %}

#### Usage tips

Use `traits: long-text` to ensure that dynamic content (like a news feed) has actually loaded and isn't just showing an empty state.
{% endhint %}

#### `traits: square`

This is a physical trait used to identify elements based on their aspect ratio. Icons, profile pictures, and many action buttons are designed as perfect squares. If an element's width and height are within 3% of each other, Maestro identifies it as a square.

```yaml
# Taps a square icon located to the right of the "Home" text
- tapOn:
    traits: square
    rightOf: Home
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/selectors/element-traits.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
