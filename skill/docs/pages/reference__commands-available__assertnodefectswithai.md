> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/assertnodefectswithai.md).

# assertNoDefectsWithAI

{% hint style="warning" %}
This is an experimental feature that uses LLM technology. All feedback is welcome.
{% endhint %}

The `assertNoDefectsWithAI` command takes a screenshot of the current view and sends it to an LLM to analyze for common visual defects. The command checks for issues such as text or UI elements that are cut off, overlapping, or not centered correctly within their containers.

Use this command as a general smoke test to verify that UI elements in your application render as expected.

### Command specifications

The `assertNoDefectsWithAI` accepts only one parameter:

| Parameter  | Type    | Description                                                                                     |
| ---------- | ------- | ----------------------------------------------------------------------------------------------- |
| `optional` | boolean | **Optional.** Determines if the Flow should continue if the assertion fails. Default is `true`. |

{% hint style="info" %}
Since `assertNoDefectsWithAI` is an experimental feature, `optional` is set to `true` by default to prevent unstable AI responses from breaking your CI/CD pipelines. If you want a failed AI assertion to stop the test, you must explicitly set `optional: false`.
{% endhint %}

### Output

The command generates an analysis report in both `HTML` and `JSON` formats. The output files are saved in the directory for the specific test run.

```
~/.maestro
└── tests
    ├── 2024-08-20_213616
    │   ├── ai-(My first flow).json
    │   ├── ai-(My second flow).json
    │   ├── ai-report-(My first flow).html
    │   ├── ai-report-(My second flow).html
```

The HTML report provides a visual summary of the findings.

![AI analysis report showing a screenshot with highlighted defects.](https://2384395183-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fn5KVIOjVkVjYRyVWZ0yT%2Fuploads%2Fgit-blob-c2909fc1a2e650255b19d003fb4aa19d0f25f02c%2Fai_demo.png?alt=media)

### Usage examples

The following video demonstrates the command in action.

{% embed url="<https://youtu.be/tfawnGqEhF0>" %}

### Related content

Access the [AI test analysis](/maestro-flows/workspace-management/ai-test-analysis.md) to learn how to configure the workspace to use the AI based solutions.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/assertnodefectswithai.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
