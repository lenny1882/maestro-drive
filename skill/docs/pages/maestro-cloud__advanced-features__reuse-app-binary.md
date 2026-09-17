> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/advanced-features/reuse-app-binary.md).

# Reuse app binary

To run multiple test scenarios on the same build, you can reuse a previously uploaded binary instead of re-uploading the same file. This optimization saves time and bandwidth.

{% hint style="info" %}
**Maestro Cloud Plan required.**

App binary reuse is available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Find the app binary ID

When you upload an app to Maestro Cloud, a unique app binary ID is generated. You can find this ID in two locations:

* **CLI output**: The ID is returned in the terminal response immediately after a successful upload.

<figure><img src="/files/Syi8pecMYAw67jRHXvMs" alt=""><figcaption></figcaption></figure>

* **Maestro dashboard**: The ID is visible at the top of the run details page.

<figure><img src="/files/b3JRww0X7uVYjbMksq5A" alt=""><figcaption></figcaption></figure>

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
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/advanced-features/reuse-app-binary.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
