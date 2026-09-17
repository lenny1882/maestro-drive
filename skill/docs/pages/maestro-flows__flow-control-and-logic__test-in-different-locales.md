> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/test-in-different-locales.md).

# Test in different locales

Testing how your app handles different languages and regional formats is critical for a global user base. In Maestro, the locale is a global device setting. Because changing the system language requires a device-level configuration change, it is handled via the CLI only at runtime.&#x20;

{% hint style="info" %}
To define the locale, provide the `--device-locale` flag at execution time using the [Maestro CLI](/maestro-cli/readme.md). For automated workflows, you can use CI wrappers to configure the locale for [Maestro Cloud](https://docs.maestro.dev/maestro-cloud/) runs.&#x20;

Note that there is no place within a Flow itself (such as `launchApp` or `config.yaml`) to define the locale.
{% endhint %}

{% hint style="info" %}

#### Web support

Maestro can change the locale for Android and iOS devices, but it does not control the internal language settings of the Chrome browser used for Web tests.
{% endhint %}

#### Set the locale

To run a Flow in a specific language, use the `--device-locale` flag when executing commands from the terminal. The value passed to `--device-locale` must be a combination of an [ISO-639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code and an [ISO-3166-1](https://en.wikipedia.org/wiki/ISO_3166-1) country code, separated by an underscore (`_`).

You can use `--device-locale` with the `maestro start-device` and `maestro cloud` commands. It is not possible to define the locale when running the `maestro test` command.

Refer to [Locales supported by Maestro](/maestro-flows/flow-control-and-logic/test-in-different-locales/locales-supported-by-maestro.md) for the full list of supported locales.

The following examples show how to start devices with specific locales.

{% tabs %}
{% tab title="Android" %}

```bash
# Create a new Android emulator with the locale set to France (French)
maestro start-device \
  --platform android \
  --device-locale fr_FR
```

{% endtab %}

{% tab title="iOS" %}

```bash
# Create a new iOS simulator with the locale set to Italy (Italian)
maestro start-device \
  --platform ios \
  --device-locale it_IT
```

{% endtab %}
{% endtabs %}

{% hint style="info" %}

#### What happens to the device?

When you start a device and define a locale, Maestro attempts to change the system language and region of the connected simulator or emulator before running any Flow.
{% endhint %}

After starting the device with the desired locale, you can run your tests normally. Maestro continues using the locale defined during device initialization.

```bash
maestro test your_flow.yaml
```

#### Combine locales and tags

If certain tests should only run in specific languages (for example, tests that validate French translations), a recommended approach is to combine `--device-locale` with [tags](/maestro-flows/workspace-management/test-discovery-and-tags.md). This ensures that only tests relevant to the selected locale are executed, making test runs faster and more efficient.

First, define a tag in the Flow. In the following example, the `french` tag indicates that the Flow is intended to validate the app using the French translation.

```yaml
# flows/login_fr.yaml
appId: com.example.app
tags:
  - french
---
- launchApp
- assertVisible: "Bienvenue"
```

After tagging your Flows, specify the tag when running tests using the `--include-tags` flag.

```bash
# Start the Android device using the French locale
maestro start-device --platform android --device-locale fr_FR
# Run only tests tagged as French
maestro test --include-tags french .maestro/
```

#### Related Documentation

* [Locales supported by Maestro](/maestro-flows/flow-control-and-logic/test-in-different-locales/locales-supported-by-maestro.md): Check the full list of supported locales.
* [Maestro CLI overview](/maestro-cli/readme.md): Learn how to execute flows using the CLI.
* [Test discovery and tags](/maestro-flows/workspace-management/test-discovery-and-tags.md): Learn how to group and filter your localization tests.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/test-in-different-locales.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
