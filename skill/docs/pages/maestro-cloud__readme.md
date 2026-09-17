> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/readme.md).

# Maestro Cloud overview

Maestro Cloud is a hosted, enterprise-grade infrastructure designed to execute automated tests with high parallelism and reliable scaling. It allows teams to run their Flows in a stable, managed environment, eliminating the need to configure or maintain local emulators and simulators.

By offloading device management to the cloud, teams can reduce test execution time by up to 90% through asynchronous parallel runs, enabling faster shipping cycles with increased confidence.

{% hint style="info" %}
Maestro does not provide a separate "Cloud CLI." To take advantage of Maestro Cloud features, you use the `cloud` subcommand within the standard [Maestro CLI](https://docs.maestro.dev/maestro-cli/). This subcommand uploads your app and test flows to our cloud infrastructure and enables hosted test execution.
{% endhint %}

### Learn how to use Maestro Cloud

Follow these guides to set up your cloud testing environment:

1. [How to run your tests on Maestro Cloud](/maestro-cloud/run-tests-on-maestro-cloud.md): A step-by-step tutorial on prerequisites and your first cloud upload.
2. [CI Integration](/maestro-cloud/ci-cd-integration.md): Detailed guides for connecting to GitHub, Bitrise, Bitbucket, CircleCI, or any generic CI platform.
3. [Cloud Command Reference](/maestro-cloud/cloud-commands.md): A technical reference for all cloud-specific CLI arguments and parameters.

### Core capabilities

Maestro Cloud provides a purpose-built environment that ensures deterministic results by addressing the common causes of flakiness in mobile testing.

| Capability                 | Description                                                                                               |
| -------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Device Isolation**       | Every virtual device is wiped and recreated between tests to ensure complete isolation and repeatability. |
| **Flexible Configuration** | Customize exact environments, such as Android API levels or specific iOS models.                          |
| **Global Testing**         | Test localized app behavior using the `--device-locale` parameter and fixed regional timezones.           |
| **Cross-Platform**         | Native support for Android (Views/Compose), iOS (UIKit/SwiftUI), React Native, Flutter, and Web.          |

### CI/CD and workflow integration

You can integrate Maestro into your existing development lifecycle. Maestro Cloud offers native integrations with popular CI providers to automate your testing pipeline.

| Feature                      | Description                                                                                                           |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Native CI Support**        | Ready-made integrations for GitHub Actions, Bitrise, Bitbucket Pipelines, and CircleCI.                               |
| **Pull Request Integration** | Specifically for GitHub and GitHub Enterprise, Maestro can block merging if test failures are detected in a PR.       |
| **Performance Optimization** | Reuse cached app binaries via the `app-binary-id` to skip re-uploading the application for every individual test run. |

### Next step

Learn [How to run your tests on Maestro Cloud](/maestro-cloud/run-tests-on-maestro-cloud.md) using the tutorial to launch your first parallel test run.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/readme.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
