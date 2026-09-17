> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/waitforanimationtoend.md).

# waitForAnimationToEnd

The `waitForAnimationToEnd` command pauses command execution until on-screen animations or videos complete and the UI becomes static.

### Parameters

This command accepts the following optional parameter:

| Parameter | Type      | Description                                                                                                                                                                                                                                                            |
| --------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `timeout` | `integer` | The maximum time to wait, in milliseconds. Defaults to 15000 (15 seconds). If the animation is still running when the timeout is reached, the command succeeds and execution continues. If the animation finishes before the timeout, execution continues immediately. |

### Usage examples

The following example waits for an animation to finish without a timeout. As a result, the next step is executed only after the animation ends.

```yaml
- waitForAnimationToEnd
```

The following example waits for an animation to finish with a maximum timeout of 5,000 milliseconds. If the animation ends before the timeout, Maestro continues execution without waiting for the full timeout. If the animation does not finish before the timeout is reached, the command is marked as successful, and the flow continues.

```yaml
- waitForAnimationToEnd:
    timeout: 5000
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/waitforanimationtoend.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
