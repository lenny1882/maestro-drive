> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/clearstate.md).

# clearState

Clears all data for a specified mobile application.

### Usage examples

To clear the state of the current app, use add the `clearState` command alone.

```yaml
- clearState
```

If you want to clear the state of a specific app by its ID, add the app ID:

```yaml
- clearState: app.id
```

Or for a website, when testing on the web platform:

```yaml
- clearState: https://example.com
```

You can also add a `label` when invoking `clearState` to improve the readability of the report.

```yaml
- clearState:
    appId: app.id
    label: Reset ExampleApp
```

### Platform-specific behavior

The command's behavior differs based on the mobile operating system.

{% tabs %}
{% tab title="Android" %}
On Android, the `clearState` command is equivalent to running:

```
adb shell pm clear {package name}
```

It removes all app-related data from the device, such as shared preferences, databases, and accounts.
{% endtab %}

{% tab title="iOS" %}
On iOS, the `clearState` command causes Maestro to reinstall the entire app, resulting in a completely fresh install and removing all existing data folders.

As described in [Stack Overflow](https://stackoverflow.com/a/56746729/7009800) discussion, it's also possible to `xcrun simctl` to perform the same action.
{% endtab %}

{% tab title="Web" %}
The command clears all browser data (cookies, local storage, etc.) for the [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) of the current web app, or of the provided web app URL.
{% endtab %}
{% endtabs %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/clearstate.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
