> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/notifications/set-slack-notification.md).

# Set Slack notification

Connect Slack to Maestro Cloud for test result notifications after each upload. Option to notify on failed flows only.

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

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2Fg9LYWUyoTyowSpPQtbFm%2Fconnect-slack.png?alt=media&amp;token=dc9beedf-37f4-4d44-bc44-b3517303f070" alt=""><figcaption></figcaption></figure>

5. You are redirected to Slack. Select the workspace and channel where you want to receive notifications, then click **Allow**.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2Fz2CkkJn4do40wOV6WVSQ%2Fallow-access-to-slack.png?alt=media&amp;token=65fad435-e431-4bb7-8f88-febcd660fe7d" alt=""><figcaption></figcaption></figure>

6. After authorization, you are redirected back to the Maestro Console. The integration is now enabled, and you will start receiving Slack notifications.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2FxlyeJwabPsrq1q8XiywW%2Fimage.png?alt=media&amp;token=dfca1df0-2f51-43a7-8498-8ff09a99973c" alt=""><figcaption></figcaption></figure>

### Receive notifications

Once the integration is active, Maestro posts a message to your selected Slack channel after each upload finishes, regardless of whether the test succeeds or fails.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2FvNZwBs6WLLyZlNdgyuBD%2Fimage.png?alt=media&amp;token=3565ad38-707c-48c0-85da-4121eb5cd8d7" alt=""><figcaption></figcaption></figure>

You have the option to configure Maestro to share updates only from failed tests. To enable this configuration:

1. Log in to the [Maestro Dashboard](https://app.maestro.dev/).
2. Click **Settings** in the sidebar.
3. Select the project you want to configure.
4. Enable **Send notifications for failed flows only**.

<figure><img src="https://1537828429-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2Fky7LkNoLfvcORtXOzzBs%2Fuploads%2FKqx2LA9NL3JrmfNhscD6%2Fslack-failed-tests-only.png?alt=media&amp;token=5bfd7aee-173d-4033-aa7e-fe509e11632c" alt=""><figcaption></figcaption></figure>

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
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/notifications/set-slack-notification.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
