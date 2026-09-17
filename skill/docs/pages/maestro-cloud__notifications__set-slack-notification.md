> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/notifications/set-slack-notification.md).

# Set Slack notification

Configure Maestro Cloud to notify you and your team in Slack about test results for a specific project.

{% hint style="info" %}
**Maestro Cloud Plan required.** Slack notifications are available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Connect Slack to Maestro Cloud

Follow these steps to integrate Slack with your Maestro project:

1. Log in to the [Maestro Dashboard](https://app.maestro.dev/).
2. Click **Settings** in the sidebar.
3. Select the project for which you want to receive Slack notifications.
4. Click **Connect Slack**.

<figure><img src="/files/86aDfyMsO8ig8SrJ0PM5" alt=""><figcaption></figcaption></figure>

5. You are redirected to Slack. Select the workspace and channel where you want to receive notifications, then click **Allow**.

<figure><img src="/files/gY143GXsSWGvFmrpte6X" alt=""><figcaption></figcaption></figure>

6. After authorization, you are redirected back to the Maestro Console. The integration is now enabled, and you will start receiving Slack notifications.

<figure><img src="/files/K5lQ7QeehtjmS8BZNNHF" alt=""><figcaption></figcaption></figure>

### Receive notifications

Once the integration is active, Maestro posts a message to your selected Slack channel after each upload finishes, regardless of whether the test succeeds or fails.

<figure><img src="/files/qppk9gJ2193aDyIGlMUG" alt=""><figcaption></figcaption></figure>

You have the option to configure Maestro to share updates only from failed tests. To enable this configuration:

1. Log in to the [Maestro Dashboard](https://app.maestro.dev/).
2. Click **Settings** in the sidebar.
3. Select the project you want to configure.
4. Enable **Send notifications for failed flows only**.

<figure><img src="/files/LyGsIWeoFi9TeIAZCJRz" alt=""><figcaption></figcaption></figure>

{% hint style="info" %}
**Multi-project routing**

You can connect different projects to different Slack channels. This allows you to route notifications to the specific teams responsible for each project (e.g., `#android-alerts` for your Android project and `#ios-alerts` for your iOS project).
{% endhint %}

### Manage the integration

You can disable the integration or change the notification channel at any time from the **Settings** page in the Maestro Console.

### Related content

Check the other notification options available when testing your app with Maestro Cloud:

* [Set email notification](/maestro-cloud/notifications/set-email-notification.md)
* [Configure webhooks](/maestro-cloud/notifications/configure-webhooks.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/notifications/set-slack-notification.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
