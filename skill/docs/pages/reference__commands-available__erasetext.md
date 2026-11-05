> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/erasetext.md).

# eraseText

Delete text from input fields by character count or clear entirely.

The `eraseText` command deletes characters from the currently focused text field by simulating backspace key presses. By default, it removes up to 50 characters, making it an efficient way to clear input fields.

### Syntax

You can use the command without arguments to perform a standard clear, or specify a precise number of characters to delete (up to a maximum of 100).

```yaml
# Removes up to 50 characters (Default)
- eraseText 

# Removes a specific number of characters (Up to 100)
- eraseText: 10
```

### Clearing large text blocks

While `eraseText` works well for short inputs, clearing long paragraphs or very large fields by hitting backspace 50 times can be slow. To optimize your Flow, especially on iOS, you can use the following sequence to select and delete everything at once:

```yaml
# 1. Select the entire text block
- longPressOn: "<your_input_id>"
- tapOn: "Select All"

# 2. Perform a single backspace to clear the selection
- eraseText: 1
```

{% hint style="success" %}
When text is already selected (e.g., after **Select All**), using `- eraseText: 1` is faster than the default `- eraseText`, as it only needs to trigger a single backspace to delete the entire highlighted selection.
{% endhint %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/erasetext.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
