> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/hidekeyboard.md).

# hideKeyboard

The `hideKeyboard` command hides the software keyboard if it is visible.

### Usage examples

The following example hides the keyboard.

```yaml
- hideKeyboard
```

{% hint style="info" %}
This command is a no-op on web. It has no effect when running web tests.
{% endhint %}

{% hint style="success" %}

#### Update

Maestro has updated the `hideKeyboard` command to verify that the keyboard is actually hidden. If the system fails to dismiss the keyboard, the command will now fail the test.

**This behavior is currently only available on Maestro Cloud.** It will be released to Maestro CLI and Maestro Studio soon.

If your tests start failing after this release, use the [workaround ](/reference/commands-available/hidekeyboard.md#workarounds)described in the documentation.
{% endhint %}

### Implementation details

Unlike other UI actions, mobile operating systems do not provide a native way for closing the keyboard. To achieve this, Maestro simulates the specific gestures or actions a user would perform on each platform:

* **Android**: Maestro triggers a back button event, which is the standard system-level action to dismiss an active keyboard. This is identical to the [back](/reference/commands-available/back.md) command.
* **iOS**: Since iOS does not have a back button, Maestro performs small, quick swipes in the middle of the screen to trigger the system's auto-hide behavior.

### Workarounds

Because the Maestro implementation methods rely on system behaviors rather than direct APIs, they can occasionally be affected by specific app layouts or keyboard types.

If the keyboard doesn't hide, a reliable workaround is to use the `tapOn` command to click a non-tappable element on the screen (such as a header, a title bar, or an empty background area). This mimics how a user might dismiss the keyboard.

```yaml
- tapOn:
    id: "header_title" # Tap on a safe area to force the keyboard down
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/hidekeyboard.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
