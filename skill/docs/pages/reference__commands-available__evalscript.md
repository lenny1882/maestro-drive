> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/evalscript.md).

# evalScript

The `evalScript` command executes a single line of JavaScript directly within a Maestro flow. This is useful for performing simple computations or data manipulations without creating a separate JavaScript file.

The command accepts a single string argument representing the JavaScript expression to evaluate.

### Syntax&#x20;

To use the `evalScript` command, you need to provide the single-line JavaScript expression to evaluate. The result can be assigned to the `output` scope for use in subsequent steps:

```yaml
- evalScript: ${output.myVar = myExpression}
```

### Usage examples

The following example uses `evalScript` to convert an environment variable to uppercase and stores the result in `output.uppercaseName`.

```yaml
appId: com.example
env:
    MY_NAME: John
---
- launchApp
- evalScript: ${output.uppercaseName = MY_NAME.toUpperCase()}
- inputText: ${output.uppercaseName}
```

### Related content

Access the [JavaScript guides](/maestro-flows/javascript/javascript-overview.md) to learn how to use JavaScript when creating Flows.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/evalscript.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
