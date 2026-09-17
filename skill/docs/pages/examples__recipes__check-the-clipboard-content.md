> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/recipes/check-the-clipboard-content.md).

# Check the clipboard content

One of the trickiest things to test in mobile automation is the system clipboard. While Maestro provides built-in `copyTextFrom` and `pasteText` commands, these use a shim, a simulated clipboard designed for speed.

But what if you need to verify that your "Copy to Clipboard" button actually worked at the OS level? Maybe you're building a banking app and need to ensure a BIC code was copied correctly, or a social app sharing a referral link. In these cases, we need to leak out of the app sandbox and use the phone's native UI as a testing ground.

{% hint style="info" %}

#### Credits

This approach was pioneered by the team at [GlossGenius](https://glossgenius.com/) to solve real-world clipboard validation challenges.
{% endhint %}

### The workflow

Since Maestro can't read the OS clipboard directly into a variable, we can test the clipboard's contents in a text field that's available out-of-the-box on every device:

1. Access the Home Screen.
2. Open the System Search bar (Spotlight on iOS, Google Search on Android).
3. Paste the contents there.
4. Use Maestro's `assertVisible`  command to check if the text appeared.

#### 1. Reusable validation Flow

To start, create a Flow (e.g., `check_clipboard.yaml`) that handles the platform-specific logic of pasting into a system search field. The `runFlow` command combined with the `when` condition is used to handle the differences between how iOS and Android manage their search widgets.

```yaml
# check_clipboard.yaml
# Requirements: iOS 18 Simulator / Android API 34 Emulator
# Required Env: EXPECTED_CONTENTS (The string you expect to be in the clipboard)

appId: ${APP_ID}
---
# Step 1: Minimize the app. This is like the user pressing the Home button.
- pressKey: Home

# Step 2: Find a place to "write" the clipboard contents. 
# Here, the platform's native search bar is used.
- runFlow:
    when:
      platform: Android
    commands:
      - tapOn: Search           # Targets the Home screen widget
      - tapOn: 
          id: input             # Focus search input
      - longPressOn: 
          id: input 
      - tapOn: Paste

- runFlow:
    when:
      platform: iOS
    commands:
      - pressKey: Home          # Second tap ensures we are on the first home screen page
      - tapOn: Search           # Targets the iOS search "pill"
      - longPressOn: 
          id: SpotlightSearchField 
      - tapOn: Paste

# Step 3: Assertion
# Check if the OS-level search field now contains the expected text
- assertVisible: ${EXPECTED_CONTENTS}

# Step 4: Cleanup
# Explicitly clear the search field and set the clipboard to a known dummy value to ensure test isolation
- runFlow:
    when:
      platform: Android
    commands:
      - tapOn: Clear search box
      - inputText: Hello World
      - longPressOn: 
          id: input 
      - tapOn: Select all
      - tapOn: Cut

- runFlow:
    when:
      platform: iOS
    commands:
      - tapOn: Clear text
      - inputText: Hello World
      - longPressOn: 
          id: SpotlightSearchField 
      - tapOn: Select All
      - tapOn: Cut

# Step 5: Return to App
- launchApp:
    stopApp: false  # Brings the app back to the foreground without restarting it
```

By navigating to the Home Screen, you gain access to system-level elements that aren't available while your app is focused. Using IDs like `SpotlightSearchField` allows you to interact with the OS search bar reliably.&#x20;

It is important to note that, unlike most tests where `launchApp` starts the app from the beginning, in this subflow you set `stopApp: false`. As a result, Maestro simply brings the app back into focus. The user session remains exactly where it was before the Home button was pressed, allowing the test to continue seamlessly.

#### 2. Implementation

To use the `check_clipboard.yaml` Flow in your main test, you need to pass `EXPECTED_CONTENTS` as an environment variable. After saving the partial, you can invoke it with a single command by specifying the text you expect to find in the clipboard:

```yaml
# main_test.yaml
- runFlow:
    file: ../partials/check_clipboard.yaml
    env:
      EXPECTED_CONTENTS: Maestro
```

### Related content

Explore the following documentation pages if some of the concepts used in this example are not clear to you:

* [Nested flows](/maestro-flows/flow-control-and-logic/nested-flows.md): Learn how to organize your tests by breaking them into smaller Flows.
* [Conditions](/maestro-flows/flow-control-and-logic/conditions.md): Take a closer look at how the `when` parameter allows you to write a single test that works across both iOS and Android.
* [runFlow](/reference/commands-available/runflow.md): Review the details on how to use the `runFlow` command.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/examples/recipes/check-the-clipboard-content.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
