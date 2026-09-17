> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/stoprecording.md).

# stopRecording

Stops an in-progress screen recording that was previously initiated by the `startRecording` command. This command takes no arguments.

{% hint style="info" %}
`stopRecording` does not fail if no recording is in progress. If your flow starts recording conditionally, do not rely on `stopRecording` to fail when no recording was started.
{% endhint %}

### Usage examples

The following example shows how to stop a recording within a test Flow after an action is performed.

```yaml
appId: yourAppId
---
- launchApp
- startRecording: my_recording.mp4
- tapOn: "Login"
- stopRecording
```

### Related commands

* [startRecording](/reference/commands-available/startrecording.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/stoprecording.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
