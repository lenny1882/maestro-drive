> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/repeat.md).

# repeat

The `repeat` command executes a sequence of commands multiple times, either for a fixed number of iterations or until a specific condition is met.

### Parameters

To customize sequence execution when using the `repeat` command, you can use the following parameters:

| Parameter  | Type      | Description                                                                                                                |
| ---------- | --------- | -------------------------------------------------------------------------------------------------------------------------- |
| `times`    | integer   | The number of times to repeat the `commands`.                                                                              |
| `while`    | condition | A condition that must evaluate to `true` for the loop to continue. The loop terminates when the condition becomes `false`. |
| `commands` | list      | The list of commands to execute during each iteration.                                                                     |

### Usage examples

#### Repeat a specific number of times

To execute a set of commands a fixed number of times, use the `times` parameter.

```yaml
- repeat:
    times: 3
    commands:
      - tapOn: Button
      - scroll
```

In the above example, the test will repeat the process of tapping on the button and scrolling three consecutive times.

#### Repeat while a condition is true

To execute commands as long as a condition is met, use the `while` parameter. The loop continues as long as the element with the text `ValueX` is not visible.

```yaml
- repeat:
    while:
      notVisible: "ValueX"
    commands:
      - tapOn: Button
```

#### Repeat using a JavaScript expression

The `while` parameter also accepts a JavaScript expression. The loop continues as long as the expression evaluates to `true`.

```yaml
- evalScript: ${output.counter = 0}
- repeat:
    while:
      true: ${output.counter < 3}
    commands:
      - tapOn: Button
      - evalScript: ${output.counter = output.counter + 1}
```

#### Repeat with a maximum count and a condition

You can combine `times` and `while` to repeat commands until a condition is met, but for no more than a specified number of iterations. The loop stops when either the `while` condition becomes `false` or the `times` count is reached, whichever occurs first.

The following example taps a button while an element is not visible, but stops after 10 attempts regardless of the element's visibility.

```yaml
- repeat:
    times: 10
    while:
      notVisible: "someElement"
    commands:
      - tapOn: Button
```

Here’s another example that logs `"Hello World"` four times. The `times: 4` limit ensures the loop stops even if the condition never becomes false. For example, if the counter were never incremented.

```yaml
- evalScript: ${output.counter = 1}
- repeat:
    times: 4
    while:
      true: ${output.counter < 10}
    commands:
      - evalScript: ${console.log("Hello World")}
      - evalScript: ${output.counter++}
```

{% hint style="success" %}
Use the `--verbose` flag to see the effect of the `repeat` command more effectively when using [Maestro CLI overview](/maestro-cli/readme.md).
{% endhint %}

### Related content

Learn how to use [conditions](/maestro-flows/flow-control-and-logic/conditions.md) in your Flows.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/repeat.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
