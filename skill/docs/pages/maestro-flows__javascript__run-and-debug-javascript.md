> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/javascript/run-and-debug-javascript.md).

# Run and debug JavaScript

This guide explains how to execute JavaScript within your Maestro Flows and how to use logging to debug your scripts.

### Execution Methods

Maestro provides three ways to run JavaScript, depending on the complexity of the logic you need to perform.

#### 1. In-line expressions

For simple logic or dynamic values, use the `${}` syntax directly inside existing Maestro commands. This is ideal for string concatenation or basic math.

```yaml
- launchApp
- inputText: ${'User_' + faker.name().firstName()} # Generates a dynamic username
- tapOn: ${maestro.platform === 'ios' ? 'Allow' : 'While using the app'} # Conditional logic
```

{% hint style="info" %}
Learn how to [generate synthetic data](/maestro-flows/javascript/generate-synthetic-data.md) using JavaScript.
{% endhint %}

#### 2. The `evalScript` Command

Use [`evalScript`](/reference/commands-available/evalscript.md) for logic-only steps that do not directly interact with a UI element, such as setting a variable or performing a calculation.

```yaml
- evalScript: ${output.timestamp = new Date().getTime()} # Store data for later use
- evalScript: ${console.log('Test execution started')} # Inline logging
```

#### 3. The `runScript` Command

For complex logic, reusable functions, or long scripts, use [`runScript`](/reference/commands-available/runscript.md) to execute an external `.js` file.

You can pass environment variables to your script using the `env` attribute, in the same way you pass parameters to subflows. First, use `runScript` to define the JavaScript file and the variables to be shared with it:

```yaml
- runScript:
    file: setupUser.js
    env:
       userRole: 'admin' # Pass a parameter to the script
```

The JavaScript file can then read the environment variable directly to perform necessary actions:

```javascript
// Access the passed parameter directly by its name
const role = userRole; 
console.log(`Setting up user with role: ${role}`);
```

### Logging and debugging

Maestro supports standard `console.log` statements to help you debug your scripts and track Flow execution.

When logging with JavaScript in Maestro, keep these points in mind:

* **Multiple arguments are not supported:** Running `console.log('My variable is', variable)` will only output `My variable is`.
* **Use template literals or concatenation:** To log variables alongside text, use template literals (in external files) or string concatenation.
* **Log Destination:** Anything output via `console.log` is captured in the `maestro.log` file, prefaced with `JsConsole`.

The following code snippet shows examples of both methods:

```javascript
console.log('Value: ' + myVar)   // concatenation
console.log(`Value is ${myVar}`) // template literals
```

#### Logging with `evalScript` command <a href="#logging-with-evalscript-command" id="logging-with-evalscript-command"></a>

If you want to log something inline, you can use [`evalScript`](/reference/commands-available/evalscript.md) to output it to the console without creating a separate file.

```yaml
- evalScript: '${console.log("Value: " + myVar)}'
```

{% hint style="info" %}

#### Don't use template literals in `evalScript`

Standard JavaScript template literals (using backticks \`\`\` and `${}`) will **not** work inside `evalScript` because the command itself is already wrapped in a `${...}` block.&#x20;

```yaml
# Example of incorrect use
- evalScript: console.log(`Value is ${myVar}`)
```

Use string concatenation instead.
{% endhint %}

#### Logging in external files

When using `runScript`, you can organize your logs within your JavaScript files just as you would in a standard development environment. Here, template literals are fully supported.

The following Flow runs a script which will log a status message:

{% tabs %}
{% tab title="Flow" %}

```yaml
- runScript:
    file: script.js
```

{% endtab %}

{% tab title="JavaScript file (script.js)" %}

```js
// script.js
const status = 'Success';
console.log(`Operation status: ${status}`); // Outputs 'Operation status: Success'
```

{% endtab %}
{% endtabs %}

### Next steps

Now that you already know how to run and debug JavaScript code in Maestro Flows, access the following guides:

* [Manage data and states](/maestro-flows/javascript/manage-data-and-states.md): Learn how to use the `output` object.
* [Generate synthetic data](/maestro-flows/javascript/generate-synthetic-data.md): Use `faker` to create dynamic test data.
* [Test reports and artifacts](/maestro-flows/workspace-management/test-reports-and-artifacts.md): Learn how to access the `maestro.log` using the `--debug-output` flag to see your console logs.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/javascript/run-and-debug-javascript.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
