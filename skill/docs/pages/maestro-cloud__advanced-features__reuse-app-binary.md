> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/advanced-features/reuse-app-binary.md).

# Reuse app binary

Use --app-binary-id to skip re-uploading your app and save time. Find the binary ID in CLI output or Maestro dashboard.

To run multiple test scenarios on the same build, you can reuse a previously uploaded binary instead of re-uploading the same file. This optimization saves time and bandwidth.

{% hint style="info" %}
**Maestro Cloud Plan required.**

App binary reuse is available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Find the app binary ID

When you upload an app to Maestro Cloud, a unique app binary ID is generated. You can find this ID in two locations:

* **CLI output**: The ID is returned in the terminal response immediately after a successful upload.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2FW6QBVL8fIIbRShiuz7B2%2Fcli-app-binary-id.png?alt=media&amp;token=31b93105-0c6d-4284-842c-ffaa9c7c48b8" alt=""><figcaption></figcaption></figure>

* **Maestro dashboard**: The ID is visible at the top of the run details page.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2Fz6Op4S1DlFgi97qtFrmN%2Fdashboard-binary-app.png?alt=media&amp;token=7253e545-64d0-43f9-ac66-26c7c63f0edd" alt=""><figcaption></figcaption></figure>

### Use the app binary ID

Use the `--app-binary-id` flag to reference a cached binary for subsequent test runs. You must copy the ID form the CLI or from the dashboard and pass it when running the test:

```bash
maestro cloud \
  --api-key <YOUR_API_KEY> \
  --project-id <YOUR_PROJECT_ID> \
  --app-binary-id <BINARY_ID> \
  .maestro/
```

This tells Maestro to skip the binary re-upload and go straight to execution.

### Security

Reusing an app binary is a performance optimization and does not compromise security.

* **Access**: Only you or authorized members of your project can access the binary from your previous uploads.
* **Privacy**: All cloud devices are wiped after every test execution. Even after the test completes, no one, including the Maestro team, has access to the running application data.

### Related content

* [Maestro CLI reference](/maestro-cli/maestro-cli-commands-and-options.md): Full list of all available parameters.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/advanced-features/reuse-app-binary.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
