> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/run-tests-on-maestro-cloud.md).

# Run tests on Maestro Cloud

Upload and execute your Maestro tests on Cloud infrastructure using the CLI.

Running your tests on Maestro Cloud provides reliable scaling, guaranteed parallelism, and seamless CI integration for your mobile and web applications.

This guide explains how to execute your tests using Maestro Cloud via the [Maestro CLI](https://docs.maestro.dev/maestro-cli/).

### Prerequisites

Before running tests on Maestro Cloud, ensure you have the following:

* **Maestro account:** [Sign up for a Maestro account](https://signin.maestro.dev/sign-up).
* **Cloud plan:** Maestro Cloud requires a Cloud plan, which you can start as a trial from the [Maestro Dashboard](https://signin.maestro.dev/sign-up).
* [**Maestro CLI**](/maestro-cli/how-to-install-maestro-cli.md)**:** Install the Maestro CLI on your local machine or CI environment.

{% hint style="info" %}
**Test your app**

When testing your app, you also need the app binary for Android (ARM APK) or iOS (simulator .app bundle). If you don’t know how to build your app, check the [Build your app for the cloud](/maestro-cloud/build-your-app-for-the-cloud.md) guide.
{% endhint %}

### Command syntax

Use the `maestro cloud` command to upload your app and execute your flows. This command can be used both for local testing and within CI pipelines.

```bash
maestro cloud [options] --app-file <app-file> --flows <flow-file-or-directory>
```

### Run Flows on the Cloud

The Maestro CLI provides sample files to help you get started quickly. Use the `download-samples` command to download a sample app and Flow file:

```bash
maestro download-samples
```

{% hint style="info" %}
You can upload your own app and Flow files, but we recommend using the samples first to understand how it works.
{% endhint %}

After running the command, the Maestro CLI downloads a folder containing a set of Flows into your current directory. You can use the included app builds to test both Android and iOS apps:

{% tabs %}
{% tab title="Android" %}
To run an Android test using the sample app and Flow, run the following command:

```bash
cd samples
maestro cloud --app-file sample.apk --flows android-flow.yaml
```

{% endtab %}

{% tab title="iOS" %}
To run an iOS test using the sample app and Flow, run the following command:

```bash
cd samples
maestro cloud --app-file sample.app --flows ios-flow.yaml
```

{% endtab %}
{% endtabs %}

After a successful upload, the CLI prints a link to the Maestro Console.

1. Click the provided link to open the console.
2. Test processing may take a few minutes depending on your other uploads and how many runners are configured on your account.
3. Review the test results, including videos, logs, and hierarchy data.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2FpqrkbAUHtX8GYIPgCrrh%2Fcloud-successful-run.png?alt=media&amp;token=8d355dac-75a1-4b75-aaf6-9955506742e8" alt=""><figcaption></figcaption></figure>

### Authentication and project selection

If you belong to multiple organizations or projects, use the following flags to avoid interactive prompts:

* `--api-key`: Your Maestro Cloud API key.
* `--project-id`: The specific project ID for the upload.

The following example demonstrates how to use these flags:

```bash
maestro cloud --api-key <YOUR_API_KEY> --project-id <YOUR_PROJECT_ID> --app-file sample.apk --flows flow.yaml
```

For a complete list of cloud command options, see the [Maestro CLI reference](/maestro-cli/maestro-cli-commands-and-options.md).

### Next steps

After verifying your cloud execution, [learn how to build your app](/maestro-cloud/build-your-app-for-the-cloud.md) or integrate Maestro Cloud into your development workflow:

* [CI/CD Integration](/maestro-cloud/ci-cd-integration.md): Automate your tests using GitHub Actions, Bitrise, CircleCI, and more.
* [Advanced features](/maestro-cloud/advanced-features.md): Manage secrets, configure locales, and use IP allowlists.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/run-tests-on-maestro-cloud.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
