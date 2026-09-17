> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/assertwithai.md).

# assertWithAI

{% hint style="warning" %}
This is an experimental feature that uses LLM technology. All feedback is welcome.
{% endhint %}

The `assertWithAI` command uses Large Language Models to validate the visual state of an application. The command captures a screenshot of the current screen and uploads it to an LLM along with a natural language assertion. The model evaluates the screenshot and returns a boolean result indicating whether the assertion is true.

This command is intended for scenarios where standard element-based assertions are difficult or impossible to implement, such as identifying complex visual patterns or dynamic content like two-factor authentication prompts.

### Command specifications

The following table describes the fields available for the `assertWithAI` command.

| Field       | Type    | Description                                                                                     |
| ----------- | ------- | ----------------------------------------------------------------------------------------------- |
| `assertion` | string  | The natural language description of the expected UI state to be evaluated by the LLM.           |
| `optional`  | boolean | **Optional.** Determines if the Flow should continue if the assertion fails. Default is `true`. |

{% hint style="info" %}
Since `assertWithAI` is an experimental feature, `optional` is set to `true` by default to prevent unstable AI responses from breaking your CI/CD pipelines. If you want a failed AI assertion to stop the test, you must explicitly set `optional: false`.
{% endhint %}

### Output artifacts

The command generates detailed reports in both HTML and JSON formats. These files are stored in a timestamped subdirectory within the Maestro configuration folder.

The following structure shows the location and naming convention for these artifacts:

```
~/.maestro
└── tests
    ├── 2024-08-20_213616
    │   ├── ai-(My first flow).json
    │   ├── ai-(My second flow).json
    │   ├── ai-report-(My first flow).html
    │   ├── ai-report-(My second flow).html

```

The reports provide visual confirmation of the assertion logic applied by the model.

### Usage examples

The following examples demonstrate how to implement `assertWithAI` for different validation scenarios.

#### Basic visibility check

This example validates that specific text fields are present on the screen.

```yaml
- assertWithAI:
    assertion: Login and password text fields are visible.

```

#### Complex visual validation

Use natural language to describe complex UI elements, such as a two-factor authentication (2FA) screen. To require the test to pass, set `optional: false`, so the test fails if the assertion is false.

```yaml
- assertWithAI:
    assertion: A two-factor authentication prompt, with space for 6 digits, is visible.
    optional: false
```

#### Video demonstration

The following video demonstrates the command in action.

{% embed url="<https://www.youtube.com/watch?v=tfawnGqEhF0>" %}

### Related content

Access the [AI test analysis](/maestro-flows/workspace-management/ai-test-analysis.md) to learn how to configure the workspace to use the AI based solutions.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/assertwithai.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
