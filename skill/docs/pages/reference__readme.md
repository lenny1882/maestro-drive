> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/readme.md).

# Commands overview

API Reference covering Maestro commands, selectors for UI elements, and workspace configuration for global settings.

The API Reference provides detailed documentation on the core components of Maestro, including commands, selectors, and workspace configuration.

### Explore API capabilities

<table data-view="cards"><thead><tr><th></th><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><i class="fa-code">:code:</i></td><td><strong>Commands</strong></td><td>Explore the full list of available commands to interact with your application, from simple taps to complex logic.</td><td><a href="/reference/commands-available.md">Commands available</a></td></tr><tr><td><i class="fa-crosshairs">:crosshairs:</i></td><td><strong>Selectors</strong></td><td>Learn how to identify and target UI elements effectively using different selector strategies.</td><td><a href="/reference/selectors.md">Selectors</a></td></tr><tr><td><i class="fa-gears">:gears:</i></td><td><strong>Workspace Configuration</strong></td><td>Configure global settings for your Maestro workspace to customize behavior across all flows.</td><td><a href="/reference/workspace-configuration.md">Workspace configuration</a></td></tr></tbody></table>


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/readme.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
