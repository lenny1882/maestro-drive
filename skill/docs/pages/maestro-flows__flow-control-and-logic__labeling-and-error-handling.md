> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/labeling-and-error-handling.md).

# Labeling and error handling

Beyond their core actions, most Maestro commands share two attributes, `label` and `optional`. These allow you to refine how tests are reported, documented, and how they behave when faced with unexpected UI states.

### Command labeling

The `label` attribute allows you to replace the default technical output in the console and test reports with a custom, human-readable description.

Some of the reasons to include a label include:

* **Intent over Implementation**: Instead of showing a technical selector (like a resource ID), a label describes the business logic of the step.
* **Security and privacy**: Mask sensitive data (like passwords or PII) so they don't appear in shared console outputs, team dashboards, or screen recordings.
* **Maintainability**: Labels act as "live" documentation that stays with the command, making it easier for collaborators to understand the flow's purpose.

The following code snippet shows how you can use labels to improve the test reporting:

```yaml
- tapOn:
    id: "buy-now-btn-v2"
    label: "Confirm purchase on the final checkout screen"

- inputText:
    text: "super-secret-password-123"
    label: "Enter the secure test user password"

- swipe:
    direction: LEFT
    label: "Navigate through the onboarding tutorial"
```

If you use labels, the output will be clearer to read and understand:

```shellscript
✅ Input text "super-secret-password-123" ## Standard output
✅ Enter the secure test user password    ## Output using labels
```

{% hint style="info" %}
While labels hide sensitive text from the UI and console summaries, the actual values remain visible in raw internal debug logs.
{% endhint %}

### Error handling with `optional`

By default, Maestro follows a "fail-fast" philosophy, which means that if a command fails to find an element or execute an action, the Flow stops immediately. The `optional: true` attribute overrides this, allowing the test to continue even if a specific step fails.

Some common use cases for `optional` include:

* **Non-critical UI**: Verifying elements that don't block the user journey, such as a "new feature" badge or a footer link.
* **Transient content**: Handling banners, pop-ups, or A/B test variations that might only appear for specific users or regions.
* **Environmental handling**: Dealing with system dialogs or sync messages that appear inconsistently and aren't critical to your test's objective.

The following code snippet shows an example of how you can use `optional`:

```yaml
- launchApp: com.example.example
- assertVisible:
    text: Summer sale is here!
    optional: true # If the banner isn't there, the test continues
- tapOn: Sign up now!
```

If an optional command fails, it is marked with a warning icon in the output, but the execution proceeds to the next step:

```shellscript
✅ Launch app "com.example.example"
⚠️ Assert that "Summer sale is here!" is visible (warned)
✅ Tap on "Sign up now!"
```

Maestro uses the following rules to define the default value of `optional` for the available commands:

* Standard Commands: Default to `optional: false`.
* AI Commands: Commands such as [`assertNoDefectsWithAI`](/reference/commands-available/assertnodefectswithai.md) and [`assertWithAI`](/reference/commands-available/assertwithai.md) default to `optional: true` due to their probabilistic nature.

{% hint style="info" %}
While `optional` can be added to any command, it has no practical effect on actions that cannot technically "fail" to execute, such as `back`, `stopRecording`, or `clearState`.
{% endhint %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/labeling-and-error-handling.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
