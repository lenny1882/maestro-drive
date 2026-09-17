> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/assertnotvisible.md).

# assertNotVisible

The `assertNotVisible` command asserts that a UI element is not visible on the screen. If the element is currently visible, this command waits for it to disappear before proceeding.

{% hint style="info" %}

#### Maestro's fluent assertion

If the element is visible when the command is first called, Maestro will not immediately fail the test. Instead, it will automatically wait and retry for up to 7 seconds, giving the UI time to update or for animations to complete.

If you expect an element to take longer than 7 seconds to disappear, use the [`extendedWaitUntil`](/reference/commands-available/extendedwaituntil.md) command.
{% endhint %}

### Parameters

This command accepts the same selectors as `tapOn`. The following table lists commonly used parameters.

| Parameter  | Type      | Description                                                            |
| ---------- | --------- | ---------------------------------------------------------------------- |
| `text`     | `string`  | The text content of the element.                                       |
| `id`       | `string`  | The ID of the element.                                                 |
| `enabled`  | `boolean` | Specifies if the element is enabled (`true`) or disabled (`false`).    |
| `checked`  | `boolean` | Specifies if the element is checked (`true`) or unchecked (`false`).   |
| `focused`  | `boolean` | Specifies if the element has keyboard focus (`true`) or not (`false`). |
| `selected` | `boolean` | Specifies if the element is selected (`true`) or not (`false`).        |

For a complete list of all available selectors, see the [Selectors](/reference/selectors.md) reference.

### Usage examples

The following examples demonstrate how to use `assertNotVisible`.

#### Assert an element with specific text is not visible

This example uses the shorthand syntax to assert that an element with the text `My Button` is not on the screen.

```yaml
- assertNotVisible: "My Button"
```

#### Assert an element matching multiple properties is not visible

This example asserts that an enabled element with the text `My Button` is not visible. The command passes if no visible element matches both the `text` and `enabled` criteria. The test only fails if an element that is both enabled and has the text `My Button` is currently visible on the screen.

```yaml
- assertNotVisible:
    text: "My Button"
    enabled: true
```

### Related commands

* [`assertVisible`](/reference/commands-available/assertvisible.md)
* [`assertTrue`](/reference/commands-available/asserttrue.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/assertnotvisible.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
