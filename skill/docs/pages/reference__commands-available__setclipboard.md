> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/setclipboard.md).

# setClipboard

Set the device clipboard content to a specified text value.

The `setClipboard` command sets a specified text string to Maestro's in-memory clipboard. It allows you to define the clipboard content directly, unlike `copyTextFrom` which copies text from a UI element.

### Syntax

The `setClipboard` command accepts a string or a JavaScript expression:

```yaml
- setClipboard: "custom@example.com"  # string
- setClipboard: "${'user' + Math.floor(Math.random() * 1000) + '@example.com'}" # JavaScript expression
```

### Usage examples

#### Set a static value

This example sets a static email address to the clipboard and then pastes it into a text field instead of typing. Using [`pasteText`](/reference/commands-available/pastetext.md) can help avoid flakiness when entering text.

```yaml
appId: com.example.app
---
- launchApp
- tapOn:
    id: "emailField"
- setClipboard: "custom@example.com"
- pasteText
```

#### Set a dynamic value

You can use a JavaScript expression to generate dynamic content for the clipboard.

```yaml
appId: com.example.app
---
- launchApp
- setClipboard: ${'user' + Math.floor(Math.random() * 1000) + '@example.com'}
- tapOn:
    id: "emailField"
- pasteText
```

#### Access clipboard contents

You can access the clipboard's contents in subsequent steps using the `maestro.copiedText` property.

```yaml
appId: com.example.app
---
- setClipboard: "test@example.com"
- inputText: ${'Email: ' + maestro.copiedText}
```

### Related commands

* [pasteText](/reference/commands-available/pastetext.md)
* [copyTextFrom](/reference/commands-available/copytextfrom.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/setclipboard.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
