> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/notifications/configure-webhooks.md).

# Configure webhooks

Enable webhooks to send real-time notifications about upload results from a specific Maestro project to your custom workflows, monitoring systems, or external services.

{% hint style="info" %}
**Maestro Cloud Plan required.** Webhook notifications are available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Set up a webhook

Follow these steps to configure a webhook in the Maestro:

1. Log in to the [Maestro Dashboard](https://app.maestro.dev/).
2. Click **Settings** in the sidebar.
3. Select the project for which you want to configure webhooks.
4. Under **Webhook Management**, enter your webhook URL. You must provide the full URL where Maestro should send POST requests.

<figure><img src="/files/EDu8TM5wZe7k7txhef3B" alt=""><figcaption></figcaption></figure>

{% hint style="warning" %}
Ensure that your webhook endpoint can handle POST requests and is publicly accessible.
{% endhint %}

If you need to authenticate webhook requests from Maestro Cloud, you can use the **Webhook Token** generated after you add the webhook URL. Use this token in your webhook endpoint as a **Bearer token** to authenticate requests from Maestro.

<figure><img src="/files/D3JMxLnhVBDSktUae5ad" alt=""><figcaption></figcaption></figure>

You can update URLs or tokens, or disable an integration at any time from the settings page.

{% hint style="success" %}

#### **Multiple Webhooks**

You can configure multiple webhooks for the same project to trigger different services.
{% endhint %}

You can update URLs or tokens, or disable an integration at any time from the settings page.

### Webhook payload example

When an upload event occurs, Maestro sends a POST request with a JSON payload. The payload also includes [tags](/maestro-flows/workspace-management/test-discovery-and-tags.md) and [custom properties](/maestro-flows/workspace-management/test-reports-and-artifacts.md) defined in your flows, allowing you to filter and route events if necessary.

Below is an example of the data sent:

```json
{
  "id": "mupload_01kghgqmsqfa38z5gjpxpz3wv5",
  "name": "Upload 7",
  "url": "https://app.maestro.dev/project/proj_01kdze2nbdfactc52yg9jqdb0n/maestro-test/app/app_01kgfx3k6gfx4t84qyr8f3q9nj/upload/mupload_01kghgqmsqfa38z5gjpxpz3wv5",
  "githubBranch": null,
  "envVariables": {
    "MAESTRO_FILENAME": "android-advanced-flow"
  },
  "platform": "ANDROID",
  "deviceModel": "iPhone-17-Pro-Max",
  "osVersion": "iOS-26-2",
  "deviceLocale": "en_US",
  "appId": "app_01kgfx3k6gfx4t84qyr8f3q9nj",
  "startTime": 1770114514724,
  "endTime": 1770114503499,
  "flows": [
    {
      "id": "run_01kghgqmtbeb6afhnchgxcck48",
      "name": "android-advanced-flow",
      "url": "https://app.maestro.dev/project/proj_01kdze2nbdfactc52yg9jqdb0n/maestro-test/flow/run_01kghgqmtbeb6afhnchgxcck48",
      "status": "SUCCESS",
      "failureReason": null,
      "startTime": 1770114514724,
      "endTime": 1770114569337,
      "tags": [
        "release",
        "critical-path"
      ],
      "properties": {
        "jira_ticket": "ENG-402",
        "deployment_env": "staging"
      },
      "videoUrl": "https://storage.googleapis.com/.../screen-recording.mp4?X-Goog-Signature=..."
    }
  ]
}
```

Each flow includes a `videoUrl` field: a signed link to the flow's screen recording (`screen-recording.mp4`), valid for 7 days. It is available for all platforms (Android, iOS, and web). The value is `null` when the flow has no recording — for example, if the recording failed.

### Related content

Check the other notification options available when testing your app with Maestro Cloud:

* [Set Slack notification](/maestro-cloud/notifications/set-slack-notification.md)
* [Set email notification](/maestro-cloud/notifications/set-email-notification.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/notifications/configure-webhooks.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
