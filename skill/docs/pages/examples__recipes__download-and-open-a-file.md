> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/recipes/download-and-open-a-file.md).

# Download and open a file

Automating file downloads is a common requirement, but it can be a headache to test across different platforms. Between varying system dialogs, download confirmations, and the way different OS versions handle file associations, a simple tap and open often requires more nuance than it seems.

This recipe demonstrates how to trigger a file download (using a PDF as an example), navigate the various system prompts that appear on Android and iOS, verify the file's content, and return safely to your application.

### The workflow

Because file handling is managed by the operating system's file manager or a system PDF viewer, your test needs to bridge the gap between your app and the system UI.

1. Initiate the action within your app.
2. Manage "Download again" prompts or location confirmations.
3. Ensure the file opens in the system viewer and check for specific text.
4. Close the viewer to resume the test in your app.

#### **1. Download and verify the file**

This recipe assumes your app has a button titled `'Maestro PDF'` that triggers the download of a document containing the text `"This is a Maestro test"`.

```yaml
# Step 1: Trigger the download in your app
- tapOn: 'Maestro PDF'

# Step 2: Handle "Stale" Files
# On local emulators, the file might exist from a previous run. 
# We use 'optional: true' to skip this if the prompt doesn't appear.
- tapOn:
    text: 'Download again'
    optional: true

# Step 3: Handle Android-specific download confirmations
# Some Android versions (SDK 33/34) ask for location confirmation 
# or show a "File downloaded" snackbar before opening.
- runFlow:
    when:
      visible: 'Choose where to download'
    commands:
      - tapOn: 'Download'

- runFlow:
    when:
      # If the PDF hasn't automatically opened yet, find the 'Open' button
      notVisible: 'This is a Maestro test.*'
    commands:
      - assertVisible: 'File downloaded'
      - tapOn: 'Open'

# Step 4: Verify the PDF Content
# Once the system PDF viewer is open, we assert that the text is visible.
- assertVisible: 'This is a Maestro test.*'

# Step 5: Return to the App
# We close the system viewer to return to the application state.
- runFlow:
    when:
      platform: Android
    commands:
      - back
- runFlow:
    when:
      platform: iOS
    commands:
      - tapOn: 'Done'
```

To ensure the file contents are reliably detected, this recipe uses a regular expression in the assertion (`This is a Maestro test.*`). This approach accounts for the fact that PDF viewers may render text with invisible characters or trailing spaces. Using a regular expression makes the assertion more resilient to minor rendering differences.

Additionally, there are two other important points to consider. On older Android versions, the system may open the PDF viewer immediately after the download completes. On newer versions (SDK 33+), however, the user is often left at a **File downloaded** notification instead. By first checking that the content is `notVisible`, the test attempts to tap **Open** only when the operating system has not already done so.

Finally, the `optional: true` flag on the **Download again** step is essential for CI/CD environments. On a fresh cloud instance, this prompt will never appear, and this flag prevents the test from failing when it doesn't show up.

#### 2. Implementation

To use this logic in your test, you can incorporate it directly into your main Flow or save it as a reusable subflow. Since it relies on system-level text, no extra environment variables are needed unless you want to parameterize the expected text.

```yaml
# main_test.yaml
- tapOn: 'Reports'
- runFlow: ../partials/download_and_verify_pdf.yaml
```

### Related content

Explore these pages to learn more about the logic used to navigate system boundaries:

* [Selectors](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md): Learn how to use selectors to make your text assertions more flexible.
* [Conditions](/maestro-flows/flow-control-and-logic/conditions.md): See how to use `visible` and `notVisible` to handle branching UI logic.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/examples/recipes/download-and-open-a-file.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
