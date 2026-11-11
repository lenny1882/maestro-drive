> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/workspace-management/design-your-test-architecture.md).

# Design your test architecture

Plan your test architecture with guides on repository configuration and test suite structure.

Moving from your first test to a full-scale automation suite requires shifting your focus from "how to write a command" to "how to design a system." A well-architected Maestro suite ensures that your tests stay fast, reliable, and easy to maintain as your application evolves.

To build this system, you need to address two distinct layers:&#x20;

* Where your tests live&#x20;
* How they are structured

To help you navigate these layers, you can explore the best practices into the following specialized guides:

1. [Repository configuration](/maestro-flows/workspace-management/design-your-test-architecture/repository-configuration.md): Learn where to store test files or choosing a high-level organization model (User Journeys vs. Features). It will help you decide on your folder structure and repo strategy, preventing refactoring later.
2. [Structuring your test suite](https://maestro.dev/blog/maestro-best-practices-structuring-your-test-suite): Check this guide if you are ready to write YAML files and want to know the rules for naming, sub-folders, and using tags to filter execution. Learn the "Maestro Way" of writing modular, tagged, and parallel-ready tests.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-flows/workspace-management/design-your-test-architecture.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
