> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/pastetext.md).

# pasteText

Paste text from clipboard into the currently focused input field.

The `pasteText` command pastes text from the clipboard into the currently focused UI element.

This command requires that a text field is in focus before execution. Text must first be copied to the clipboard using the [`copyTextFrom` ](/reference/commands-available/copytextfrom.md)command.

{% hint style="info" %}

#### System vs. internal clipboard

Maestro distinguishes between two types of clipboards:

* **Internal clipboard**: Stores text captured by Maestro commands, such as `copyTextFrom`, or values manually assigned to `maestro.copiedText`.
* **System clipboard**: The native operating system clipboard used when interacting with in-app actions like a **Copy to Clipboard** button.

The `pasteText` command interacts **exclusively** with Maestro’s internal clipboard. It does not read from or write to the system clipboard.

As a result, if you tap a button in your app that copies content to the system clipboard, `pasteText` will not paste that content. It will only paste text that was previously captured using `copyTextFrom` or explicitly assigned to `maestro.copiedText`.
{% endhint %}

### Syntax

This command takes no arguments.

```yaml
- pasteText
```

### Usage examples

The following example copies text from an element with the ID `someId`, taps a search field to give it focus, and then pastes the copied text into it.

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

### Related commands

* [copyTextFrom](/reference/commands-available/copytextfrom.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/pastetext.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
