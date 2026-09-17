> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/flow-control-and-logic-overview.md).

# Flow control and logic overview

While standard Flows represent linear user journeys, real-world testing often requires dynamic behavior. This section covers the tools that allow your tests to adapt to different application states, platform requirements, and data environments.

### Core pillars of Flow architecture

To build scalable tests, you will utilize five pillars:

#### **Selection**

Identify UI elements with precision. Before building the test logic, you must master [how to use Selectors](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md) to ensure Maestro can reliably find and interact with the correct parts of your application screen.

#### **Modularity**

Avoid repeating yourself, you can use [Nested Flows](/maestro-flows/flow-control-and-logic/nested-flows.md) to extract common journeys, like Login or Onboarding, into separate files. You can then call these "subflows" across your entire suite using the `runFlow` command.

#### **Conditional execution**

Not every test step should run every time. [Conditions](/maestro-flows/flow-control-and-logic/conditions.md) allow you to execute actions based on element visibility, platform (iOS vs. Android), or custom JavaScript expressions.

#### **Repetition**&#x20;

Handle dynamic lists or "polling" scenarios with [Loops ](/maestro-flows/flow-control-and-logic/loops.md)to repeat actions until a goal is met. Complement this with [Wait Commands](/maestro-flows/flow-control-and-logic/wait-commands.md) to ensure your tests only proceed when the UI is stable, eliminating flakiness from slow network loads.

#### **Environment and l**ifecycle

Manage test data externally using [parameters and constants](/maestro-flows/flow-control-and-logic/parameters-and-constants.md), allowing the same Flow to run in Staging, QA, or Production. Use [Hooks ](/maestro-flows/flow-control-and-logic/hooks.md)(`onFlowStart`, `onFlowComplete`) to automate setup and teardown tasks, such as clearing app state or granting [Permissions](/maestro-flows/flow-control-and-logic/permissions.md).


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/flow-control-and-logic-overview.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
