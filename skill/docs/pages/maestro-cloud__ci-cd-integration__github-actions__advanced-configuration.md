> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/github-actions/advanced-configuration.md).

# Advanced configuration

Once you have the basics running, you can customize how Maestro Cloud executes your Flows using the options below.

### Custom workspace location

By default, the action looks for a `.maestro` folder in the root of your repository. If your Flows are located elsewhere, use the `workspace` argument.

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    workspace: myFlows/
```

### Custom upload name

Maestro Cloud automatically names your upload based on the context:

1. **Pull Request**: Uses the PR title.
2. **Push**: Uses the commit message.
3. **Fallback**: Uses the commit SHA.

To override this manually, use the `name` argument:

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    name: My Upload
```

### Async mode and timeouts

If you don't want the GitHub Action to wait for the tests to finish (e.g., "fire and forget"), set `async` to `true`.

{% hint style="info" %}
When running in async mode, the action will not fail if tests fail, and output variables like `MAESTRO_CLOUD_FLOW_RESULTS` will not be available.
{% endhint %}

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    async: true
```

If you want to wait for results but need more time than the default 30 minutes, use the `timeout` argument (in minutes).

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    timeout: 90 # Wait for 90 minutes
```

### Environment variables

You can pass environment variables to your Maestro Flows (accessible via `${env.VARIABLE_NAME}` in your YAML flows) using the `env` argument. Use a multiline string for multiple variables.

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    env: |
      USERNAME=<username>
      PASSWORD=<password>
```

### Filtering with Tags

You can use [Tags](/maestro-flows/workspace-management/test-discovery-and-tags.md) to include or exclude specific Flows from the run.

* `include-tags`: Only run Flows with these tags.
* `exclude-tags`: Skip Flows with these tags.

Values can be single tags or comma-separated lists.

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    include-tags: dev, pull-request
    exclude-tags: excludeTag
```

### Reusing uploaded binaries

If you have a workflow where you want to run multiple distinct test suites against the same app binary without re-uploading it, you can capture the `app-binary-id` output from a previous step.

```yaml
- id: upload
  uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip

- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-binary-id: ${{ steps.upload.outputs.MAESTRO_CLOUD_APP_BINARY_ID }}
```

Access the [Reuse app binary](/maestro-cloud/advanced-features/reuse-app-binary.md) guide for more information.

### Device Locale

To run your tests on a device with a specific locale (default is `en_US`), use the `device-locale` argument. The value is a combination of:

```
 lowercase ISO-639-1 code + _ + uppercase ISO-3166-1 code
```

The following code snippet displays an example:

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v2.0.2
  with:
    api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
    project-id: 'proj_01example0example1example2'
    app-file: app.zip
    device-locale: de_DE
```

Access the [App locales and device timezones](/maestro-cloud/environment-configuration/app-locales-and-device-timezones.md) guide for more information.

#### Next steps

* [Outputs and triggers](/maestro-cloud/ci-cd-integration/github-actions/outputs-and-triggers.md): Learn how to access build results and configure CI triggers.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/ci-cd-integration/github-actions/advanced-configuration.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
