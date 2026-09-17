> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-studio/maestro-studio-overview.md).

# Maestro Studio overview

With Maestro Studio you can connect a device, build your tests by interacting directly with your app, and run them without switching tools.

### Learn how to use Maestro Studio

To start using Maestro Studio, Explore the following path:

1. Visit [Run tests with Maestro Studio](/maestro-studio/run-tests-with-maestro-studio.md) to install the Studio and create and run your first test.
2. Explore [Environments and variables](/maestro-studio/environments-and-variables.md) to learn how to handle dynamic data and secrets directly within the visual editor.
3. Use the [Run cloud tests from Maestro Studio](/maestro-studio/run-cloud-tests-from-maestro-studio.md) to run your tests on Maestro Cloud directly from Studio.

### What you can do in Studio

<table data-view="cards"><thead><tr><th></th><th></th></tr></thead><tbody><tr><td><strong>Write tests faster</strong></td><td>Type a hyphen in the YAML editor to see all available Maestro commands. Autocomplete suggests commands, arguments, and real selectors pulled from your connected device's screen, so you spend less time in the docs and fewer errors make it to run time.</td></tr><tr><td><strong>Visual test creation</strong></td><td>Right-click any element on your connected device to add YAML commands directly to your test. No need to manually look up element IDs or selectors. </td></tr><tr><td><strong>Run and debug locally</strong></td><td>Run your tests step by step and see exactly what happens on screen at each stage. Every run is recorded, so you can jump to any point and inspect what went wrong.</td></tr></tbody></table>

### Maestro Studio vs. Maestro CLI

Maestro is also available via [CLI](/maestro-cli/readme.md). However, while the Maestro CLI is the core engine for executing tests and CI/CD integration, the Maestro Studio  is a specialized layer designed for development and debugging.

| **Feature**       | **Maestro Studio**                                                | **Maestro CLI**                               |
| ----------------- | ----------------------------------------------------------------- | --------------------------------------------- |
| Primary Interface | Visual GUI / Desktop App                                          | Terminal / Command Line                       |
| Core Purpose      | Writing, running, and debugging tests visually.                   | Executing test suites in CI/CD.               |
| Setup Required    | Requires Android SDK and/or Xcode to run against virtual devices. | Requires Java 17+, Android SDK, and Xcode.    |
| Inspection Tool   | Point-and-click interface to see what Maestro sees.               | Uses `maestro hierarchy` for terminal output. |


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-studio/maestro-studio-overview.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
