> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/hooks.md).

# Hooks

In automated testing, you often need to perform specific setup or cleanup tasks for every test. Instead of manually adding a `runFlow` to the start or end of every file, Maestro provides Hooks.

Hooks provide a configuration section to place setup and teardown logic, separate from the steps in the test. This ensures a consistent environment, reduces boilerplate code, and simplifies maintenance.

#### Types of Hooks

Maestro supports two primary hooks defined in the configuration section (above the `---` marker in your Flow file). These hooks apply every time you run the Flow:

| Hook             | When it runs                                         | Ideal Use Case                                                                  |
| ---------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| `onFlowStart`    | Before every individual Flow begins.                 | Resetting app state, logging in, or handling dynamic permissions.               |
| `onFlowComplete` | After every individual Flow finishes (Pass or Fail). | Clearing cookies, logging out, reporting custom metrics, or deleting test data. |

Here's how you could use these hooks in your `flow.yaml`:

```yaml
# flow.yaml
appId: my.app
onFlowStart:
  - runFlow: setup.yaml
  - runScript: setup.js
  - <any other command>
onFlowComplete:
  - runFlow: teardown.yaml
  - runScript: teardown.js
  - <any other command>
---
- launchApp
```

{% hint style="success" %}

#### Best practices

* Since hooks run for every single Flow, a slow hook will significantly increase your total suite execution time.
* Be careful not to call a Flow that itself triggers the same hook, causing an infinite loop.
* Use the `when` block within your hook sub-flow to perform actions only on specific platforms (e.g., clearing the iOS Keychain).
* Use `onFlowComplete` hook to ensure your app is in a "neutral" state for the next test, such as navigating back to the home screen, logging out, or deleting test data from your environment.
  {% endhint %}

### Usage example

Let's walk through how to set up setup and teardown logic so that every test in your workspace starts with an authenticated user.

#### **Step 1: Create your login subflow**

Create a reusable file at `subflows/login.yaml`:

```yaml
# subflows/login.yaml
- tapOn: "Username"
- inputText: "maestro_user"
- tapOn: "Login"
```

#### **Step 2: Register the hook**

Open your `flow.yaml` file and add the hooks to the configuration section:

```yaml
# flow.yaml
appId: com.example.app

onFlowStart:
  runFlow: subflows/login.yaml
```

#### **Step 3: Run your tests**

Now, when you run your test using `maestro test .`, it will execute the `login.yaml` sequence before starting the logic in your specific test file.

### Dynamic hooks

You can pass environment variables into your hooks just like a standard `runFlow`. This is useful for switching roles (e.g., User vs. Admin) across your entire suite.

```yaml
# flow.yaml
appId: com.example.app

onFlowStart:
  runFlow:
    file: subflows/login.yaml
    env:
      ROLE: "admin"
```

### **Handling hook failures**

It is important to understand how Maestro behaves when a hook encounters an error. Maestro’s logic remains consistent with industry-standard testing frameworks like **JUnit** (`@Before`/`@After`) and **XCTest** (`setUp`/`tearDown`).

If a hook fails, Maestro prioritizes test integrity and environment cleanup.

| Scenario                   | Result / Behavior                                                                                                                                                                                                                                                                             |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`onFlowStart` fails**    | <ol><li>The entire Flow is immediately marked as <strong>Failed</strong> (🔴).</li><li>The main body of the Flow execution is <strong>skipped</strong>.</li><li> The <strong><code>onFlowComplete</code></strong> hook is <strong>still executed</strong> to ensure cleanup occurs.</li></ol> |
| **`onFlowComplete` fails** | The Flow is marked as **Failed** (🔴), even if the main body of the test passed.                                                                                                                                                                                                              |

#### Related content

* [Nested flows](/maestro-flows/flow-control-and-logic/nested-flows.md): Understand the underlying `runFlow` command used by hooks.
* [Sequential execution](/maestro-flows/workspace-management/sequential-execution.md): Learn how hooks interact when running tests in a specific order.
* [Parameters and constants](/maestro-flows/flow-control-and-logic/parameters-and-constants.md): See how to manage variables within your hooks.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/hooks.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
