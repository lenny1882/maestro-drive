> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/selectors/dimension-matchers.md).

# Dimension matchers

Match elements by width and height with optional tolerance values.

Dimension Selectors allow you to identify and filter UI elements based on their physical size on the screen.&#x20;

### **Overview**

| **Selector** | **Description**                                                                             |
| ------------ | ------------------------------------------------------------------------------------------- |
| `width`      | Targets an element with a specific width in pixels.                                         |
| `height`     | Targets an element with a specific height in pixels.                                        |
| `tolerance`  | A value used to allow for minor rendering or rounding differences when matching dimensions. |

{% hint style="success" %}

#### Usage tips

* **Combine with Traits**: Use `tolerance` alongside `traits: square` if you need to find an element that is square but you only know its approximate size.
* **Device Variability**: Be careful with hardcoded pixel values when running tests on a wide variety of device models with different screen resolutions. Using a higher `tolerance` can help maintain cross-device compatibility.
  {% endhint %}

### `width` and `height`

These selectors match the exact pixel dimensions of an element as reported by the accessibility tree. Because screen densities vary across different devices (e.g., iPhone 15 vs. Pixel 7), it is recommended to combine `width` and `height` with other Selectors.

```yaml
# Taps a button that is exactly 200px wide
- tapOn:
    id: action_button
    width: 200

# Asserts that the profile header has a height of 350px
- assertVisible:
    id: profile_header
    height: 350
```

### `tolerance`

Rendering engines and screen scaling can result in slight variations in reported dimensions (e.g., a 100px button reporting as 99px or 101px). The `tolerance` parameter allows you to define a buffer range to ensure your tests remain stable across different devices.

If you set a `tolerance: 5`, Maestro will match any element within +/- 5 pixels of the target dimension.

```yaml
# Matches an icon that is 48px square, with a 2px wiggle room
- assertVisible:
    id: settings_icon
    width: 48
    height: 48
    tolerance: 2
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/selectors/dimension-matchers.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
