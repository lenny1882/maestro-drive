> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/doubletapon.md).

# doubleTapOn

Double-taps a UI element or a specific point on the screen.

### Arguments

The `doubleTapOn` command accepts a [Selector](/reference/selectors.md) and a `delay` :

| Argument                            | Description                                                                                                                                                                                                                             |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Selector](/reference/selectors.md) | The element to double-tap. This can be a string representing the element's text, the accessibility ID, or an object specifying a selector. Accepts the same selectors as the [`tapOn`](/reference/commands-available/tapon.md) command. |
| `delay`                             | (Optional) The delay in milliseconds between the first and second tap. Defaults to `100`.                                                                                                                                               |

### Usage examples

You can use the shorthand approach by providing the visible text of the element. This example double-taps an element with the visible text `My Button`:

```yaml
- doubleTapOn: My Button
```

The implementation above produces the same result as using [`tapOn`](/reference/commands-available/tapon.md) with the `repeat` configuration.

```yaml
- tapOn:
    text: My Button
    repeat: 2
    delay: 100
```

If you need to use a different selector, or if you need to change the delay between the first and second tap, use this approach. This example uses an `id` selector to find the element and specifies a custom delay between taps:

```yaml
- doubleTapOn:
    id: "someId"
    delay: 200
```

### Related commands

* [tapOn](/reference/commands-available/tapon.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/doubletapon.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
