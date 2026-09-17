> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/takescreenshot.md).

# takeScreenshot

The `takeScreenshot` command saves a screenshot of the current screen as a PNG file.

### Parameters

The `takeScreenshot` command accepts the `path` parameter:

| Parameter | Description                                                                                                                                                                                                                                                                                           |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `path`    | The filename for the screenshot, without the extension. May include subdirectories. See [Artifact paths](#artifact-paths) for info about where it's saved.                                                                                                                                            |
| `cropOn`  | Optional. A selector to narrow the screenshot to just an element or container that you care about. Often used with [assertScreenshot](/reference/commands-available/assertscreenshot.md). For a complete list of all available selectors, see the [Selectors](/reference/selectors.md) documentation. |
| `label`   | Optional. A message to display when executing the evaluation.                                                                                                                                                                                                                                         |

### Usage examples

The following example saves a screenshot as `LoginScreen.png`.

```yaml
- takeScreenshot:
    path: LoginScreen
```

This next example is the same login screen, but crops to the area containing the login controls

```yaml
- takeScreenshot:
    path: LoginScreen
    cropOn:
      id: LoginFormContainer
    label: Take a screenshot of the login form
```

You can also use a shorthand syntax. The following example saves a screenshot as `MainScreen.png`.

```yaml
- takeScreenshot: MainScreen
```

You can also group screenshots into subdirectories of the artifact folder.

```yaml
- takeScreenshot:
    path: checkout/PaymentScreen
```

### Artifact paths

Maestro writes this command's output into the `takeScreenshot` folder of the Flow's artifact bundle. See [Layout of a Flow's artifact folder](/maestro-flows/workspace-management/test-reports-and-artifacts.md#layout-of-a-flows-artifact-folder).

The `path` must name a file, and must not attempt to escape the artifacts folder. Maestro rejects the command with an `Invalid path` error (and will fail the flow) if the value:

* names a directory rather than a file
* climbs out of the command's output folder using `..`, such as `../escape`
* is an empty string, which happens when a variable in the path resolves to `""`

An absolute path is allowed as long as it still points at the correct directory. This might be used, for example, via `maestro test --test-output-dir=/tmp/maestro123 --env OUTPUTDIR=/tmp/maestro123 ...` to compute paths that work for the environment at runtime.

A variable that was never defined does **not** fail the command. It resolves to `undefined`, and the screenshot is silently written to `undefined.png`.

If the file cannot be written (e.g. full disk or read-only destination), the Flow fails with `Cannot write startRecording output to ...`.

{% hint style="info" %}
**Maestro CLI**

If you are using the [Maestro CLI](https://docs.maestro.dev/maestro-cli/), you can override the default output location with the `--test-output-dir` flag when running `maestro test` or with `testOutputDir` in your workspace config. See [Test reports and artifacts](/maestro-flows/workspace-management/test-reports-and-artifacts.md) for details.
{% endhint %}

### Related content

Check the [Test reports and artifacts](/maestro-flows/workspace-management/test-reports-and-artifacts.md) to learn how to configure the output directory.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/takescreenshot.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
