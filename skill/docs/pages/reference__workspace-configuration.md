> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/workspace-configuration.md).

# Workspace configuration

This page provides a technical reference for all properties you can set in the `config.yaml` file. The configuration is structured into Global, Execution, Platform-specific, and Cloud sections.

### Global workspace settings

These settings define the identity of your application and how Maestro discovers your Flow files.

| Key                                                                                  | Description                                                                                                                                            |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`flows`](/maestro-flows/readme.md)                                                  | Glob patterns defining which files to include in a test suite. Defaults to `*` (only YAML files in the root folder). Use `**` for recursive discovery. |
| [`testOutputDir`](/maestro-flows/workspace-management/test-reports-and-artifacts.md) | Custom directory where screenshots, logs, and metadata are saved. Defaults to `~/.maestro/tests/`.                                                     |

#### Execution and filtering

Use these keys to control the order and selection of tests during a suite run.

| **Key**                                                                                           | **Description**                                                                                    |
| ------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [`includeTags`](/maestro-flows/workspace-management/test-discovery-and-tags.md)                   | Only executes Flows that contain at least one of these tags in their internal configuration.       |
| [`excludeTags`](/maestro-flows/workspace-management/test-discovery-and-tags.md)                   | Skips any Flows that contain one or more of these tags.                                            |
| [`executionOrder`](/maestro-flows/workspace-management/sequential-execution.md)                   | A nested object used to force a specific sequence of Flows.                                        |
| [`executionOrder.continueOnFailure`](/maestro-flows/workspace-management/sequential-execution.md) | If `false`, Maestro stops the sequential execution immediately if a Flow fails. Default is `true`. |
| [`executionOrder.flowsOrder`](/maestro-flows/workspace-management/sequential-execution.md)        | The ordered list of Flow names or filenames (without `.yaml`) to execute sequentially.             |

#### Platform configuration

Platform-specific settings allow you to optimize the environment for Android or iOS.

| **Key (iOS specifics)**      | **Description**                                                                                                                                                                                                                                                                                                           |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `disableAnimations`          | **(Cloud only)** Enables Reduce Motion on the iOS Simulator to prevent flakiness caused by system-level animations.                                                                                                                                                                                                       |
| `snapshotKeyHonorModalViews` | <p>You can use this key when running tests locally or on the cloud.</p><p></p><p>If <code>false</code>, Maestro includes elements from the background hierarchy even when a modal is present. Useful for certain custom UI frameworks. This helps capture elements that have absolute positioning into the hierarchy.</p> |

| **Key (Android specifics)** | **Description**                                                                                             |
| --------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `disableAnimations`         | **(Cloud only)** Disables system-level window, transition, and animator animations on the Android Emulator. |

#### Maestro cloud configuration

These properties are used only when running tests on [Maestro Cloud](/maestro-cloud/readme.md).

| **Key**                          | **Description**                                                       |
| -------------------------------- | --------------------------------------------------------------------- |
| `baselineBranch`                 | Defines the source-of-truth branch (e.g., `main`) for PR comparisons. |
| `notifications`                  | Configures automated alerts upon test completion.                     |
| `notifications.email.enabled`    | Set to `true` to enable email notifications.                          |
| `notifications.email.recipients` | A list of email addresses to receive the test reports.                |
| `notifications.slack.endpoint`   | The Webhook URL for posting results directly to a Slack channel.      |

### Usage example

The following example shows a typical Maestro workspace configuration file. This file must be named `config.yaml`. You can place it at the root of your project or in the `.maestro` directory:

```yaml
# config.yaml
flows:
  - 'subFolder/*'
  - 'anotherSubfolder/**'
includeTags:
  - tagNameToInclude
excludeTags:
  - tagNameToExclude
executionOrder:
  continueOnFailure: false # default is true
  flowsOrder:
    - flowA
    - flowB

# Customised test output directory
testOutputDir: test_output_directory

# Cloud only config options
baselineBranch: main
notifications:
  email:
    enabled: true
    recipients:
      - john@example.com

# Platform Configuration
platform:
  ios:
    snapshotKeyHonorModalViews: false
    disableAnimations: true
  android:
    disableAnimations: true
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/workspace-configuration.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
