> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/supported-platform/web-browser.md).

# Web Browsers

Test web applications in desktop browsers using Maestro's web automation capabilities.

<figure><img src="https://1411608689-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FCbCMt5C3rawmE9oIus7f%2Fuploads%2FEo0j9rs1l8TSiGekzja4%2Fimage.png?alt=media&amp;token=1d836276-32c2-4ad4-b509-63eeb8acc366" alt=""><figcaption></figcaption></figure>

Maestro extends its one framework to rule them all philosophy to the desktop browser. By using the same declarative YAML syntax you use for mobile, you can automate web applications, enabling unified end-to-end testing across your entire product surface.

{% hint style="warning" %}
**Beta Status**

Web support is currently in Beta. It is functional for Chromium-based testing and is ideal for teams looking to consolidate their mobile and web automation into a single toolset.
{% endhint %}

### Technical approach

Maestro maintains its "Arm's Length" philosophy for web testing. Instead of directly manipulating the DOM or injecting JavaScript, Maestro interacts with the browser as a user would.

* **Unified Syntax**: The same commands like `tapOn`, `inputText`, and `assertVisible` work identically on Web as they do on Android and iOS.
* **Framework Agnostic**: Whether your site is built with React, Vue, Angular, or plain HTML, Maestro interacts with the rendered output.

### Execution Workflow

For web tests, you replace the `appId` with a `url`. Behind the scenes, Maestro treats the URL as the unique identifier for the application session.

```yaml
# example.yaml
url: https://maestro.mobile.dev
---
- launchApp
- tapOn: "Installing Maestro"
- assertVisible: "Installing the CLI"
```

On the first run, Maestro will automatically download a managed version of Chromium. Subsequent runs will launch instantly. To run the test with [Maestro CLI](https://docs.maestro.dev/maestro-cli/), just run:

```bash
maestro test example.yaml
```

### Maestro Studio for Web

[Maestro Studio](https://docs.maestro.dev/maestro-studio/) is fully compatible with web testing. It allows you to visually inspect web elements and generate YAML commands through a point-and-click interface.

### Platform specifics and tips

* **Flutter Web**: Just like Flutter Mobile, Flutter Web renders elements differently. You should use Semantics to make elements addressable. Refer to the [Flutter](https://docs.maestro.dev/platform-support/flutter) documentation for best practices.
* [**Selectors**](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md): Maestro prioritizes user-visible text. For complex web apps, using unique text labels or stable accessibility attributes is recommended to ensure your tests remain "refactoring resilient."

### State Management

By default, browser state (cookies, local storage, etc.) is retained between flows in the same test run. State can be cleared by [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) by using the [clearState](/reference/commands-available/clearstate.md) command or the `clearState` option of the [launchApp](/reference/commands-available/launchapp.md) command.

### Known limitations

As this feature is in Beta, certain advanced browser configurations are not yet supported:

* **Browser Engines**: The current default and only supported browser is Chromium.
* **Localization**: The default locale is set to `en-US`.
* **Screen Dimensions**: Custom screen size and viewport configuration are currently preset.

### Next steps

If you don't know how to create tests with Maestro, access the [QuickStart](/get-started/quickstart.md) guide to get up and running in minutes.

To learn how to create tests, refer to the [Flows](https://docs.maestro.dev/maestro-flows/) documentation. If you want to explore Maestro solutions, consult the appropriate documentation:

* [Maestro Studio](https://docs.maestro.dev/maestro-studio/)
* [Maestro CLI](https://docs.maestro.dev/maestro-cli/)
* [Maestro Cloud](/maestro-cloud/readme.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/get-started/supported-platform/web-browser.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
