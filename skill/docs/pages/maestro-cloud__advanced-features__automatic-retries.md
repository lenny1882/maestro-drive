> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/advanced-features/automatic-retries.md).

# Automatic Retries

There are situations where Maestro Cloud will automatically retry a test execution

### Smart Retries

We automatically retry tests that we consider might be a flaky test - perhaps there was a network hiccup, a timing issue in your test, or something happened on your test environment's backend.

We automatically retry a failed run when we detect that:

1. the previous run of the same flow (as determined by the `name`, or the filename if there isn't one) succeeded (irregardless of branch source
2. it used the exact same target device (os/model)

### Infrastructure-triggered retries

Operating systems are complex, and our device hosts have a virtual device operating system running on top. We're regularly improving device behaviours, but sometimes hiccups occur on a machine or on a network. When this happens and we detect that it was probably infrastructural, we automatically retry your test on a different machine.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/advanced-features/automatic-retries.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
