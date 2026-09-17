> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/cloud-commands.md).

# Cloud commands

Maestro does not provide a separate "Cloud CLI." To take advantage of Maestro Cloud features, you use the `cloud` subcommand within the standard [Maestro CLI](https://docs.maestro.dev/maestro-cli/). This subcommand uploads your app and tests to our cloud infrastructure and enables hosted test execution

#### Maestro CLI Reference

Because the `cloud` command is part of the core Maestro CLI, all available flags, options, and global settings are documented in a centralized reference.

To explore the full list of parameters you can use to customize your cloud runs, visit the [Maestro CLI commands and options](/maestro-cli/maestro-cli-commands-and-options.md) reference page.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/cloud-commands.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
