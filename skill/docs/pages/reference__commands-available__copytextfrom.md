> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/copytextfrom.md).

# copyTextFrom

The `copyTextFrom` command copies text from a UI element and stores it in memory. This command requires a [Selector](/reference/selectors.md) to identify the target element.

### Accessing the copied text

When you copy content using the `copyTextFrom` command, you have two ways to use the text after it has been copied:

1. Use the [`pasteText`](/reference/commands-available/pastetext.md) command to immediately insert the content into a focused field.
2. To run an equality check, perform complex logic, or store the text for later use in your flow, use the `maestro.copiedText` variable.

### Usage examples

The following examples demonstrate how to use the copied text.

#### Paste with the `pasteText`  command

This example copies text from an element with the ID `someId` and pastes it into a search field.

```yaml
appId: com.example.app
---
- launchApp
- copyTextFrom:
    id: "someId"
- tapOn:
    id: "searchFieldId"
- pasteText
```

#### Access with JavaScript

The copied text is available in JavaScript through the `maestro.copiedText` property. This example copies the text from `someId` and uses the [`inputText`](/reference/commands-available/inputtext.md) command to add the content into the search field.

```yaml
appId: com.example.app
---
- launchApp
- copyTextFrom:
    id: "someId"
- tapOn:
    id: "searchFieldId"
- inputText: ${'Pasted using JavaScript: ' + maestro.copiedText}
```

#### **Store and validate**

You can assign the copied value to a custom variable to perform assertions or use it later in a Flow after other commands have overwritten the clipboard.&#x20;

This example demonstrates how to copy text from a UI element, store the copied value in a variable using `maestro.copiedText`, and then validate that the captured text matches the expected value.

```yaml
# Copy text from an element
- copyTextFrom:
    id: "my_element"

# Store the value for later use
- evalScript: ${output.myElementText = maestro.copiedText}

# Check that the element had the correct value
- assertTrue: ${output.myElementText == "Correct Text"}
```

### Related content

Explore how the [`pasteText`](/reference/commands-available/pastetext.md) command works, or learn how to use the available [Selectors](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md) to define the desired element when copying content.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/copytextfrom.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
