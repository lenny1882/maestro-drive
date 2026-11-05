> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/advanced-features.md).

# Advanced features

- [Manage secrets](https://docs.maestro.dev/maestro-cloud/advanced-features/manage-secrets.md): Pass sensitive parameters like usernames and passwords to Maestro Cloud tests via environment variables using the -e CLI option.
- [Reuse app binary](https://docs.maestro.dev/maestro-cloud/advanced-features/reuse-app-binary.md): Use --app-binary-id to skip re-uploading your app and save time. Find the binary ID in CLI output or Maestro dashboard.
- [IP allowlist](https://docs.maestro.dev/maestro-cloud/advanced-features/ip-allowlist.md): Static IP addresses used by Maestro Cloud to connect to your services. Add to your firewall or ACLs for access.
- [Automatic Retries](https://docs.maestro.dev/maestro-cloud/advanced-features/automatic-retries.md): There are situations where Maestro Cloud will automatically retry a test execution
- [Stop previous flows](https://docs.maestro.dev/maestro-cloud/advanced-features/stop-previous-flows.md): Automatically stop in-progress flows when a newer upload arrives for the same app and branch, so CI doesn't spend device time on superseded commits.
- [Queue priority](https://docs.maestro.dev/maestro-cloud/advanced-features/queue-priority.md): Set an upload's queue priority so its flows start before other flows your organization has waiting in the queue.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/advanced-features.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
