> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/extendedwaituntil.md).

# extendedWaitUntil

Wait for an element with a custom timeout longer than the default.

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
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/extendedwaituntil.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
