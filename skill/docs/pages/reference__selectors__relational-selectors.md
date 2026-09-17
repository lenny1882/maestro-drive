> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/selectors/relational-selectors.md).

# Relational Selectors

Relational Selectors allow you to identify UI elements based on their relationship to other views on the screen. This is extremely useful when elements have generic names (like multiple "Buy" buttons) or when you want to target a view that lacks a stable `text` or `id` but is always located near a known anchor.

### **Overview**

| **Selector**          | **Description**                                                              |
| --------------------- | ---------------------------------------------------------------------------- |
| `above`               | Matches a view located vertically above a specified anchor element.          |
| `below`               | Matches a view located vertically below a specified anchor element.          |
| `leftOf`              | Matches a view located to the left of a specified anchor element.            |
| `rightOf`             | Matches a view located to the right of a specified anchor element.           |
| `containsChild`       | Matches a parent element that has a direct child matching specific criteria. |
| `childOf`             | Matches an element that is a child of a specified parent element.            |
| `containsDescendants` | Matches a view that contains a specific set of descendant elements.          |

{% hint style="success" %}

#### Usage tips

* **Compound Selectors**: Positional selectors (`above`, `below`, `leftOf`, `rightOf`) use screen bounds; for example, `leftOf` means "left of" by coordinate only, not necessarily next to or vertically aligned with the anchor. Combining them with other attributes (`id`, `text`, `enabled`, etc.) improves precision: `tapOn: { id: "icon", rightOf: "Settings", enabled: true }`.
* **Anchor Reliability**:  Always use the most stable element (typically static text or a unique ID) as the anchor for `above`, `below`, `leftOf`, or `rightOf`.
  {% endhint %}

### Alignment selectors

The vertical alignment selectors `above` and `below`  identify views located above or below a reference element.

```yaml
# Tap a view located below the "Email" label
- tapOn:
    below: Email

# Tap a view located above the "Checkout" title
- tapOn:
    above: Checkout
```

Similarly, horizontal alignment selectors `leftOf` and `rightOf`  are used to identify  elements positioned side-by-side, such as icons next to labels.

```yaml
# Tap the view to the right of an input field
- tapOn:
    rightOf:
      id: input_text

# Tap the view to the left of a specific phrase
- tapOn:
    leftOf: I agree to the terms
```

These alignment selectors use screen bounds; for precision when multiple elements match, combine them with other selectors (see **Compound Selectors** in the tip above).

**To assert vertical hierarchy**

You can stack `above` or `below` to assert the vertical order of elements:

```yaml
- assertVisible:
    text: Top Thing
    above:
      text: Middle Thing
      above:
        text: Bottom Thing
```

### Parent-Child Relationships

These selectors navigate the accessibility tree rather than relying on screen position.

#### `containsChild` (Direct child only)

This matches a parent element that has a direct child matching the given selector.

```yaml
# Tap the container that directly contains the text "Order 12345"
- tapOn:
    containsChild:
      text: Order 12345
```

#### `childOf` (Direct parent only)

This matches an element that is a direct child of a specific parent. This is useful when the same child element exists in multiple containers.

```yaml
# Tap the Delete button inside the Basket
- tapOn:
    text: Delete
    childOf:
        id: basket_container
```

#### **`containsDescendants`**

This matches a view that contains all specified descendant elements, at any depth in its hierarchy. This is not limited to direct children. Use `containsDescendants` for complex components like cards, rows, or grouped layouts where relevant elements may be nested multiple levels deep.

```yaml
# Find a list item that contains both a specific product name and a price
- assertVisible:
    id: list_item
    containsDescendants:
      - text: Wireless Headphones
      - text: $99.99
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/selectors/relational-selectors.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
