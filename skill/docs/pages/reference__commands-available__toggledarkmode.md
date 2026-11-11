> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/toggledarkmode.md).

# toggleDarkMode

Toggle dark mode on or off during test execution.

Toggles the device's system-wide dark mode (light/dark appearance) state.

{% hint style="info" %}
On Android, this toggles the system night mode setting. On iOS, this controls the simulator's system appearance. On web, this forces the `prefers-color-scheme` media query, which affects any page using it to detect dark mode.
{% endhint %}

### Syntax

This command takes no arguments.

```yaml
- toggleDarkMode
```

### Related commands

* [setDarkMode](/reference/commands-available/setdarkmode.md)
* [assertDarkMode](/reference/commands-available/assertdarkmode.md)
* [assertLightMode](/reference/commands-available/assertlightmode.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/toggledarkmode.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
