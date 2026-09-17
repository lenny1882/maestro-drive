> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/runflow.md).

# runFlow

The `runFlow` command executes a sequence of commands from another Flow file or from an inline definition. This command helps you modularize tests and reuse common sequences, such as a login process. Inline subflows (using the `commands` parameter) are especially useful for [conditional](https://app.gitbook.com/s/mS3lsb9jRwfRHqddeRXG/flow-control-and-logic/conditions) logic or for grouping a few steps under a clear `label`.

### Parameters

The `runFlow` command accepts the following parameters.

| Parameter  | Type   | Description                                                                                                |
| ---------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| `file`     | string | The relative path to the Flow file to execute.                                                             |
| `label`    | string | A short description of what the subflow does. Shown in reports and helps with readability and maintenance. |
| `env`      | map    | A map of key-value pairs to pass as environment variables to the subflow.                                  |
| `commands` | list   | A list of commands to execute inline. Use this instead of the `file` parameter for self-contained Flows.   |

### Usage examples

The following examples demonstrate how to use the `runFlow` command.

#### Run a separate Flow file

To reuse a common sequence of steps, define them in a separate file and call them with `runFlow`. For example, you can define a login sequence once and reuse it in multiple tests. The following **Login** Flow is defined in one file and reused in the other two Flows (**Profile** and **Settings**).

{% tabs %}
{% tab title="Login.yaml" %}

```yaml
appId: com.example.app
---
- launchApp
- tapOn: Username
- inputText: Test User
- tapOn: Password
- inputText: Test Password
- tapOn: Login
```

{% endtab %}

{% tab title="Profile.yaml" %}

```yaml
appId: com.example.app
---
- runFlow: Login.yaml # <-- Run commands from "Login.yaml"
- tapOn: Profile
- assertVisible: "Name: Test User"
```

{% endtab %}

{% tab title="Settings.yaml" %}

```yaml
appId: com.example.app
---
- runFlow: Login.yaml # <-- Run commands from "Login.yaml"
- tapOn: Settings
- assertVisible: "Switch to dark mode"
```

{% endtab %}
{% endtabs %}

{% hint style="success" %}
Flow files are a great way to abstract steps or create a reusable component. Be mindful during test Flow files help you reuse and abstract steps. Keep tests easy to follow so they stay maintainable.
{% endhint %}

#### Pass environment variables to a subflow

You can pass variables to the subflow using the `env` parameter. These variables are accessible within the subflow.

```yaml
- runFlow: 
    file: anotherFlow.yaml
    env:
      MY_PARAMETER: "123"
```

#### When to use inline subflows

Inline subflows fit [conditional](/maestro-flows/flow-control-and-logic/conditions.md) logic or small groups of steps that don't need a separate file. Use a `label` so the step has a clear intent; otherwise, listing the commands directly is simpler.

#### Run an inline Flow

To define a subflow in place, use the `commands` parameter instead of `file`. A `label` gives the step a clear name so you can see at a glance what it does. For example:

```yaml
- runFlow:
    label: Sort alphabetically
    commands:
      - tapOn:
          id: sort_icon
      - tapOn: algorithm
      - tapOn: A-Z
      - tapOn: Apply
```

You can also pass environment variables into an inline subflow:

```yaml
- runFlow:
    env:
      INNER_ENV: Inner Parameter
    commands:
      - inputText: ${INNER_ENV}
```

### Cloud execution

Pass a **workspace folder** (not a single Flow file) so Maestro can upload dependent flows and a root `config.yaml` if present. Passing only a file relies on best-effort dependency collection and can result in `Failed to parse file`. Use named parameters. For example, if your flows and app are under `myTestsFolder`:

```bash
maestro cloud --app-file myApp.apk --flows ./myTestsFolder
```

### Related content

Learn how to define parameters and set environment variables in Maestro Flows by accessing the [Parameters and constants](/maestro-flows/flow-control-and-logic/parameters-and-constants.md) and [Broken mention](broken://spaces/mS3lsb9jRwfRHqddeRXG/pages/DLtBiFLCJpsE4uxGnPNx) pages.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/runflow.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
