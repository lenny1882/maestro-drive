> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/retry.md).

# retry

The `retry` command executes a set of commands repeatedly until they succeed or the maximum number of retries is reached. Use this command to handle intermittent or unpredictable behavior in your application.

### Parameters

The `retry` command accepts the following parameters:

| Parameter    | Description                                                                                                                |
| ------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `maxRetries` | **Optional.** Specifies the number of times to retry the commands. The value must be between `0` and `3`. Defaults to `1`. |
| `commands`   | A list of commands to execute. You must provide either `commands` or `file`.                                               |
| `file`       | The path to a file containing a flow to execute. You must provide either `file` or `commands`.                             |

### Usage examples

The following example retries tapping a button up to three times. If the process is successful on the second attempt, the test will proceed to the next step, considering this one successful.

```yaml
- retry:
    maxRetries: 3
    commands:
      - tapOn:
          id: 'button-that-might-not-be-here-yet'
```

{% hint style="info" %}
**Note:** It's an anti-pattern to wrap large parts of your flow in a retry block. You could hide genuine app flakiness, like a button that only works 50% of the time.&#x20;

Wrapping the *entire* flow in a retry command may give unpredictable results.
{% endhint %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/retry.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
