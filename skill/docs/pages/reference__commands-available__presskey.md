> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/presskey.md).

# pressKey

Press hardware keys like home, back, enter, or volume buttons.

The `pressKey` command simulates pressing a physical or virtual key on a device.

### Syntax

To use the `pressKey` command, you need to define the key to be used:

```yaml
- pressKey: "keyToPress"
```

### Supported keys

The `pressKey` command accepts the following key names as arguments. You can use only one key at a time.

| Key                             | Description                                                   |
| ------------------------------- | ------------------------------------------------------------- |
| `home`                          | Simulates pressing the home button.                           |
| `lock`                          | Simulates pressing the lock button to lock the device screen. |
| `enter`                         | Simulates pressing the enter button.                          |
| `backspace`                     | Simulates pressing the backspace button.                      |
| `volume up`                     | Increases the device volume.                                  |
| `volume down`                   | Decreases the device volume.                                  |
| `back`                          | Simulates pressing the back button. Android only.             |
| `power`                         | Simulates pressing the power button. Android only.            |
| `tab`                           | Simulates pressing the tab button. Android only.              |
| `Remote Dpad Up`                | Android TV remote control key.                                |
| `Remote Dpad Down`              | Android TV remote control key.                                |
| `Remote Dpad Left`              | Android TV remote control key.                                |
| `Remote Dpad Right`             | Android TV remote control key.                                |
| `Remote Dpad Center`            | Android TV remote control key.                                |
| `Remote Media Play Pause`       | Android TV remote control key.                                |
| `Remote Media Stop`             | Android TV remote control key.                                |
| `Remote Media Next`             | Android TV remote control key.                                |
| `Remote Media Previous`         | Android TV remote control key.                                |
| `Remote Media Rewind`           | Android TV remote control key.                                |
| `Remote Media Fast Forward`     | Android TV remote control key.                                |
| `Remote System Navigation Up`   | Android TV remote control key.                                |
| `Remote System Navigation Down` | Android TV remote control key.                                |
| `Remote Button A`               | Android TV remote control key.                                |
| `Remote Button B`               | Android TV remote control key.                                |
| `Remote Menu`                   | Android TV remote control key.                                |
| `TV Input`                      | Android TV remote control key.                                |
| `TV Input HDMI 1`               | Android TV remote control key.                                |
| `TV Input HDMI 2`               | Android TV remote control key.                                |
| `TV Input HDMI 3`               | Android TV remote control key.                                |


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/presskey.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
