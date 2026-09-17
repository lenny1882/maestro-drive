> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-studio/environments-and-variables.md).

# Environments and variables

Maestro Studio allows you to manage dynamic configurations through Environments. This is essential for running the same tests across different app variants, server environments, or localized settings without hardcoding values into your tests.

### Organize your environments

To keep your tests maintainable, it is recommended to separate your environment configurations. Common use cases for different environments include:

* **Platform Variants**: Running tests against the same app on multiple platforms with different properties, such as a unique `appId` for Android vs. iOS.
* **Host Environments**: Testing against different backends (e.g., Staging vs. Production) using different credentials or API endpoints.
* **Whitelabel Variants**: Running tests against variants of a whitelabelled application that require different test data or theme settings.

### Add environments

Environments in Maestro enable you to define two key types of configurations:

* **Environment Variables**: Key-value pairs used to inject dynamic data into your tests (e.g., `BASE_URL`, `USER_EMAIL`).
* **Configure Tags**: Specify the tags to be included and excluded when running the tests. This allows you to create specific labels used to filter which tests are executed during a run (e.g., `smoke`, `regression`).

When you start using Maestro Studio, you have the default environment, called `None`. But, to better organize your tests, it's recommended to have environments and environment variables separated.

To add a new environment, follow these steps:

1. Open the Maestro Studio.
2. In Maestro Studio, click the **Env** icon.
3. Click on **Manage Environments**, then click **Create**.

<figure><img src="/files/azvY5WUxhm0z5vqr15Mi" alt=""><figcaption></figcaption></figure>

4. Specify the **Included** and **Excluded** tags for this environment.
5. Add your variables as **Key-Value** pairs.

{% hint style="success" %}

#### Example

Imagine you have created a set of generic test to be used across all available operating systems. To ensure the correct tests run for a specific platform, you can create a dedicated Android Environment:

* **Filter with Tags**: Add `Android` to **includedTags**. This ensures that only tests applicable to Android are executed. Alternatively, add `iOS` and `Web` to **excludedTags.**
* **Define Variables**: Specify an `appId` variable containing the unique package name for your Android app (e.g., `com.example.android`).
  {% endhint %}

<figure><img src="/files/TY4oYTy8lL5zuPhgIW6h" alt=""><figcaption></figcaption></figure>

### Using variables in your Tests

Environment variables are available throughout your test wherever a JavaScript expression is supported. You are not limited to a specific `env` section; you can use them directly in UI commands or logic gates.

You can use the variables as direct iputs, using `${variableName}` to inject values into text fields:

```yaml
- inputText: ${email}
```

You can also use the variables to control test execution based on the environment:

```yaml
- runFlow:
    when:
      true: ${APP_ID == "com.example.android"}
    commands:
      - tapOn: "Start"
```

### Next steps

To take the next step with Maestro Studio, learn how to run your tests using the Maestro Cloud solution.

If you want to deepen your understanding of how Maestro works, explore the related documentation:

* [**Parameters and constants**](/maestro-flows/flow-control-and-logic/parameters-and-constants.md)**:** Pass dynamic values to tests using parameters and inline constants.
* [**Test discovery and tags**](/maestro-flows/workspace-management/test-discovery-and-tags.md)**:** Organize tests with tags and control which tests run using include/exclude filters.
* [**Conditions**](/maestro-flows/flow-control-and-logic/conditions.md): Execute commands conditionally based on visibility, platform, or custom expressions.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-studio/environments-and-variables.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
