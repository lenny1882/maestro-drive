> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/extra-materials/readme.md).

# Resources overview

Additional resources: community projects, articles, and troubleshooting guides.

The Resources section contains troubleshooting guides, community links, and reference materials for Maestro. Use it when you need to debug issues, report bugs, or find articles, projects, and case studies from the community.

### Troubleshooting

<table data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>Known issues</strong></td><td>Known limitations and workarounds when debugging Maestro tests, grouped by cross-platform, Android, and iOS.</td><td><a href="/extra-materials/troubleshooting/known-issues.md">Known issues</a></td></tr><tr><td><strong>FAQ</strong></td><td>Common questions: parameters, assertions, YAML gotchas, cloud behavior, and how to organize your tests.</td><td><a href="/extra-materials/troubleshooting/faq.md">FAQ</a></td></tr><tr><td><strong>Bug report</strong></td><td>How to report a bug in Maestro and attach context</td><td><a href="/extra-materials/troubleshooting/bug-report.md">Bug report</a></td></tr></tbody></table>

### Community

<table data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>Community projects</strong></td><td>Maestro repository, Slack, awesome list, and community-built projects and integrations.</td><td><a href="/extra-materials/community/community-projects.md">Community projects</a></td></tr><tr><td><strong>Articles</strong></td><td>Articles, blog posts, and tutorials about Maestro from the community and the Maestro team.</td><td><a href="/extra-materials/community/articles.md">Articles</a></td></tr><tr><td><strong>Showcase</strong></td><td>Case studies and examples of teams and apps using Maestro.</td><td><a href="/extra-materials/community/showcase.md">Showcase</a></td></tr></tbody></table>


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/extra-materials/readme.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
