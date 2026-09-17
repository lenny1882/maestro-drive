> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cli/run-your-first-test-with-the-maestro-cli.md).

# Run your first test with the Maestro CLI

In this tutorial, you will write and execute your first Maestro Flow using the CLI. You will create a test that automates the process of adding a new contact to an Android device using the native Contacts app.

### Prerequisites

Ensure you have the following ready before starting:

* **Maestro CLI**: Installed and configured on your local machine. If not yet installed, follow the [How to install Maestro CLI](/maestro-cli/how-to-install-maestro-cli.md) guide.
* **Android Studio**: Used to manage and launch virtual devices. See the [QuickStart](/get-started/quickstart.md) guide.

{% stepper %}
{% step %}

### Start the Android emulator

Maestro requires an active device or emulator to interact with the application UI. This example uses Android Emulator to run an emulated Android device:

1. Open **Android Studio**.
2. Navigate to the **Virtual Device Manager**.
3. Launch a virtual device (e.g., Pixel 8 or similar).
4. Wait for the device to appear in your home screen.

<figure><img src="/files/jzLBBSDznaeTvYSxKQDJ" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}

### Create the Flow file

A Flow is a YAML file containing the commands Maestro executes. For this tutorial, we will use the system's default Contacts app (`com.google.android.contacts`), which is pre-installed on standard Android emulators:

1. Create a new directory for your test and navigate into it.
2. Create a file named `contacts.yaml`.
3. Copy and paste the following content:

```yaml
appId: com.google.android.contacts
---
- launchApp:
    clearState: true              # Resets the app to a fresh state before starting
- startRecording: recording       # Starts capturing a video of the execution
- tapOn: "Allow"                  # Handles system permission dialog if it appears
- tapOn: Create contact
- tapOn: First name
- inputText: John
- tapOn: Last name
- inputText: Doe
- tapOn: Company
- inputText: Maestro
- tapOn: "+1"
- inputText: 111-111-1111
- tapOn: Save
- back                            # Returns to the main contact list
- stopRecording                   # Saves the video file
```

{% hint style="info" %}
If you don't know to create and structure Flows, access the [specific documentation](/maestro-flows/readme.md).
{% endhint %}

{% hint style="info" %}

#### Download and use Maestro samples

The Maestro CLI provides the `download-samples` command, which lets you download a curated collection of Flow files to help you learn Maestro. Use these samples to explore examples and understand how different Maestro features work in practice.

To use this command, run `maestro doenload-samples`.
{% endhint %}
{% endstep %}

{% step %}

### Run the Flow

With the emulator running and your YAML file ready, you can now execute the test:

1. Open your terminal.
2. Run the following command:

```bash
maestro test contacts.yaml
```

{% hint style="info" %}

### CLI options and commands

To see all the options and commands available when using the Maestro CLI, [access the Maestro CLI documentation](/maestro-cli/maestro-cli-commands-and-options.md).
{% endhint %}

{% hint style="success" %}

#### Troubleshooting: Connection timeouts

If your CI runner fails to start the Maestro driver within the default timeframe, you may see a timeout error.

The default timeout is 15 seconds (15000 ms) for Android and 120 seconds (120000 ms) for iOS.

You can extend this by setting a custom millisecond value in your pipeline environment. Here's an example to increase the timeout to 3 minutes (180000 ms):

```bash
export MAESTRO_DRIVER_STARTUP_TIMEOUT=180000
```

{% endhint %}

Maestro will connect to the emulator and execute the steps sequentially. You will see a live progress report in your terminal.

<figure><img src="/files/VHQP2sO4vbmFe6aUtmgV" alt=""><figcaption></figcaption></figure>

{% hint style="info" %}

#### What happens during execution:

1. Maestro begins capturing the screen.
2. The Contacts app opens and resets any existing state.
3. Maestro identifies fields by their text or accessibility labels and inputs names and phone numbers.
4. The contact is saved, and the app navigates back to the list view.
5. The recording stops, and a file named `recording.mp4` is saved to your directory.
   {% endhint %}
   {% endstep %}
   {% endstepper %}

### Final Outcome

Once the test completes, check your folder for the `recording.mp4` file. It should display the automated process exactly as seen in the example below:

<figure><img src="/files/g5psPJnspxsL9jR31jZi" alt=""><figcaption></figcaption></figure>

### Next steps

Now that you have executed your first Flow, you are ready to explore the deeper capabilities of Maestro:

* [Flows](/maestro-flows/flow-control-and-logic/flow-control-and-logic-overview.md): Learn how to build resilient, intelligent journeys by utilizing modular subflows, conditional execution, and repetitive loops to handle complex app states.
* [Selectors](/maestro-flows/flow-control-and-logic/how-to-use-selectors.md): Learn how Maestro identify UI elements when testing your app.
* [JavaScript](/maestro-flows/javascript/javascript-overview.md): Learn how to use JavaScript to extend your YAML logic.
* [Workspace management](/maestro-flows/workspace-management/workspace-management-overview.md): Learn how to organize your test suite for larger projects.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cli/run-your-first-test-with-the-maestro-cli.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
