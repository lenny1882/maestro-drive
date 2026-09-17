> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/assertscreenshot.md).

# assertScreenshot

The `assertScreenshot` command takes a screenshot and matches it against a known good image, performing a visual regression test.

The assertion will fail if the comparison image is too dissimilar, or doesn't exist.

### Syntax

```yaml
- assertScreenshot: splash.png
```

or

```yaml
- assertScreenshot:
    path: screen.png
    cropOn:
      id: banner
    thresholdPercentage: 98
```

### Parameters

| Parameter             | Type             | Description                                                                                                                                                                                                                                                  |
| --------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `path`                | String           | Path to the reference screenshot that the current screen will be compared against. Can be a JavaScript expression. Was likely created by a [takeScreenshot](/reference/commands-available/takescreenshot.md) invocation in a previous run.                   |
| `cropOn`              | Element Selector | Optional. A selector to narrow the screenshot before comparison. The comparison screenshot must also have been cropped. For a complete list of all available selectors, see the [Selectors](https://docs.maestro.dev/api-reference/selectors) documentation. |
| `thresholdPercentage` | Number           | Optional. Percentage match required to pass this assertion. Default is `95`. Can be a variable or a JavaScript expression, as long as it resolves to a number.                                                                                               |
| `label`               | String           | Optional. A message to display when executing the evaluation.                                                                                                                                                                                                |

### Usage Examples

#### Assert against a reference screenshot

This example compares the current screen against `splash.png`, using the default threshold of 95%.

```yaml
- assertScreenshot: splash.png
```

#### Set the threshold from a variable

The threshold is interpolated before the comparison runs, so you can tune it per environment or per device without editing the Flow.

```yaml
appId: com.example.app
env:
  THRESHOLD_PERCENTAGE: 80
---
- assertScreenshot:
    path: ./screenshot.png
    thresholdPercentage: ${THRESHOLD_PERCENTAGE}
```

{% hint style="info" %}
The value must resolve to a number. If it resolves to something else — an empty string from an unset variable, for example — the assertion fails with `Invalid thresholdPercentage for assertScreenshot` rather than falling back to the default.
{% endhint %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/assertscreenshot.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
