> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/notifications/set-email-notification.md).

# Set email notification

Configure Maestro Cloud to send email summaries for your Flow results.

{% hint style="info" %}
**Maestro Cloud Plan required** Email notifications are available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Configure email recipients

To receive email notifications, add the `notifications` mapping to your `config.yaml` file. This file should be located in the root of your workspace (usually the `.maestro` folder).

#### Notify on failure (Default)

By default, Maestro Cloud sends emails only when a Flow fails. Add the following to your `config.yaml`:

```yaml
# .maestro/config.yaml
notifications:
  email:
    enabled: true
    recipients:
      - dev-team@example.com
      - qa-lead@example.com
```

#### Notify on success and failure

If you want to receive notifications for successful runs as well, add `onSuccess: true`:

```yaml
# .maestro/config.yaml
notifications:
  email:
    enabled: true
    onSuccess: true # Enable on sucess notification
    recipients:
      - dev-team@example.com
```

### Example email notification

When a Flow fails, recipients receive an email containing a summary of the test run and a link to the detailed report in the Maestro Dashboard.

<figure><img src="/files/McLI3irOQbYfaLF0CFEn" alt=""><figcaption></figcaption></figure>

### Related content

Check the other notification options available when testing your app with Maestro Cloud:

* [Set Slack notification](/maestro-cloud/notifications/set-slack-notification.md)
* [Configure webhooks](/maestro-cloud/notifications/configure-webhooks.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/notifications/set-email-notification.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
