> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/scrolluntilvisible.md).

# scrollUntilVisible

Scrolls the screen in a specified direction until a target element is visible.

### Parameters

The following parameters configure the `scrollUntilVisible` command.

| Parameter              | Type             | Description                                                                                                                                                                                                                                                                                              |
| ---------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `element`              | string or object | **Required.** The selector for the element to find. To select the element, you can use any of the available selectors.                                                                                                                                                                                   |
| `direction`            | string           | **(Optional).** The direction to scroll. Accepts `DOWN`, `UP`, `LEFT`, or `RIGHT`. Defaults to `DOWN`.                                                                                                                                                                                                   |
| `timeout`              | integer          | **(Optional).** The maximum time in milliseconds to scroll while searching for the element. If the timeout is reached before the element is found, the test fails. Defaults to `20000` milliseconds.                                                                                                     |
| `speed`                | integer          | **(Optional).** The scroll speed, specified as a value from `0` to `100`. Higher values result in faster scrolling. Defaults to `40`.                                                                                                                                                                    |
| `visibilityPercentage` | integer          | **(Optional).** The percentage of the element, from `0` to `100`, that must be visible in the viewport for the scroll to stop. Defaults to `100`.                                                                                                                                                        |
| `centerElement`        | boolean          | **(Optional).** If `true`, the command keeps scrolling until the element is more than 30% away from the viewport edge (e.g. in the top 70% when scrolling down). If the element cannot reach that position (e.g. it is the last list item), the command stops after a few attempts. Defaults to `false`. |

{% hint style="info" %}
By default, an element is considered visible if it is fully displayed in the viewport.
{% endhint %}

#### How it works

The command checks whether the target element is visible. If not, it swipes from the center of the screen toward the edge (to 10% from the edge in the chosen direction), checks again, and repeats until the element is found or the timeout is reached.

This behavior works well when the whole screen scrolls (e.g. a full-screen list). When only part of the screen is scrollable (such as a bottom sheet, a fragment, or a small widget), the swipe may miss the scrollable region. For those layouts, use a custom scroll loop. The [Custom scrolling for screen fragments](/examples/recipes/custom-scrolling-for-screen-fragments.md) shows how you can do it.

### Usage examples

The following examples demonstrate how to use the `scrollUntilVisible` command.

#### Scroll to an element with specific text

This example scrolls down until an element containing the text "My text" is visible.

```yaml
- scrollUntilVisible:
    element: "My text"
    direction: DOWN
```

#### Scroll to an element by ID

This example scrolls down until a view with a matching ID becomes visible.

```yaml
- scrollUntilVisible:
    element:
      id: ".*some_view_id"
    direction: DOWN
```

#### Center an element after scrolling

Use `centerElement: true` to keep scrolling until the target is not only visible but also more than 30% away from the viewport edge. The example below stops when "Item 6" meets that condition.

```yaml
- scrollUntilVisible:
    centerElement: true
    element:
      text: "Item 6"
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/scrolluntilvisible.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
