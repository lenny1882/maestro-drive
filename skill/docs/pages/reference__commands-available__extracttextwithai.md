> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/extracttextwithai.md).

# extractTextWithAI

{% hint style="warning" %}
This is an experimental feature that uses LLM technology. All feedback is welcome.
{% endhint %}

The `extractTextWithAI` command takes a screenshot of the current view and uses a Large Language Model (LLM) to extract a specified text value. The command writes the extracted text to an output variable (`aiOutput`).

### Parameters

You can specify parameters as a simple string query or as a map for more configuration options.

| Parameter        | Description                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| `query`          | **Required.** A natural language prompt describing the text to extract from the screen.         |
| `outputVariable` | **Optional.** The variable name to store the extracted text. Defaults to `aiOutput`.            |
| `optional`       | **Optional.** Determines if the Flow should continue if the assertion fails. Default is `true`. |

{% hint style="info" %}
Since `extractTextWithAI` is an experimental feature, `optional` is set to `true` by default to prevent unstable AI responses from breaking your CI/CD pipelines. If you want a failed text extraction to stop the test, you must set `optional: false`.
{% endhint %}

### Usage examples

The following examples demonstrate how to use the `extractTextWithAI` command.

#### Basic extraction

This example extracts text based on the query and stores it in the default `aiOutput` variable.

```yaml
- extractTextWithAI: CAPTCHA value
- inputText: ${aiOutput}
```

#### Custom output variable

This example extracts text and stores it in a custom variable named `theCaptchaValue`.

```yaml
- extractTextWithAI:
    query: 'CAPTCHA value'
    outputVariable: 'theCaptchaValue'
```

#### Dynamic content interaction

This example uses `extractTextWithAI` to identify the title of the first search result on a page and tap on that item using the output variable. The test will fail if the AI cannot detect an item title, since `optional: false` is set.

```yaml
- extractTextWithAI: Title of the first item on this page
    optional: false
- tapOn: ${aiOutput}
```

<figure><img src="/files/yhnwxNNaiAuPM6fpmO80" alt=""><figcaption></figcaption></figure>

### Best practices

Use this command for scenarios where standard element selectors are not practical. Good use cases include:

* Content where the view ID or text is unknown beforehand, such as in dynamic search results.
* Information presented as an image, such as promotional banners or CAPTCHAs.

{% hint style="info" %}
`extractTextWithAI` is not a replacement for conventional element selectors. When possible, prefer to use stable IDs or text values with commands like `tapOn`.
{% endhint %}

### Prerequisites

Before using this command, you must configure the AI service. Check the [AI test analysis](/maestro-flows/workspace-management/ai-test-analysis.md) page for more information.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/extracttextwithai.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
