> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/javascript/javascript-overview.md).

# JavaScript overview

While Maestro’s YAML syntax is designed to handle the majority of UI interactions declaratively, certain testing scenarios require complex logic that goes beyond simple linear steps. The JavaScript integration allows you to make use of a full-scale scripting engine directly from your Flows, enabling you to handle dynamic data, complex assertions, and external integrations.

### Why use JavaScript in your Flows?

JavaScript provides the flexibility needed to create resilient, data-driven tests without sacrificing the stability. By using JavaScript, you can:

* **Handle Dynamic Data**: Generate unique identifiers, format dates, or manipulate strings for input fields.
* **Complex Control Flow**: Implement logic that YAML cannot express easily, such as complex mathematical calculations or multi-step conditional branching.
* **External Connectivity**: Sync your UI tests with your backend by making API calls to fetch test data or verify database states.
* **Enhanced Assertions**: Write custom logic to verify UI states that require calculation or data parsing.

### How it works

To ensure that tests remain portable and secure, Maestro executes JavaScript in a restricted sandbox. This means the scripts run in a "clean" environment without direct access to your local file system or external Node.js libraries. This architecture ensures that a Flow written on one machine will behave identically on a teammate's computer or in Maestro Cloud.

{% hint style="info" %}

#### JavaScript engine support

In Maestro, the GraalJS engine is enabled by default, allowing you to use modern ECMAScript (ES6+) features.

Rhino is also supported, but it must be explicitly enabled. Maestro discourage the Rhino usage.
{% endhint %}

### Explore JavaScript capabilities

Navigate through these guides to master scripting within your automation suite:

* [Run and debug JavaScript](/maestro-flows/javascript/run-and-debug-javascript.md): Maestro provides three ways to run JavaScript. You can also use standard `console.log` statements to debug your logic during execution.
* [Manage data and states](/maestro-flows/javascript/manage-data-and-states.md): The global `output` object allows you to share data across your entire Flow. This ensures that a value captured or generated in one script can be used by any subsequent YAML command or JavaScript expression.
* [Make HTTP requests](/maestro-flows/javascript/make-http-requests.md): With the built-in HTTP client, you can perform `GET`, `POST`, `PUT`, and `DELETE` requests directly from your scripts.&#x20;
* [Generate synthetic data](/maestro-flows/javascript/generate-synthetic-data.md): The `faker` object integration enables the generation of randomized data to ensure every test run uses fresh data and avoids account collisions.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/javascript/javascript-overview.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
