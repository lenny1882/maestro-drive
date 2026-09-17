> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/readme.md).

# Commands overview

The API Reference provides detailed documentation on the core components of Maestro, including commands, selectors, and workspace configuration.

### Explore API capabilities

<table data-view="cards"><thead><tr><th></th><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><i class="fa-code">:code:</i></td><td><strong>Commands</strong></td><td>Explore the full list of available commands to interact with your application, from simple taps to complex logic.</td><td><a href="/pages/EhKJmG3upspLn0J3rvEd">/pages/EhKJmG3upspLn0J3rvEd</a></td></tr><tr><td><i class="fa-crosshairs">:crosshairs:</i></td><td><strong>Selectors</strong></td><td>Learn how to identify and target UI elements effectively using different selector strategies.</td><td><a href="/pages/5WlrDHblGj9kwJw5bTLR">/pages/5WlrDHblGj9kwJw5bTLR</a></td></tr><tr><td><i class="fa-gears">:gears:</i></td><td><strong>Workspace Configuration</strong></td><td>Configure global settings for your Maestro workspace to customize behavior across all flows.</td><td><a href="/pages/WDWCAl6raG6I9MiguTCg">/pages/WDWCAl6raG6I9MiguTCg</a></td></tr></tbody></table>


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/readme.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
