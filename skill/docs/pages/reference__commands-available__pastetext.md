> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/pastetext.md).

# pasteText

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
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/pastetext.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
