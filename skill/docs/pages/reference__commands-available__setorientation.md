> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/setorientation.md).

# setOrientation

Sets the orientation of the virtual device.

{% hint style="info" %}
This command is not supported on Web.
{% endhint %}

### Arguments

The command accepts one of the following string arguments.

| Argument          | Description                                                                      |
| ----------------- | -------------------------------------------------------------------------------- |
| `PORTRAIT`        | The device is in an upright, vertical orientation. **Default**.                  |
| `LANDSCAPE_LEFT`  | The device is in a horizontal orientation, rotated 90 degrees counter-clockwise. |
| `LANDSCAPE_RIGHT` | The device is in a horizontal orientation, rotated 90 degrees clockwise.         |
| `UPSIDE_DOWN`     | The device is in an inverted, vertical orientation.                              |

### Usage examples

The following example sets the device orientation to landscape left.

```yaml
- setOrientation: LANDSCAPE_LEFT
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/setorientation.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
