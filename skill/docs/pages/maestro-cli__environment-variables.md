> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cli/environment-variables.md).

# Environment variables

Reference for all environment variables supported by the Maestro CLI, covering   logging, analytics, cloud authentication, and driver behavior.

You can configure the Maestro CLI behavior using the following environment variables. Set them in your shell or CI/CD environment before running any `maestro` command.

| Variable                                     | Type    | Default                                              | Description                                                                                                                                                                                                                              |
| -------------------------------------------- | ------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED` | Boolean | `false`                                              | Disables the notification displayed on each run about AI analysis.                                                                                                                                                                       |
| `MAESTRO_CLI_LOG_PATTERN_CONSOLE`            | String  | `%highlight([%5level]) %msg%n`                       | Controls the console logging format using [Logback layout](https://logback.qos.ch/manual/layouts.html) patterns.                                                                                                                         |
| `MAESTRO_CLI_LOG_PATTERN_FILE`               | String  | `%d{HH:mm:ss.SSS} [%5level] %logger.%method: %msg%n` | Controls the file logging format using [Logback layout](https://logback.qos.ch/manual/layouts.html) patterns. For more information, see [Test reports and artifacts](/maestro-flows/workspace-management/test-reports-and-artifacts.md). |
| `MAESTRO_CLI_NO_ANALYTICS`                   | Boolean | `false`                                              | Disables Maestro analytics collection.                                                                                                                                                                                                   |
| `MAESTRO_CLOUD_API_KEY`                      | String  | Not set                                              | The API key used when communicating with Maestro Cloud. Required for cloud operations. For more information, see [Run tests on Maestro Cloud](/maestro-cloud/run-tests-on-maestro-cloud.md).                                             |
| `MAESTRO_DISABLE_UPDATE_CHECK`               | Boolean | `false`                                              | Disables the check for newer Maestro versions when running the CLI.                                                                                                                                                                      |
| `MAESTRO_DRIVER_STARTUP_TIMEOUT`             | Number  | `15000`                                              | The maximum time (in milliseconds) to wait for a driver to start. For more information, see [Run your first test with the Maestro CLI](/maestro-cli/run-your-first-test-with-the-maestro-cli.md).                                        |

#### Usage examples

{% tabs %}
{% tab title="Disable analytics" %}

```shellscript
export MAESTRO_CLI_NO_ANALYTICS=true
export MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true
maestro test my-flow.yaml
```

{% endtab %}

{% tab title="Cloud authentication" %}

```shellscript
export MAESTRO_CLOUD_API_KEY=your_api_key_here
maestro cloud --app-file app.apk --flows ./flows
```

{% endtab %}

{% tab title="Driver startup timeout" %}

```shellscript
export MAESTRO_DRIVER_STARTUP_TIMEOUT=30000
maestro test my-flow.yaml
```

{% endtab %}

{% tab title="Custom log format" %}

```shellscript
export MAESTRO_CLI_LOG_PATTERN_CONSOLE="%d{HH:mm:ss} [%level] %msg%n"
maestro test my-flow.yaml
```

{% endtab %}
{% endtabs %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cli/environment-variables.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
