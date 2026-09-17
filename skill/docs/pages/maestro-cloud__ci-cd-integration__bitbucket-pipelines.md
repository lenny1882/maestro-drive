> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/bitbucket-pipelines.md).

# Bitbucket Pipelines

Integrate Maestro Cloud into your Bitbucket CI/CD workflow using the [Maestro Cloud Upload Pipe](https://bitbucket.org/product/features/pipelines/integrations?search=maestro\&p=mobiledevinc/maestro-cloud-upload). This native integration allows you to automatically upload and execute your Flows on enterprise-grade infrastructure directly from your CI/CD pipeline.

{% hint style="info" %}
**Maestro Cloud Plan required.**

Bitbucket integration is available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

{% stepper %}
{% step %}

#### Setup environment variables

To authenticate with Maestro Cloud, you must add your credentials as secret variables in Bitbucket.

1. On Bitbucket, navigate to your **Repository → Repository settings → Repository Variables**.
2. Add the following secured variables:
   * `MDEV_API_KEY`: Your Maestro Cloud API Key.
   * `MDEV_PROJECT_ID`: Your specific Maestro Project ID.

{% hint style="info" %}
Access the [Maestro Dashboard](https://app.maestro.dev/) to get your API Key and Project ID.
{% endhint %}
{% endstep %}

{% step %}

#### Organize your Flows

Maestro expects your Flow files to be located in a specific directory (`.maestro/`) at the root of your repository.

1. Create a `.maestro/` directory at your repository root.
2. Place all Flow files directly inside `.maestro/` to be executed as a standalone test.
3. Place all "utility" Flows (those used by `runFlow`) in a `subflows/` subdirectory. This way you prevent these Flows from executing as top-level tests.

```
<root>
├── .maestro/
│   ├── subflows/
│   │   └── LoginSubFlow.yaml    # Only runs when called via runFlow
│   ├── Login.yaml               # Executed as a top-level Flow
│   ├── Add_to_Cart.yaml         # Executed as a top-level Flow
│   └── Search.yaml              # Executed as a top-level Flow
```

{% endstep %}

{% step %}

#### Add the Maestro Cloud Pipe

Update your `bitbucket-pipelines.yml` file to include the [Maestro Cloud Upload Pipe](https://bitbucket.org/mobiledevinc/maestro-cloud-upload/src/master/README.md). This step should occur immediately after your app has successfully built.

{% hint style="warning" %}
All file paths provided below are relative to the repository source root.
{% endhint %}

{% tabs %}
{% tab title="Android" %}

```yaml
script:
  - pipe: mobiledevinc/maestro-cloud-upload:1.5.0
    variables:
      MDEV_API_KEY: $MDEV_API_KEY
      MDEV_PROJECT_ID: $MDEV_PROJECT_ID
      MDEV_APP_FILE: app/build/outputs/apk/debug/app-debug.apk
```

{% endtab %}

{% tab title="iOS" %}

```yaml
script:
  - pipe: mobiledevinc/maestro-cloud-upload:1.5.0
    variables:
      MDEV_API_KEY: $MDEV_API_KEY
      MDEV_PROJECT_ID: $MDEV_PROJECT_ID
      MDEV_APP_FILE: <app_name>.app
```

{% endtab %}
{% endtabs %}

Once triggered, the Maestro Cloud Pipe automates the following lifecycle:

* Uploads your app binary and Flow workspace to Maestro Cloud.
* Runs your tests on dedicated cloud infrastructure.
* By default, the pipe waits for all Flows to complete. You can configure this option.
* Returns an exit code of `0` on success or `1` if failures are detected, allowing you to block builds based on test results.
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
GET https://docs.maestro.dev/maestro-cloud/ci-cd-integration/bitbucket-pipelines.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
