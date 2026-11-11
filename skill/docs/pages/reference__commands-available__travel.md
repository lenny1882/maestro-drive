> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/travel.md).

# travel

Simulate time travel by adjusting the device system clock.

The `travel` command mocks the motion of a user along a specified path at a given speed.

### Parameters

When using the `travel` command, you need to inform the following parameter:

| Parameter | Type      | Description                                                                                                                                                                                                                                                            |
| --------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `timeout` | `integer` | The maximum time to wait, in milliseconds. Defaults to 15000 (15 seconds). If the animation is still running when the timeout is reached, the command succeeds and execution continues. If the animation finishes before the timeout, execution continues immediately. |

### Usage examples

This example simulates a user traveling along a route from Paris to Rome at 150 km/s (about 10 seconds).

```yaml
- travel:
    points:
      - "48.8578065, 2.295188"
      - "46.2276, 5.9900"
      - "43.7230, 10.3966"
      - "41.8902, 12.4922"
    speed: 150000
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/travel.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
