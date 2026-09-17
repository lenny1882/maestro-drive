> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/inputtext.md).

# inputText

the `inputText` command inputs a specified text string. This command works even if no text field is focused.

### Syntax

You can use the shorthand string syntax for quick inputs:

```yaml
- inputText: "string"
```

You can also use the expanded syntax to include the label:

```yaml
- inputText:
    text: "user@example.com"
    label: "Input the test system username"
```

The `label` parameter provides real-world context in your test reports, making it clear what specific data is being entered during that step.

{% hint style="warning" %}
Unicode characters are not supported on Android. See [GitHub issue #146](https://github.com/mobile-dev-inc/maestro/issues/146) for status updates.
{% endhint %}

### Random text input commands

Maestro provides several commands to input randomly generated data. These commands use the [DataFaker](https://www.datafaker.net/) library.

| Command                  | Description                      |
| ------------------------ | -------------------------------- |
| `inputRandomEmail`       | Inputs a random email address.   |
| `inputRandomPersonName`  | Inputs a random person's name.   |
| `inputRandomNumber`      | Inputs a random integer.         |
| `inputRandomText`        | Inputs random unstructured text. |
| `inputRandomCityName`    | Inputs a random city name.       |
| `inputRandomCountryName` | Inputs a random country name.    |
| `inputRandomColorName`   | Inputs a random color name.      |

#### Parameters for random text commands

You can specify the length for certain random input commands.

| Parameter | Type      | Applicable Commands                       | Description                                                                   |
| --------- | --------- | ----------------------------------------- | ----------------------------------------------------------------------------- |
| `length`  | `integer` | `inputRandomNumber` and `inputRandomText` | Specifies the number of digits or characters to generate. The default is `8`. |

### Usage examples

You can use the `inputText` command to add a specific string:

```yaml
- inputText: "Hello World"
```

You can also input a random number or text with a specific length:

```yaml
- inputRandomNumber:
    length: 9  
- inputRandomText:
    length: 11  
```

#### Reuse a random value in an assertion

This example inputs a random string, copies it to a variable, and then asserts that the copied text is visible on the next screen.

```yaml
- tapOn:
    id: MyTextInput
- inputRandomText
- copyTextFrom:
    id: MyTextInput
- tapOn: 'Submit'
- assertVisible: ${maestro.copiedText}
```

In this example, `copyTextFrom` stores the copied text in the `copiedText` variable. This value is then used by `assertVisible` to verify that the generated text appears on the new screen after tapping the **Submit** button.

#### Use variables

You can input dynamic data stored in variables or the results of JavaScript expressions.

```yaml
# Input text from an environment variable or previous output
- inputText: ${USER_EMAIL}

# Input using complex logic
- inputText: ${'testuser_' + Math.floor(Math.random() * 1000)}
```

### Related commands

* [copyTextFrom](/reference/commands-available/copytextfrom.md)


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/inputtext.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
