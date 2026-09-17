> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/generic-ci-platform.md).

# Generic CI platform

You can run Maestro Flows in the cloud from any CI platform by using the Maestro CLI. This flexible approach works with Jenkins, GitLab CI, Azure DevOps, and more.

{% hint style="info" %}
**Maestro Cloud Plan required.**

Cloud execution is available on the [Maestro Cloud Plan](https://signin.maestro.dev/sign-up).
{% endhint %}

{% hint style="info" %}
Refer to the appropriate guide if you are using one of the following CI/CD integration options:

* [GitHub Actions](/maestro-cloud/ci-cd-integration/github-actions.md)
* [Bitrise](/maestro-cloud/ci-cd-integration/bitrise.md)
* [Bitbucket Pipelines](/maestro-cloud/ci-cd-integration/bitbucket-pipelines.md)
* [CircleCI](/maestro-cloud/ci-cd-integration/circleci.md)
  {% endhint %}

### Prerequisites

* **API Key**: Get your API Key in the [Maestro Dashboard](https://app.maestro.dev/).
* **Project ID**: Obtain your Project ID from your project settings in the dashboard.
* **Build Compatibility**:
  * **Android**: APKs must be ARMv8 compatible.
  * **iOS**: Simulator builds must be provided as a `*.app` directory or a zipped `*.app`.

### Integration steps

{% stepper %}
{% step %}
**Organize your Flows**

Add your Flow files to a single directory in your repository.

```
<root>
├── e2e/
│   ├── subflows/
│   │   └── LoginSubflow.yaml
│   ├── Login.yaml
│   └── Search.yaml
```

In this configuration, files in the root of `e2e` run as top-level Flows. Files in subdirectories can be used as subflows that are not executed, but can be used by other flows at the top level.
{% endstep %}

{% step %}

#### Install the Maestro CLI

Ensure the [Maestro CLI](/maestro-cli/how-to-install-maestro-cli.md) is installed on your CI runner:

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

{% endstep %}

{% step %}

#### Run the cloud command

Execute the `maestro cloud` command as part of your pipeline.

```bash
maestro cloud \
  --api-key "<YOUR_API_KEY>" \
  --project-id "<YOUR_PROJECT_ID>" \
  --name "<uploadName>" \
  --app-file "<APP_FILE>" \
  --flows "./e2e"
```

The following table describes all the parameter you must pass:

| Parameter      | Description                                                                                                                                                                        |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--api-key`    | Your Maestro Cloud API Key.                                                                                                                                                        |
| `--project-id` | Your Maestro Project ID.                                                                                                                                                           |
| `--name`       | **(Optional)** A custom name for this specific upload.                                                                                                                             |
| `--app-file`   | Path to your `.apk` or `.app` binary. Check the [Build your app for the cloud](/maestro-cloud/build-your-app-for-the-cloud.md) guide for more information on how to build the app. |
| `--flows`      | The directory containing your Flows.                                                                                                                                               |

{% hint style="info" %}
For a complete list of advanced flags, refer to the [Maestro CLI commands and options](/maestro-cli/maestro-cli-commands-and-options.md#cloud) reference.
{% endhint %}

{% hint style="info" %}
**Troubleshooting: Connection timeouts**

If your CI runner fails to start the Maestro driver within the default timeframe, you may see a timeout error.

The default timeout is 15 seconds (15000 ms) for Android and 120 seconds (120000 ms) for iOS.

You can extend this by setting a custom millisecond value in your pipeline environment. Here's an example to increase the timeout to 3 minutes (180000 ms):

```bash
export MAESTRO_DRIVER_STARTUP_TIMEOUT=180000
```

{% endhint %}
{% endstep %}

{% step %}

#### Handling results

Once your tests finish running, Maestro follows standard CI practices to let you know how they went:

* **Exit Codes**: The `maestro cloud` command returns `0` on success and `1` if any Flow fails. CI platforms typically use these exit codes to mark a build as failed.
* **Reports**: A link to the upload details in the Maestro Console is printed in the terminal logs for every run.
  {% endstep %}
  {% endstepper %}

#### Next steps

Now that your CI pipeline is connected, consider optimizing your cloud runs:

* Set up notifications via [Slack](/maestro-cloud/notifications/set-slack-notification.md), [email](/maestro-cloud/notifications/set-email-notification.md), or [webhooks](/maestro-cloud/notifications/configure-webhooks.md) to stay informed about build and test results.
* [Configure the operating system](/maestro-cloud/environment-configuration/configure-the-os.md) for your runs to match your application and dependency requirements.
* Define [locales and time zones](/maestro-cloud/environment-configuration/app-locales-and-device-timezones.md) to ensure consistent behavior across environments and regions.
* Explore all the [subcommand options for `claud`.](/maestro-cli/maestro-cli-commands-and-options.md#cloud)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/ci-cd-integration/generic-ci-platform.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
