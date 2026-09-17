> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/ci-cd-integration.md).

# CI/CD integration

- [GitHub Actions](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/github-actions.md): Official GitHub Action for Maestro Cloud. Run mobile tests on push or PR, pass env variables, and access outputs like console URL.
- [Platform guides](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/github-actions/platform-guides.md): Set up Maestro Cloud GitHub Actions for Android, iOS, and Flutter.
- [Advanced configuration](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/github-actions/advanced-configuration.md): Customize Maestro Cloud runs with advanced settings for custom workspaces, upload naming, async mode, environment variables, and tag filtering.
- [Outputs and triggers](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/github-actions/outputs-and-triggers.md): Configure GitHub Action triggers and use output variables to integrate Maestro Cloud into your CI/CD pipeline.
- [Bitrise](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/bitrise.md): Native Bitrise integration for Maestro Cloud. Set API Key, Project ID, and app binary path to trigger tests automatically.
- [Bitbucket Pipelines](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/bitbucket-pipelines.md): Native Bitbucket Pipe for Maestro Cloud. Set API key and Project ID to upload app binary and run Flows on cloud infrastructure.
- [CircleCI](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/circleci.md): Integrate Maestro Cloud into CircleCI pipelines to automate mobile testing. Set up API keys, organize flows, and configure your .circleci/config.yml.
- [Generic CI platform](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/generic-ci-platform.md): Integrate Maestro Cloud with any CI/CD provider using the CLI. Works with Jenkins, GitLab CI, Azure DevOps, and more.
- [Pull request integration](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/pull-request-integration.md): Native pull request integration runs Maestro tests asynchronously and blocks merges on failures. Supports GitHub Enterprise.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/ci-cd-integration.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
