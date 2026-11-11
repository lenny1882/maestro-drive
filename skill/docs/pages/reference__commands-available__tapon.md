> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/tapon.md).

# tapOn

Tap on UI elements by text, ID, or coordinates with optional repeat and delay.

The `tapOn` command performs a tap gesture on a UI element or a specific coordinate on the screen. It is the most common interaction command in Maestro.

{% hint style="info" %}

#### Perform a long press

Use the [`longPressOn`](/reference/commands-available/longpresson.md) command to perform a long press. It accepts the same selectors and parameters as `tapOn`.
{% endhint %}

### Parameters

You can specify the target element using a shorthand text selector or a map containing a selector and optional interaction parameters.

| Parameter               | Type          | Description                                                                                                                                                                                            |
| ----------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `selector`              | String or Map | **Required.** The element to tap. Use a string for a shorthand text selector (e.g. `"My Text"`). For other selectors or to add parameters, use a map. See the Selectors documentation for a full list. |
| `point`                 | String        | A specific coordinate to tap on the screen or within a selected element. Use relative percentages (e.g. `"50%,50%"`) or absolute pixel values (e.g. `"100,200"`).                                      |
| `repeat`                | Integer       | The number of times to repeat the tap.                                                                                                                                                                 |
| `delay`                 | Integer       | The delay in milliseconds between each tap when using `repeat`. Defaults to `100`.                                                                                                                     |
| `retryTapIfNoChange`    | Boolean       | If `true`, Maestro retries the tap if the UI hierarchy does not change after the initial tap. This is useful for handling early taps before the UI is fully responsive.                                |
| `waitToSettleTimeoutMs` | Integer       | The maximum time in milliseconds that Maestro waits for the screen to settle before executing the next command. This is a best-effort timeout; Maestro does not interrupt core operations to honor it. |

### Usage examples

The following examples demonstrate how to use the `tapOn` and `longPressOn` commands.

#### Tap an element by text or ID

The fastest way to interact with your app is via visible text or technical identifiers. This example shows the shorthand for tapping an element by its visible text.

```yaml
- tapOn: "My text"
```

This example uses the `id` selector to tap an element.

```yaml
- tapOn:
    id: "your.view.id"
```

#### Repeat a tap

If you need to tap the same element several times in a row, use `repeat`. This option is useful, for example, when you need to increase the value of a counter.

If you need to wait for the animation to finish before executing the next tap, use `delay`. This example taps the button five times with a 200 ms delay between each tap.

```yaml
- tapOn:
    id: "plus_button"
    repeat: 5
    delay: 200
```

#### Retry a tap if the UI is unresponsive

If a tap is ignored because the target was not ready yet or an animation is still playing, use `retryTapIfNoChange`. This example retries the tap if the UI does not change after the first attempt.

```yaml
- tapOn:
    id: "someId"
    retryTapIfNoChange: true
```

#### Tap a specific coordinate

While element selectors are preferred, you can target specific points on the screen. This example taps the center of the screen.

```yaml
- tapOn:
    point: "50%,50%"
```

This example taps an absolute coordinate on the screen.

```yaml
- tapOn:
    point: "100,200"
```

{% hint style="info" %}
Prefer using element selectors like `id` or `text` over coordinates. Tapping by coordinate can make tests brittle and device-dependent.
{% endhint %}

#### Tap a coordinate within an element

This example finds an element containing specific text and then taps a point near the end of that element.

```yaml
- tapOn:
    text: "A text with a hyperlink"
    point: "90%,50%"
```

#### Full flow example

This example demonstrates a sequence of commands to add a new contact.

```yaml
appId: com.google.android.contacts
---
- launchApp
- tapOn:
    id: ".*floating_action_button.*" # regex
- inputText: "John"
- tapOn: "Last Name"
- inputText: "Snow"
- tapOn: ".*Save.*"
```

### Related content

Check the related commands:

* [longPressOn](/reference/commands-available/longpresson.md)
* [doubleTapOn](/reference/commands-available/doubletapon.md)

Or, learn about the different ways to identify elements using [Selectors](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md).


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/tapon.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
