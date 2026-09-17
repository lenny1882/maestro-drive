> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/javascript/manage-data-and-states.md).

# Manage data and states

Sharing data between UI elements and JavaScript scripts is essential for creating dynamic, resilient tests. This guide covers how to use the global `output` object, manage namespaces, and capture UI text for use in your logic.

### The `output` object

Maestro provides a single, global JavaScript object called `output` that persists throughout the entire execution of a Flow. Any data assigned to this object in one script or expression is immediately accessible to all subsequent scripts and Maestro commands.

You can store strings, numbers, booleans, or complex objects within `output`. You can access or add information to the `output` object using standard JavaScript notation. In the following example, the value `'Hello World'` is assigned to `result` (an arbitrary key name):

```javascript
// myScript.js
output.result = 'Hello World'
```

Once the Flow runs `myScript.js`, the value is assigned to the global object. You can then use that value in subsequent commands, such as `inputText`:

```yaml
- runScript: myScript.js
- inputText: ${output.result}
```

### Output Namespacing

Because the `output` object is global, different scripts can accidentally overwrite each other’s data if they use the same variable names. To prevent this, use namespaces (sub-objects named after your specific script or feature).

For example, instead of assigning variables directly to the root of `output`, group them by context:

{% tabs %}
{% tab title="authScript.js" %}

```javascript
output.auth = {
    token: "abc-123",
    expiry: 3600
};
```

{% endtab %}

{% tab title="profileScript.js" %}

```javascript
output.profile = {
    username: "MaestroUser",
    role: "Admin"
};
```

{% endtab %}
{% endtabs %}

You can then access this data using namespaced notation:

```yaml
- inputText: ${output.auth.token}
- assertVisible: ${output.profile.username}
```

### Shared Functions

The `output` object can store functions as well as data. This is a powerful pattern for defining reusable logic, such as API helpers or complex string formatters, at the start of a Flow so they can be called from any subsequent script.

In this example, we define a token generation function in `apiUtils.js` and make it globally available via the `output.utils` namespace:

```javascript
// apiUtils.js
function generateToken(prefix) {
    return prefix + "_" + Math.random().toString(36);
}

output.utils = {
    generateToken: generateToken
};
```

By loading the script in `onFlowStart`, the `generateToken` function becomes a reusable utility for the rest of the test execution:

```yaml
onFlowStart:
    - runScript: apiUtils.js
---
# Call the shared function to generate a new session token
- evalScript: ${output.sessionToken = output.utils.generateToken('session')}
```

### The `maestro` Object

The `maestro` object is a built-in utility that provides information about the current test environment and captured UI data.

| Property             | Description                                                                                                                                                                                               |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `maestro.copiedText` | Contains the text retrieved by the most recent [`copyTextFrom`](/reference/commands-available/copytextfrom.md) command.                                                                                   |
| `maestro.platform`   | <p>Identifies the OS:<br><br>- <code>ios</code><br>- <code>android</code><br>- <code>web</code><br><br>This is useful for <a href="/pages/PSh3jkLSoQSvjzMpuuNY">conditional</a> cross-platform logic.</p> |

#### Capturing UI Text

To move text from your application into your JavaScript logic:

1. Use the [`copyTextFrom`](/reference/commands-available/copytextfrom.md) command to store the content in the `maestro.copiedText` variable.
2. Access that content in your JavaScript code or Maestro commands using `maestro.copiedText`.

The following example copies content from a `userName` element and uses it to send a dynamic message:

```yaml
- copyTextFrom: 
    id: userName # Target the userName element
- inputText: ${'Hello ' + maestro.copiedText} # Greets the user using the captured name
```

### Next steps

Now that you already knows how to manage data when using JavaScript in Maestro Flows, access the following guides:

* [Generate synthetic data](/maestro-flows/javascript/generate-synthetic-data.md): Use `faker` to create dynamic test data.
* [Make HTTP requests](/maestro-flows/javascript/make-http-requests.md): Use the built-in HTTP client for API interactions.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/javascript/manage-data-and-states.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
