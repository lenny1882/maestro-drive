> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/clearkeychain.md).

# clearKeychain

The `clearKeychain` command clears all data from the iOS Keychain.&#x20;

{% hint style="warning" %}
This command only applies to iOS and has no effect on Android or Web.
{% endhint %}

### Syntax

The command takes no arguments.

```yaml
- clearKeychain
```

### Why use this command?

The iOS Keychain is a secure storage container used by apps to persist login credentials, tokens, and other sensitive information.

In automated testing, the Keychain can become a source of state leakage, where a previous test run leaves a user logged in, causing subsequent tests to fail or behave unexpectedly. Using `clearKeychain` ensures your app starts from a clean, default state.

#### Automate Keychain clearing

If you want to clear the Keychain every time the app starts without adding a separate command, you can use the `clearKeychain` parameter directly within the [`launchApp`](/reference/commands-available/launchapp.md) command:

```yaml
- launchApp:
    clearKeychain: true
```

### Related content

You can use [Hooks](/maestro-flows/flow-control-and-logic/hooks.md) to automate Keychain clearing across all your tests.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/clearkeychain.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
