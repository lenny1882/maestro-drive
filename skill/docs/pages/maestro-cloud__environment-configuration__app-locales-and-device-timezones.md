> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/environment-configuration/app-locales-and-device-timezones.md).

# App locales and device timezones

Maestro Cloud allows you to configure specific app locales and understand the default timezone settings for its cloud environments. This is essential for testing internationalization (i18n) and features that depend on localized data or time.

{% hint style="info" %}
**Maestro Cloud Plan required.**

Locale configuration features are available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Configure app locale

Use the `--device-locale` parameter with the `maestro cloud` command to automatically change the device locale for an upload.

The parameter value must follow the format `[`[`ISO-639-1`](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) `language code]_[`[`ISO-3166-1`](https://en.wikipedia.org/wiki/ISO_3166-1) `country code]`. Below you find two examples:

```bash
# Set device locale to German (Germany)
maestro cloud --device-locale de_DE --app-file <APP_FILE> --flows <WORKSPACE>

# Set device locale to Japanese (Japan)
maestro cloud --device-locale ja_JP --app-file <APP_FILE> --flows <WORKSPACE>
```

If the parameter is omitted, the default locale is `en_US`.

{% hint style="info" %}
**Locales supported by Maestro**

Check the [documentation](/maestro-flows/flow-control-and-logic/test-in-different-locales/locales-supported-by-maestro.md) to find the complete list of supported locales.
{% endhint %}

### Default device timezones

All Maestro Cloud instances are physically located in Las Vegas, USA. While the physical location is the same for all devices, the default timezones differ between platforms:

| Platform    | Default Timezone | Offset |
| ----------- | ---------------- | ------ |
| **Android** | UTC              | +00:00 |
| **iOS**     | Pacific Time     | GMT -7 |

It is important to note that these timezones are fixed and cannot currently be configured via CLI flags or configuration files. If your tests depend on specific time-of-day logic, ensure your assertions account for these offsets.

* **Android:** Regardless of the physical host region, the Android emulator defaults to UTC.
* **iOS:** iOS simulators inherit the system time of the host macOS instance, which is set to GMT -7.

### Related content

Now that you understand how locales and timezones work in the Maestro Cloud, explore other ways to customize your test environment:

* [Configure the OS](/maestro-cloud/environment-configuration/configure-the-os.md): Run your tests on specific Android API levels or iOS versions.
* Set up notifications via [Slack](/maestro-cloud/notifications/set-slack-notification.md), [email](/maestro-cloud/notifications/set-email-notification.md), or [webhooks](/maestro-cloud/notifications/configure-webhooks.md) to stay informed about build and test results.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/environment-configuration/app-locales-and-device-timezones.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
