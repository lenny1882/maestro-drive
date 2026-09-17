> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/wait-commands.md).

# Wait commands

In a perfect world, apps respond instantly. In reality, network latency, slow animations, and background processing can cause tests to fail because Maestro tries to interact with an element that isn't ready yet.

Maestro provides several ways to handle these timing issues. This guide helps you choose the right strategy to make your Flows resilient and fast.

### Automatic waiting

Before using a dedicated wait command, remember the golden rule of Maestro timing:

> If you expect an element to appear or disappear within a short period, use an assertion.

Maestro’s assertions are smart. They don't just check once and fail, they poll the UI continuously until the element appears or the timer expires. This makes them the most efficient way to wait because the test continues immediately after the condition is met.

* [`assertVisible`](/reference/commands-available/assertvisible.md): Best for waiting for a screen to load, a success message to appear, or a button to become active.
* [`assertNotVisible`](/reference/commands-available/assertnotvisible.md): Best for waiting for a loading spinner to disappear or a modal to close.

```yaml
# assertVisible example
- tapOn: "Submit"
- assertVisible: "Success!" # Maestro will wait for this to appear
```

### Wait strategies

When assertions aren't enough, such as for long-running processes or stabilizing complex animations, you can use one of the specific wait commands.

#### Waiting for long processes (`extendedWaitUntil`)

Use [`extendedWaitUntil`](/reference/commands-available/extendedwaituntil.md) for slow network responses (like processing a payment or generating a large report) that are guaranteed to take longer than a few seconds.

This command optimizes your test because Maestro moves on immediately if the element appears faster than the timeout.

```yaml
- extendedWaitUntil:
    visible: "Payment Confirmed"
    timeout: 30000            # Wait up to 30 seconds
```

{% hint style="success" %}

#### **Set realistic timeouts**

Avoid setting every timeout to 60 seconds. If a screen should load in 5 seconds, let the default assertion handle it. This helps catch performance regressions early.
{% endhint %}

#### Waiting for UI stability (`waitForAnimationToEnd`)

Sometimes elements are visible but still moving (e.g., a list sliding into place or a side menu opening). Interacting too early can cause missed taps.

Use the [`waitForAnimationToEnd`](/reference/commands-available/waitforanimationtoend.md) command to ensure the test continues only after the animation finishes.

```yaml
- waitForAnimationToEnd:
    timeout: 5000 # Wait up to 5s for movement to stop
```

{% hint style="success" %}

#### Ghost taps

If you experience "ghost taps" (tapping a button that exists but isn't yet clickable), combine your wait logic with [`retryTapIfNoChange: true`](/reference/commands-available/tapon.md#retry-a-tap-if-the-ui-is-unresponsive) in your `tapOn` command.
{% endhint %}

### Next steps

For full technical details and parameter lists, visit the individual command pages:

* [`assertVisible`](/reference/commands-available/assertvisible.md): Your primary tool for standard waits.
* [`assertNotVisible`](/reference/commands-available/assertnotvisible.md): For waiting for elements to disappear.
* [`extendedWaitUntil`](/reference/commands-available/extendedwaituntil.md): For smart, long-duration waiting.
* [`waitForAnimationToEnd`](/reference/commands-available/waitforanimationtoend.md): For stabilization after UI transitions.

Or continue learning about flow control by exploring the [Loops](/maestro-flows/flow-control-and-logic/loops.md) or [Conditions](/maestro-flows/flow-control-and-logic/conditions.md) guides.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/wait-commands.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
