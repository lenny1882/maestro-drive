> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/what-is-maestro.md).

# What is Maestro?

Maestro is an open-source UI automation framework for mobile and web with built-in tolerance, zero-wait intelligence, and declarative YAML syntax.

Maestro is the simplest and most effective open-source UI automation framework for mobile and web. It is designed to allow developers and testers to define and automate user journeys with a level of reliability and ease that traditional tools cannot match.

<figure><img src="https://1411608689-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FCbCMt5C3rawmE9oIus7f%2Fuploads%2Fgit-blob-21170ddb991b54aac54042fe34b89711750c0c0f%2Ftwitter_continuous_v3_fast.gif?alt=media" alt=""><figcaption></figcaption></figure>

Traditional testing tools often require deep instrumentation, access to the app's source code, and a strong coding ability. Maestro changes this by operating at "[arm's length](/get-started/how-maestro-works.md#the-arms-length-philosophy)," piloting the device, not the app, scrolling and tapping like a real user would through the same accessibility layer that real users rely on. This eliminates framework dependencies, allowing you to test any app, regardless of whether it was built with React Native, Flutter, or Native code.

### Why choose Maestro?

<table data-view="cards"><thead><tr><th></th><th></th></tr></thead><tbody><tr><td><i class="fa-shield">:shield:</i> <strong>Built-in Tolerance</strong></td><td>Maestro embraces the instability of mobile devices by automatically handling flakiness and UI settling.</td></tr><tr><td><i class="fa-timer">:timer:</i> <strong>Zero-Wait Intelligence</strong></td><td>No more manual <code>sleep()</code> calls. Maestro automatically waits for network content and animations to load.</td></tr><tr><td><i class="fa-file">:file:</i> <strong>Declarative Syntax</strong></td><td>Tests are defined in human-readable YAML files, removing the need for deep programming knowledge.</td></tr></tbody></table>

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th></tr></thead><tbody><tr><td><i class="fa-rocket-launch">:rocket-launch:</i> <strong>Blazingly Fast Iteration</strong></td><td>Tests run without compilation. Maestro can monitor your files and rerun flows instantly upon saving.</td></tr><tr><td><i class="fa-box">:box:</i> <strong>Single Binary Setup</strong></td><td>Maestro is a single tool that works anywhere, avoiding the "setup hell" associated with legacy drivers.</td></tr></tbody></table>

{% hint style="success" %}
🚀 **Running in the cloud**

Ready to wire into CI or scale up your testing? Start running your flows on [Maestro Cloud](https://maestro.dev/cloud). Check the Cloud documentation to run tests in the cloud and integrate with your CI pipeline.
{% endhint %}

### Maestro vs competitors

While tools like Appium or Selenium treat testing like unit tests inspecting internal APIs, Maestro treats your app as a black box. By simulating "human thumbs on a screen," Maestro validates the complete user experience stack, including interactions with system settings and notifications.

### Ready to start?

Explore the core components of the Maestro ecosystem and begin your journey:

<table data-card-size="large" data-view="cards"><thead><tr><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><strong>How Maestro works</strong></td><td>Understand the "arm's length" philosophy and accessibility-first element detection.</td><td><a href="/get-started/how-maestro-works.md">How Maestro works</a></td></tr><tr><td><strong>QuickStart guide</strong></td><td>Install Maestro Studio and run your first test in under five minutes.</td><td><a href="/get-started/quickstart.md">QuickStart</a></td></tr><tr><td><strong>Maestro solutions</strong></td><td>Compare the Maestro CLI, Maestro Studio (IDE), and Maestro Cloud to find the right tool for your workflow.</td><td><a href="/get-started/maestro-solutions.md">Maestro solutions</a></td></tr><tr><td><strong>Supported platforms</strong></td><td>View the full list of supported frameworks, including Jetpack Compose, SwiftUI, and Web.</td><td><a href="/get-started/supported-platform.md">Supported platforms</a></td></tr></tbody></table>


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/get-started/what-is-maestro.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
