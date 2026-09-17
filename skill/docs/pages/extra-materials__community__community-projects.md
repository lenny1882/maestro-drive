> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/extra-materials/community/community-projects.md).

# Community projects

The Maestro ecosystem is built on a foundation of collaboration. Beyond the core CLI, our community has developed a wide range of extensions, integrations, and resources to help you scale your mobile automation.

### Join the community

Connect with the team and other developers to ask questions, share your projects, and contribute to the source code.

<table data-view="cards"><thead><tr><th></th><th></th><th></th><th data-hidden data-card-cover data-type="image">Cover image</th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><i class="fa-github">:github:</i></td><td><strong>GitHub</strong></td><td>Maestro source code, issue tracking, and technical contributions.</td><td></td><td><a href="https://github.com/mobile-dev-inc/maestro">https://github.com/mobile-dev-inc/maestro</a></td></tr><tr><td><i class="fa-slack">:slack:</i></td><td><strong>Slack</strong></td><td>Join the <code>#maestro-questions</code> channel for  support.</td><td></td><td><a href="https://slack.maestro.dev/">https://slack.maestro.dev/</a></td></tr><tr><td><i class="fa-web-awesome">:web-awesome:</i></td><td><strong>Awesome list</strong></td><td>A curated list of community resources, tutorials, and scripts.</td><td></td><td><a href="https://github.com/ludovicobesana/awesome-maestro">https://github.com/ludovicobesana/awesome-maestro</a></td></tr></tbody></table>

### Extensions and integrations

Supercharge your local development and CI/CD pipelines with these community-built tools.

#### **IDE support**

* [VSCode Maestro Workbench](https://github.com/Mastersam07/maestro-workbench/): Full-featured extension providing IntelliSense, syntax highlighting, and visual test execution.
* [VSCode Maestro Assistant](https://github.com/agens-no/vscode-maestro-assistant): Streamline your workflow with shortcuts for creating and running flows.

#### **Frameworks and samples**

* [React Native Maestro Sample](https://github.com/kiki-le-singe/react-native-maestro): A reference project demonstrating how to test React Native apps built with Expo.
* [Expo E2E Guide](https://docs.expo.dev/build-reference/e2e-tests/): Official Expo documentation for testing React Native apps using EAS and Maestro.

#### **DevOps and CI/CD**

* [Codemagic Integration](https://docs.codemagic.io/integrations/maestro-integration/): Documentation for running Maestro tests within Codemagic pipelines.
* [Fastlane Plugin](https://github.com/inf2381/fastlane-plugin-maestro): Automate flow execution directly from your Fastlane lanes.
* [Slack Test Results](https://github.com/brett-james-rocketlab/maestro-test-results-to-slack): Automatically parse results and post status updates to your Slack channels.

### Explore more

Check out additional materials created by the community.

* [Articles](/extra-materials/community/articles.md): Deep dives and blog posts from mobile engineers.
* [Showcase](/extra-materials/community/showcase.md): See how leading teams are using Maestro in production.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/extra-materials/community/community-projects.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
