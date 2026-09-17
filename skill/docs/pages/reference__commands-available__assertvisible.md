> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/assertvisible.md).

# assertVisible

The `assertVisible` command asserts that a UI element is visible on the screen. If the element is not immediately visible, this command waits for it to appear before timing out.

{% hint style="info" %}

#### Maestro's fluent assertion

If the element is not visible when the command is first called, Maestro will not immediately fail the test. Instead, it will automatically wait and retry for up to 7 seconds, giving the UI time to update or for animations to complete.

If you expect an element to take longer than 7 seconds to appear, use the [`extendedWaitUntil`](/reference/commands-available/extendedwaituntil.md) command.
{% endhint %}

### Parameters

The `assertVisible` command uses a selector to identify the target UI element. You can specify the selector as a single string (shorthand for the `text` property) or as a YAML object with multiple properties.

The following table lists common selector properties. For a complete list of all available selectors, see the [Selectors](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md) documentation.

| Selector   | Description                                                            |
| ---------- | ---------------------------------------------------------------------- |
| `text`     | The text content of the element.                                       |
| `id`       | The ID of the element.                                                 |
| `enabled`  | Specifies if the element is enabled (`true`) or disabled (`false`).    |
| `checked`  | Specifies if the element is checked (`true`) or unchecked (`false`).   |
| `focused`  | Specifies if the element has keyboard focus (`true`) or not (`false`). |
| `selected` | Specifies if the element is selected (`true`) or not (`false`).        |

### Usage examples

#### Assert an element is visible by its text

This example asserts that an element containing the text `My Button` is visible on the screen.

```yaml
- assertVisible: "My Button"
```

#### Assert an element is visible and enabled

This example asserts that an element with the text `My Button` is both visible and enabled.

```yaml
- assertVisible:
    text: "My Button"
    enabled: true
```

The command fails if either of the following conditions is true:

* No element with the text `My Button` is found.
* An element with the text `My Button` is found, but it is disabled.

### Related commands

* [assertNotVisible](/reference/commands-available/assertnotvisible.md)
* [assertTrue](/reference/commands-available/asserttrue.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/assertvisible.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
