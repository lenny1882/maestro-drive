> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/workspace-management/workspace-management-overview.md).

# Workspace management overview

Moving from your first test to a full-scale automation suite requires shifting your focus from "how to write a command" to "how to design a system". A well-architected Maestro workspace ensures your tests stay fast, reliable, and easy to maintain as your application evolves.

### The anatomy of a workspace

When organizing your workspace, consider the following four pillars:

{% stepper %}
{% step %}

#### **Configuration**

A Maestro workspace is centered around the [`config.yaml`](/reference/workspace-configuration.md) file, which settings that apply to your entire test suite or workspace directory. Access the [Project configuration](/maestro-flows/workspace-management/project-configuration.md) guide to learn how to create and manage configuration files for your suite.&#x20;
{% endstep %}

{% step %}

#### **Architecture**

Before writing dozens of tests, you must choose a repository structure that matches your app's business logic. Whether you choose a **User Journey** or **Feature Test** model, learning how to [organize your test architecture](/maestro-flows/workspace-management/design-your-test-architecture.md) ensures your tests remain scalable and maintainable.
{% endstep %}

{% step %}

#### **Advanced execution**

As your suite grows, you need control over how tests are discovered and executed:

* [Tags](/maestro-flows/workspace-management/test-discovery-and-tags.md): Categorize Flows (e.g., `smoke`, `production_ready`) to run specific subsets of tests.
* [Sequential order](/maestro-flows/workspace-management/sequential-execution.md): While Maestro favors isolated, non-deterministic execution, you can force a strict sequence when validating complex multi-step events.
  {% endstep %}

{% step %}

#### **Analysis**

Maestro doesn't just tell you if a test passed, it provides the why:

* [Reports and artifacts](/maestro-flows/workspace-management/test-reports-and-artifacts.md): Generate JUnit (XML) for CI/CD pipelines or human-readable HTML reports with failure screenshots.
* [Record your Flow](/maestro-flows/workspace-management/record-your-flow.md): Record Maestro tests as MP4 videos for debugging and sharing.
* [AI insights](/maestro-flows/workspace-management/ai-test-analysis.md): Use the `--analyze` flag to automatically detect spelling errors, layout breaks, and internationalization issues that traditional assertions might miss.
  {% endstep %}
  {% endstepper %}

{% hint style="success" %}

#### Best practice

Each Flow should be able to run on a completely reset device, even if you are using sequential execution.
{% endhint %}

### Next steps

If you are setting up a new repository, Maestro recommends following this path:

1. Configure your  `config.yaml` using the instructions in [Project configuration](/maestro-flows/workspace-management/project-configuration.md).
2. Define your folder structure based on the strategies in [Design your test architecture](/maestro-flows/workspace-management/design-your-test-architecture.md).
3. Tag your critical tests to organize and filter execution as described in [Test discovery and tags](/maestro-flows/workspace-management/test-discovery-and-tags.md).


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/workspace-management/workspace-management-overview.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
