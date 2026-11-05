> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/advanced-features/ip-allowlist.md).

# IP allowlist

Static IP addresses used by Maestro Cloud to connect to your services. Add to your firewall or ACLs for access.

{% hint style="info" %}
**Maestro Cloud Plan required.** The IP allowlist feature is available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

If your network requires external services to be on an allowlist to permit access, update your Access Control Lists (ACLs) with the following IP addresses.

These IP addresses are used by Maestro Cloud to connect to your services:

* 207.254.42.234
* 34.127.79.8
* 35.247.62.137
* 34.83.16.33

{% hint style="info" %}
These IP addresses are static, but Maestro reserves the right to add more in the future. To be notified of future changes, contact Maestro support to join the mailing list.
{% endhint %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/advanced-features/ip-allowlist.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
