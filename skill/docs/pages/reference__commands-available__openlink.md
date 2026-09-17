> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/openlink.md).

# openLink

Opens a URL or deep link on the target device.

### Arguments

The `openLink` command accepts either a single string value for the link or the following key-value pairs:

| Key          | Description                                                                                                                                                                                                                   |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `link`       | **Required.** The URL or custom protocol link to open, such as `https://example.com` or `awesomeapp://settings`.                                                                                                              |
| `autoVerify` | **Android only.** If `true`, attempts to auto-verify your app to handle the web link, bypassing the app disambiguation dialog. On Android 12 and higher, this flag also auto-accepts Google Chrome agreements if they appear. |
| `browser`    | **Android only.** If `true`, forces the web link to open in Google Chrome.                                                                                                                                                    |

### Usage examples

To open a simple web link, use the shorthand approach, providing the link:

```yaml
- openLink: https://example.com
```

You can also open a deeplink with a custom protocol:

```yaml
- openLink:
    link: awesomeapp://settings
```

#### Android

If you are using Android, you can force the link to open in the browser by using the `browser: true` argument.

```yaml
- openLink: 
    link: https://example.com
    browser: true
```

### Platform-specific behavior

When using `openLink` for testing on Android or iOS, you need to pay attention to the specific behaviors of each operating system.

#### Android app verification

When you open a web link that your app can handle, Android may show a disambiguation dialog asking the user which app to use.

<figure><img src="/files/utx4lmgXM6iIbX0j083f" alt="" width="375"><figcaption></figcaption></figure>

To bypass this dialog, set the `autoVerify` argument to `true` :&#x20;

```yaml
- openLink: 
    link: https://example.com
    autoVerify: true
```

On Android 12 and higher, web links open in a web browser by default. The `autoVerify` flag can also handle the initial Google Chrome agreements if they are shown.

#### iOS security confirmation

On some iOS versions, the operating system shows a security confirmation dialog the first time an app is launched from a deep link.

<figure><img src="/files/XvGvixmRa2fcxytx9m16" alt="" width="232"><figcaption></figcaption></figure>

Accepting this prompt is a permanent choice for that Simulator and is not affected by clearing app state.&#x20;

You may need to account for this dialog in your Flow. The following example uses a conditional `runFlow` to tap the **Open** button if the security dialog appears.

```yaml
- openLink:
    link: awesomeapp://settings
- runFlow:
    when:
      visible: 'Open in "Awesome App"'
    commands:
      - tapOn: Open
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/openlink.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
