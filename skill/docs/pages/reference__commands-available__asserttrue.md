> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/asserttrue.md).

# assertTrue

Asserts that a given expression evaluates to a truthy value. A value is [truthy](https://developer.mozilla.org/en-US/docs/Glossary/Truthy) (in JavaScript terms) if it is not `false`, `0`, an empty string (`""`), `null`, `undefined`, or `NaN`.

### Syntax

You can use the shorthand approach, providing only the expression, or you can use the `condition` and `label`.

```yaml
- assertTrue: ${value}
# or
- assertTrue:
    condition: ${value}
    label: Variable 'value' is set
```

### Parameters

You can provide the expression directly or use the `condition` and `label` parameters for more complex assertions.

| Parameter   | Type       | Description                                                              |
| ----------- | ---------- | ------------------------------------------------------------------------ |
| `condition` | Expression | The expression to evaluate. The test passes if the expression is truthy. |
| `label`     | String     | An optional message to display when executing the evaluation.            |

### Usage examples

The following examples show how to use the `assertTrue` command.

#### Assert a JavaScript expression

This example uses `assertTrue` to verify that the text content of two separate views is identical. The `label` states the purpose of the assertion.

```yaml
- copyTextFrom: View A
- evalScript: ${output.viewA = maestro.copiedText}

- copyTextFrom: View B
- evalScript: ${output.viewB = maestro.copiedText}

- assertTrue:
    condition: ${output.viewA == output.viewB}
    label: View A and View B show the same text
```

#### Fail a test with a custom message

This example uses the `condition` and `label` parameters to intentionally fail a test and provide a descriptive reason.

```yaml
- assertTrue:
    condition: ${false}
    label: This will always fail
```

### Related commands

* [assertVisible](/reference/commands-available/assertvisible.md)
* [assertNotVisible](/reference/commands-available/assertnotvisible.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/asserttrue.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
