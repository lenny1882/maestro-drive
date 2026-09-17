> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/selectors/core-selectors.md).

# Core Selectors

Basic selectors are the most common way to identify elements in Maestro. They allow you to target views using their visible text, accessibility identifiers, or specific screen coordinates.

By default, Maestro uses the accessibility tree to find these elements, ensuring your tests interact with the app just as a user would.

#### Overview

| **Selector** | **Description**                                                     |
| ------------ | ------------------------------------------------------------------- |
| `text`       | Matches the visible text or accessibility label of an element.      |
| `id`         | Matches the accessibility identifier of an element.                 |
| `index`      | Picks a specific occurrence when multiple elements match.           |
| `point`      | Targets a specific coordinate on the screen (Relative or Absolute). |
| `css`        | Web only. Targets elements using standard CSS selectors.            |

{% hint style="info" %}

#### **Regular expressions**

You can handle dynamic values easily because `text` and `id` are regex-based.&#x20;

Remember to escape special characters like `$` or `[` with a backslash (`\`).
{% endhint %}

{% hint style="info" %}

#### **Platform specifics**

* **Flutter**: Use visible text or Semantics Labels (for text), or Semantics Identifiers (for id). Internal Flutter "Keys" are not supported.
* **Android Compose**: Use `Modifier.semantics { testTagsAsResourceId = true }` to ensure your test tags are discoverable as IDs.
  {% endhint %}

### `text`

The `text` selector finds elements based on the string displayed on the screen. On Android, this includes `contentDescription`, and on iOS, it includes `accessibilityLabel`.

* **Regex by Default**: All text selectors are treated as regular expressions.
* **Shorthand**: You can skip the key and use a string directly for commands like `tapOn` or `assertVisible`.

```yaml
- tapOn: Login              # Shorthand (matches exactly "Login")
- tapOn: 
    text: ".*Continue.*"    # Regex for partial match
- assertVisible: Submit     # Shorthand for visibility check
```

### `id`

The `id` selector targets the technical identifier of a view. This is highly recommended for dynamic content, icons without text, or localized apps where the visible text changes based on the language.

* **Android**: Maps to the Resource ID.
* **iOS**: Maps to the `accessibilityIdentifier`.

```yaml
- tapOn:
    id: login_button
- assertVisible:
    id: header_icon
```

### `index`

When multiple elements match the same criteria (e.g., three **Add to Cart** buttons on one screen), use `index` to specify which one to interact with. The index is 0-based.

```yaml
# Taps the third instance of an element with the ID "buy_button"
- tapOn:
    id: buy_button
    index: 2
```

### `css`

The `css` selector allows you to target elements in a web application using standard CSS selector syntax. This is particularly useful for targeting classes, IDs, or specific attributes in the DOM. Unlike `text` or `id`, this selector does not support regular expressions.

```yaml
- tapOn:
    css: .secondaryButton
- assertVisible:
    css: "#main-header"
```

### `point`

The `point` selector allows you to interact with specific screen coordinates. This is useful for elements that aren't in the accessibility tree or for tapping specific areas of a large view.

* Relative Position: Defined in percentages (e.g., `"50%, 50%"` for the center).
* Absolute Coordinates: Defined in exact pixels (e.g., `"100, 200"`).

```yaml
- tapOn:
    point: "50%, 50%"   # Taps the center of the screen
- tapOn:
    point: "100, 250"   # Taps 100 pixels from left, 250 from top
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/selectors/core-selectors.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
