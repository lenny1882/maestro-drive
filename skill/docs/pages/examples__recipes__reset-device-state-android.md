> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/recipes/reset-device-state-android.md).

# Reset device state (Android)

Successive test runs that use `addMedia` to import photos or download files can leave your Android emulator in an inconsistent state. Stale files from a previous execution can lead to false positive results, where a test succeeds only because data from a prior run was still present, or failures because existing clutter prevents Maestro from finding the specific file you just added.

To ensure a truly clean slate, you can automate the system Files app to purge these directories before or after your test suite runs.

{% hint style="info" %}

#### **Credits**

This recipe was shared by [AJ Owens](https://www.linkedin.com/in/owensaj/), a member of the [Maestro Slack community](https://slack.maestro.dev/), to solve the problem of persistent media on shared emulator instances.
{% endhint %}

### The workflow

Since these files exist outside your app's sandbox, you need to interact directly with the Android Files app (the default file manager on Google APIs emulators). The logic follows a "locate and destroy" pattern:

1. Exit the app and open the Android App Drawer to launch the Files app.
2. Use the hamburger menu to jump directly to Images or Downloads.
3. Evaluate if the file manager shows that thumbnails are actually present.
4. Use the system **Select all** and **Delete** commands to clear the entire directory in one action.

#### **1. Cleanup Flow**

This Flow is designed to work on Android API 30 through 34. You can run this as a standalone Flow or call it as a subflow.

```yaml
# clean_device_android.yaml
# Strategy: Use the native Files app to remove Images and Downloads.

# Step 1: Launch the Files app
- pressKey: home
- swipe:
    direction: UP
- tapOn: Files

# Step 2: Delete images
- tapOn: Show roots      # The hamburger menu
- tapOn:
    text: Images
    index: 1             # Skips the filter chip on the main page
- tapOn: Pictures

# Step 3: Conditional cleanup
# Only proceed if thumbnails (icon_thumb) are visible.
- runFlow:
    when:
      visible:
        id: "com.google.android.documentsui:id/icon_thumb"
    commands:
      - tapOn: More options
      - tapOn: Select all
      - tapOn: Delete
      - tapOn: OK

# Step 4: Delete downloads
- tapOn: Show roots
- tapOn: Downloads

- runFlow:
    when:
      visible:
        id: "com.google.android.documentsui:id/icon_thumb"
    commands:
      - tapOn: More options
      - tapOn: Select all
      - tapOn: Delete
      - tapOn: OK
```

Interacting with a system app requires targeting resource IDs that are not part of your application’s source code. The cleanup flow is structured this way for the following reasons:

* It uses IDs from the `com.android.documentsui` package (the native Files app) instead of text to ensure stability across different Android versions.
* By first checking the visibility of `id: icon_thumb`, the test executes more efficiently. If the folder is already empty, Maestro avoids searching for a **Select all** button that does not exist.
* Rather than deleting files individually, which is slow, it relies on the native **Select all** action.&#x20;

#### **2. Implementation**

Because this flow interacts with the OS, it doesn't need to be part of your app's primary navigation. You can run it once at the start of your CI pipeline to ensure a fresh environment:

```bash
maestro test clean_device_android.yaml
```

Alternatively, call it as a subflow in your main test to clear specific media after a download test completes, or automate this cleanup by calling it within a [Hook](/maestro-flows/flow-control-and-logic/hooks.md), adding it to `onFlowComplete` ensures your app is in a "neutral" state for the next test:

{% tabs %}
{% tab title="Subflow" %}

```yaml
# main_test.yaml
- tapOn: "Download Report"
- assertVisible: "Report.pdf"
# Cleanup after ourselves
- runFlow: ../utils/clean_device_android.yaml
```

{% endtab %}

{% tab title="Hook" %}

```yaml
onFlowComplete:
  runFlow: ../utils/clean_device_android.yaml
---
# Your Flow
```

{% endtab %}
{% endtabs %}

#### Related content

Explore these pages to learn more about the commands used to manage files and system navigation:

* [Conditions](/maestro-flows/flow-control-and-logic/conditions.md): Review how to use the `when` parameter to make your cleanup logic skip unnecessary steps.
* [Hooks](/maestro-flows/flow-control-and-logic/hooks.md): Learn how to automatically trigger this cleanup flow before or after every test run.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/examples/recipes/reset-device-state-android.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
