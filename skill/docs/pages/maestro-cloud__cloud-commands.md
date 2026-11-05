> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/cloud-commands.md).

# Cloud commands

Upload and execute your mobile tests on hosted cloud infrastructure using the Maestro CLI cloud subcommand.

Maestro does not provide a separate "Cloud CLI." To take advantage of Maestro Cloud features, you use the `cloud` subcommand within the standard [Maestro CLI](https://docs.maestro.dev/maestro-cli/). This subcommand uploads your app and tests to our cloud infrastructure and enables hosted test execution

#### Maestro CLI Reference

Because the `cloud` command is part of the core Maestro CLI, all available flags, options, and global settings are documented in a centralized reference.

To explore the full list of parameters you can use to customize your cloud runs, visit the [Maestro CLI commands and options](/maestro-cli/maestro-cli-commands-and-options.md) reference page.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/cloud-commands.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
