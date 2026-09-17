> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/longpresson.md).

# longPressOn

The `longPressOn` command performs a long press (3 seconds) gesture on a UI element. It is the long-press equivalent of the [`tapOn` ](/reference/commands-available/tapon.md)command.

### Usage examples

The `longPressOn` command accepts the same properties as `tapOn`, including [Selectors](/reference/selectors.md). The following examples demonstrate how to long press on text, an ID, or a point coordinates:

```yaml
- longPressOn: Text
- longPressOn:
    id: view_id
- longPressOn:
    point: 50%,50%
```

#### Long press on a specific point within an element

To long press on a specific point relative to an element, combine the selector with a `point` property. The following example finds an element containing the text "A text with a hyperlink" and performs a long press at the coordinates `90%,50%` within that element's bounds (effectively targeting the end of the sentence).

```yaml
- longPressOn:
    text: "A text with a hyperlink"
    point: "90%,50%"
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
GET https://docs.maestro.dev/reference/commands-available/longpresson.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
