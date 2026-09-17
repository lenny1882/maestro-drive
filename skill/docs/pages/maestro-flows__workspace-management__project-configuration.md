> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/workspace-management/project-configuration.md).

# Project configuration

The `config.yaml` file acts as the central "brain" of your Maestro workspace. While it is optional, it becomes essential when your project grows, allowing you to define global rules for your test suite, manage environment variables, and configure platform-specific behaviors.

{% hint style="info" %}
**Maestro Studio**

Unlike the Maestro CLI, Maestro Studio does not currently support `config.yaml`. However, Studio will include your configuration file in uploads to Maestro Cloud when you run an entire workspace.
{% endhint %}

### When do I need a config file?

If you are just running a single Flow file locally, you don't need a configuration. You should create a `config.yaml` if:

* You have a deep directory structure and need to define test discovery.
* You need to handle environment variables across multiple Flows.
* You want to configure cloud-specific behaviors like disabling system animations.

### Setting up your configuration

{% hint style="info" %}

#### Default behavior and hierarchy

When you point Maestro at a directory, it looks for a file named `config.yaml` in the root of that directory. If no `--config` flag is provided and the file is missing, Maestro runs with default settings.
{% endhint %}

{% stepper %}
{% step %}

#### Create the configuration file

You can place your configuration file anywhere in your repository, but for simplicity, it should be at the root of the Maestro workspace (commonly within a `.maestro/` folder).

{% hint style="info" %}
Ensure the file is named exactly `config.yaml`.
{% endhint %}
{% endstep %}

{% step %}

#### Configure where flows are stored

Use the `flows` block to define where in your repository the test flows are stored. Typically this will be a single line, but the config permits for a list of locations. Simple globbing syntax is permitted here, where `*` means the contents of a folder, but `**` includes all subfolders too.

```yaml
# config.yaml
flows:
  - e2e/*
  - smoke/**
```

{% endstep %}

{% step %}

#### Configure the platform behavior

To ensure your tests are stable and flake-free, you can configure platform-specific behaviors.

```yaml
# config.yaml
platform:
  ios:
    snapshotKeyHonorModalViews: false # iOS: Includes background elements in the hierarchy
```

{% hint style="info" %}

#### **Cloud-only flags**

Some flags, like `disableAnimations`, are a cloud-only feature and does not affect local emulators or simulators.
{% endhint %}
{% endstep %}
{% endstepper %}

{% hint style="info" %}
&#x20;If you need a list of all configurations available to configure your test suite, access the [Workspace configuration](/reference/workspace-configuration.md) reference.
{% endhint %}

### Working with multiple configs

While `config.yaml` is the default, you can create multiple configuration files for different scenarios (e.g., `smoke-config.yaml` or `ci-config.yaml`). To run a test suite with a specific configuration, use the `--config` flag when running the tests with the Maestro CLI:

```bash
maestro test --config .maestro/ci-config.yaml tests/
```

### Next steps

If you need a full list of every available key and configuration available, access the  [Workspace configuration](/reference/workspace-configuration.md) reference page.

To plan your test architecture access [Design your test architecture](/maestro-flows/workspace-management/design-your-test-architecture.md). On the other hand, if you need to organize your tests, learn how to use the `flows` key in your config to manage [Test discovery and tags](/maestro-flows/workspace-management/test-discovery-and-tags.md).


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/workspace-management/project-configuration.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
