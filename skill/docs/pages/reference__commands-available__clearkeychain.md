> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/clearkeychain.md).

# clearKeychain

Clear iOS keychain data for the app under test.

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
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/clearkeychain.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
