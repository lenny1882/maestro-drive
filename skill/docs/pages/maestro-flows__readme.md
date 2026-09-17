> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/readme.md).

# Maestro Flows overview

Maestro Flows are the fundamental building blocks of UI automation, representing specific segments of a user journey, such as Login, Checkout, or Search for an item, within an application. Flows can represent complete user journeys or discrete functional components that can be composed into larger test scenarios. By modeling real-world user interactions, Flows provide a reliable, repeatable way to verify app behavior across Android, iOS, and Web platforms from a single suite.

#### The anatomy of a Flow

Flows use a human-readable YAML format designed to be maintained by both developers and manual testers without heavy programming knowledge.

A standard Flow consists of two distinct parts separated by three dashes (`---`):

* **Configuration Section**: Defined at the top (above the `---` marker), this includes the `appId` of the app under test, along with optional metadata like `name`, `tags`, and environment variables.
* **Commands Section**: A sequence of declarative commands, such as `tapOn` and `inputText`, that simulate user actions and validate the UI state.

```yaml
# --- Configuration Section ---
appId: com.example.app         # Mandatory: Define the ID of the app under test
name: My Login Flow            # Optional: Customize the Flow name
tags:                          # Optional: Filter which tests to run
  - smoke-test
env:                           # Optional: Map of environment variables
  USERNAME: "user@example.com"

---
# --- Commands Section ---
- launchApp                    # Launches the application
- tapOn: "Username"            # Interacts with the username field
- inputText: ${USERNAME}       # Inputs the environment variable
- tapOn: "Login"               # Taps the login button
- assertVisible: "Welcome"     # Verifies success message appears
```

### Explore Flows capabilities

<table data-view="cards"><thead><tr><th></th><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><i class="fa-arrow-progress">:arrow-progress:</i></td><td><strong>Flow control and logic</strong></td><td>Build resilient, intelligent journeys. Master the architectural tools used to scale your tests, including modular subflows, conditional branching, repetitive loops, and lifecycle hooks.</td><td><a href="/pages/KsAwaeHz7lKgM9s7EMkI">/pages/KsAwaeHz7lKgM9s7EMkI</a></td></tr><tr><td><i class="fa-node-js">:node-js:</i></td><td><strong>JavaScript</strong></td><td>Extend YAML with custom scripting. Use the integrated JavaScript sandbox to handle complex data, generate random test variables, capture script outputs, and interact with external APIs via HTTP requests.</td><td><a href="/pages/N72iCVWiRWYBZ8BruPC7">/pages/N72iCVWiRWYBZ8BruPC7</a></td></tr><tr><td><i class="fa-gears">:gears:</i></td><td><strong>Workspace management</strong></td><td>Transition from writing commands to designing a testing system. Learn to configure global behaviors with <code>config.yaml</code>, organize repository architectures, and manage test execution and analysis at scale.</td><td><a href="/pages/KFSFrrC0ZCkU35FT0Y7B">/pages/KFSFrrC0ZCkU35FT0Y7B</a></td></tr></tbody></table>

### Next step

Learn how to build resilient, intelligent journeys by mastering [Flow control and logic](/maestro-flows/flow-control-and-logic/flow-control-and-logic-overview.md).


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/readme.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
