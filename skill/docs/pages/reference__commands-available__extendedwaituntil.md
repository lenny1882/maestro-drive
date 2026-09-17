> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/extendedwaituntil.md).

# extendedWaitUntil

The `extendedWaitUntil` command pauses the test flow until a specified element becomes visible or not visible on the screen. The command completes as soon as the condition is met. If the condition is not met before the timeout expires, the command fails.

{% hint style="success" %}
Use `extendedWaitUntil` before `assertVisible` or `assertNotVisible` when your app needs longer than the default 7-second timeout. The command keeps checking until the condition is met or your extended timeout is reached, so it does not stop after 7 seconds.
{% endhint %}

### Arguments

| Argument     | Description                                                                                           |
| ------------ | ----------------------------------------------------------------------------------------------------- |
| `visible`    | The selector for the element to wait for. The command proceeds when the element is visible.           |
| `notVisible` | The selector for the element to wait for. The command proceeds when the element is no longer visible. |
| `timeout`    | The maximum time to wait, in milliseconds.                                                            |

For a complete list of available selectors, see the [Selectors](/reference/selectors.md) reference.

### Usage examples

#### Wait for an element to be visible

This example waits up to 10 seconds for an element containing the text "My text that should be visible" to appear.

```yaml
- extendedWaitUntil:
    visible: "My text that should be visible"
    timeout: 10000
```

#### Wait for an element to be not visible

This example waits up to 10 seconds for an element with the ID `elementId` to disappear.

```yaml
- extendedWaitUntil:
    notVisible: 
        id: "elementId"
    timeout: 10000
```

### Related content

Learn [how to use wait commands](/maestro-flows/flow-control-and-logic/wait-commands.md) in Maestro to create reliable tests.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/extendedwaituntil.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
