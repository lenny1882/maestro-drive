> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available.md).

# Commands available

- [addMedia](https://docs.maestro.dev/reference/commands-available/addmedia.md): Add images or videos to the device gallery for media picker testing.
- [assertNoDefectsWithAI](https://docs.maestro.dev/reference/commands-available/assertnodefectswithai.md): AI-powered visual testing to detect UI defects and anomalies.
- [assertNotVisible](https://docs.maestro.dev/reference/commands-available/assertnotvisible.md): Assert that a UI element is not present or visible on the screen.
- [assertScreenshot](https://docs.maestro.dev/reference/commands-available/assertscreenshot.md): Perform visual regression testing of your application against existing screenshots
- [assertTrue](https://docs.maestro.dev/reference/commands-available/asserttrue.md): Assert that a JavaScript expression evaluates to true.
- [assertVisible](https://docs.maestro.dev/reference/commands-available/assertvisible.md): Assert that a UI element is visible on screen with automatic retry.
- [assertWithAI](https://docs.maestro.dev/reference/commands-available/assertwithai.md): Use AI to verify complex UI states with natural language assertions.
- [back](https://docs.maestro.dev/reference/commands-available/back.md): Press the system back button to navigate to the previous screen.
- [clearKeychain](https://docs.maestro.dev/reference/commands-available/clearkeychain.md): Clear iOS keychain data for the app under test.
- [clearState](https://docs.maestro.dev/reference/commands-available/clearstate.md): Clear app data, cache, and preferences to reset to fresh install state.
- [copyTextFrom](https://docs.maestro.dev/reference/commands-available/copytextfrom.md): Copy text content from a UI element to clipboard or variable.
- [doubleTapOn](https://docs.maestro.dev/reference/commands-available/doubletapon.md): Perform a double-tap gesture on a UI element or screen coordinates.
- [eraseText](https://docs.maestro.dev/reference/commands-available/erasetext.md): Delete text from input fields by character count or clear entirely.
- [evalScript](https://docs.maestro.dev/reference/commands-available/evalscript.md): Evaluate inline JavaScript expressions within the flow context.
- [extendedWaitUntil](https://docs.maestro.dev/reference/commands-available/extendedwaituntil.md): Wait for an element with a custom timeout longer than the default.
- [extractTextWithAI](https://docs.maestro.dev/reference/commands-available/extracttextwithai.md): Extract structured data from the screen using AI vision capabilities.
- [hideKeyboard](https://docs.maestro.dev/reference/commands-available/hidekeyboard.md): Dismiss the on-screen keyboard if currently visible.
- [inputText](https://docs.maestro.dev/reference/commands-available/inputtext.md): Type text into focused input fields with optional keyboard handling.
- [killApp](https://docs.maestro.dev/reference/commands-available/killapp.md): Force stop an app and optionally clear all its data and cache.
- [launchApp](https://docs.maestro.dev/reference/commands-available/launchapp.md): Launch an app with optional permission configuration and clear state.
- [longPressOn](https://docs.maestro.dev/reference/commands-available/longpresson.md): Long press on elements for context menus or drag-and-drop operations.
- [openLink](https://docs.maestro.dev/reference/commands-available/openlink.md): Open a URL or deep link in the app or system browser.
- [pasteText](https://docs.maestro.dev/reference/commands-available/pastetext.md): Paste text from clipboard into the currently focused input field.
- [pressKey](https://docs.maestro.dev/reference/commands-available/presskey.md): Press hardware keys like home, back, enter, or volume buttons.
- [repeat](https://docs.maestro.dev/reference/commands-available/repeat.md): Repeat a block of commands a specified number of times.
- [retry](https://docs.maestro.dev/reference/commands-available/retry.md): Retry a block of commands on failure with configurable attempts.
- [runFlow](https://docs.maestro.dev/reference/commands-available/runflow.md): Execute a subflow file with optional environment variables.
- [runScript](https://docs.maestro.dev/reference/commands-available/runscript.md): Run an external JavaScript file and capture its output.
- [scroll](https://docs.maestro.dev/reference/commands-available/scroll.md): A simple vertical scroll to move down the screen to see the content below
- [scrollUntilVisible](https://docs.maestro.dev/reference/commands-available/scrolluntilvisible.md): Automatically scroll until a target element becomes visible on screen.
- [setAirplaneMode](https://docs.maestro.dev/reference/commands-available/setairplanemode.md): Enable airplane mode to test offline behavior.
- [setClipboard](https://docs.maestro.dev/reference/commands-available/setclipboard.md): Set the device clipboard content to a specified text value.
- [setLocation](https://docs.maestro.dev/reference/commands-available/setlocation.md): Set device GPS location to specific coordinates for location testing.
- [setOrientation](https://docs.maestro.dev/reference/commands-available/setorientation.md): Change device orientation between portrait and landscape modes.
- [setPermissions](https://docs.maestro.dev/reference/commands-available/setpermissions.md): Grant or deny app permissions during flow execution.
- [startRecording](https://docs.maestro.dev/reference/commands-available/startrecording.md): Start recording the screen for video documentation of test runs.
- [stopApp](https://docs.maestro.dev/reference/commands-available/stopapp.md): Stop a running app without clearing its data or state.
- [stopRecording](https://docs.maestro.dev/reference/commands-available/stoprecording.md): Stop the current screen recording and save the video file.
- [swipe](https://docs.maestro.dev/reference/commands-available/swipe.md): Swipe gestures in any direction with customizable speed and distance.
- [takeScreenshot](https://docs.maestro.dev/reference/commands-available/takescreenshot.md): Capture a screenshot and save it to the test output directory.
- [tapOn](https://docs.maestro.dev/reference/commands-available/tapon.md): Tap on UI elements by text, ID, or coordinates with optional repeat and delay.
- [toggleAirplaneMode](https://docs.maestro.dev/reference/commands-available/toggleairplanemode.md): Toggle airplane mode on or off during test execution.
- [travel](https://docs.maestro.dev/reference/commands-available/travel.md): Simulate time travel by adjusting the device system clock.
- [waitForAnimationToEnd](https://docs.maestro.dev/reference/commands-available/waitforanimationtoend.md): Wait for UI animations to complete before proceeding.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
