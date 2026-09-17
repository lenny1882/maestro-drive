> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/workspace-management/sequential-execution.md).

# Sequential execution

By default, Maestro executes Flows in a non-deterministic order. This is intentional because testing Flows in isolation ensures they are robust and not dependent on side effects from previous tests.

However, there are scenarios, particularly in Goal-Driven Apps, where you need to validate a strict sequence of events (e.g., creating an account, then verifying a profile, then placing an order). In these cases, you can use the `executionOrder` configuration.

### Configuring the sequence

To force an order, add the `executionOrder` block to your `config.yaml`. You can identify Flows using either their file name (without the `.yaml` extension) or the name property defined inside the Flow itself.

```yaml
# config.yaml
executionOrder:
  continueOnFailure: false # Default is true
  flowsOrder:
    - signup_flow          # Step 1
    - verify_email_flow    # Step 2
    - complete_profile     # Step 3
```

When you configure `executionOrder`, Maestro will:

1. First, run the flows listed in `flowsOrder` sequentially, in the specified order.
2. After that sequence completes, run any discovered Flows that are not included in `flowsOrder` in a non-deterministic order.

#### Handling failures

The `continueOnFailure` flag determines how the sequence behaves if a step fails:

* `true` (Default): If `signup_flow` fails, Maestro will still attempt to run `verify_email_flow`. This is useful for independent tests that happen to be ordered for convenience.
* `false`: If `signup_flow` fails, the entire remaining sequence is cancelled. This is essential for dependent tests where Step 2 cannot possibly succeed if Step 1 fails.

### Best practices and isolation

Even when running in sequence, you should treat your Flows as isolated units. A good rule of thumb is:&#x20;

> Each Flow should be able to run on a completely reset device.

{% hint style="warning" %}
Do not rely on one Flow leaving the app in a specific state for the next one.&#x20;

If you need to ensure a specific state (e.g., being logged in), use a [Hook](/maestro-flows/flow-control-and-logic/hooks.md) or a [Nested Flow](/maestro-flows/flow-control-and-logic/nested-flows.md) at the start of your test.
{% endhint %}

| **Requirement**  | **Recommendation**                                        |
| ---------------- | --------------------------------------------------------- |
| Logic dependency | Use `runFlow` to nest the required setup inside the test. |
| Simple ordering  | Use `executionOrder` in `config.yaml`.                    |
| Stop on error    | Set `continueOnFailure: false`.                           |

### Example: Partial sequencing

If you have five Flows (`A`, `B`, `C`, `D`, `E`) but only care that `A` and `B` run first, you can use the following configuration for the `executionOrder`:

```yaml
executionOrder:
  flowsOrder:
    - flowA
    - flowB
```

Maestro will run `A`, then `B`, and then run `C`, `D`, and `E` in any order.

### Next steps

Now that you have defined how and when your tests run, learn how to view the results:

* [Test reports and artifacts](/maestro-flows/workspace-management/test-reports-and-artifacts.md): Learn how to generate JUnit and HTML reports.
* [AI test analysis](/maestro-flows/workspace-management/ai-test-analysis.md): Use AI to find UI and logic issues in your completed runs.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/workspace-management/sequential-execution.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
