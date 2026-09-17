> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-studio/run-tests-with-maestro-studio.md).

# Run tests with Maestro Studio

Maestro Studio is a visual desktop app that simplifies mobile test automation. This guide covers how to install the application and use its interactive tools to build a contact creation test without writing any code.

### Prerequisites&#x20;

Before building your test, ensure you have a running Android emulator. Access the [QuickStart](/get-started/quickstart.md) for further guidance on setting up your virtual environment.&#x20;

{% stepper %}
{% step %}

### Installation

Get started by downloading the installer for your specific operating system:

* **Windows**: Download [MaestroStudio.exe](https://studio.maestro.dev/MaestroStudio.exe) and follow the setup wizard.
* **macOS**: Download [MaestroStudio.dmg](https://studio.maestro.dev/MaestroStudio.dmg) and drag the icon into your Applications folder.
* **Linux**: Download [MaestroStudio.AppImage](https://studio.maestro.dev/MaestroStudio.AppImage), make it executable with `chmod +x`, and run it.
  {% endstep %}

{% step %}

### Initial setup

1. Launch Maestro Studio.
2. Click **New workspace** to select a folder on your machine where your test files will be saved.&#x20;

<figure><img src="/files/g5Uwc6PH0SdffJyZAOVk" alt=""><figcaption></figcaption></figure>

3. Click on **Select device** at the top left and select your active virtual device from the list.

<figure><img src="/files/bHD9s3EDSdyUJtMNijU9" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}

### Create the test file

1. Click **New File.**
2. Enter a name for your test file, for example `my_test.yaml`.
3. Select your app from the dropdown menu.
4. Click **Create Test**.

{% hint style="info" %}
Tags are used to control which tests run. For more information, access the following pages:

* [Environments and variables](/maestro-studio/environments-and-variables.md)
* [Run cloud tests from Maestro Studio](/maestro-studio/run-cloud-tests-from-maestro-studio.md)
  {% endhint %}

<figure><img src="/files/zXalM9wIfUrBgYJuqjeQ" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}

### Test the app initialization

Before you begin building the test, run the app initialization. Click **Run Test** and observe the app initializing with a clear state.

<figure><img src="/files/8KR3M3SbLyxWxUPXPeWU" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}

### Build your test

The fastest way to build a test is to **right-click directly on any element** in your app. A menu appears with the available Maestro commands for that element. Click the one you want, and it gets added to your test automatically.

<figure><img src="/files/8jObHZdZpaKEiSJM4MYj" alt=""><figcaption></figcaption></figure>

You can also type a hyphen in the editor to see all available Maestro commands.

<figure><img src="/files/OdXX5Bk0sAu4H8oS1g6p" alt=""><figcaption></figcaption></figure>

Autocomplete suggests commands, arguments, and real selectors from your connected device's screen, so you spend less time looking up syntax.

<figure><img src="/files/MiZjSViQ2T6ih5xeXLHo" alt=""><figcaption></figcaption></figure>

{% endstep %}

{% step %}

### Review and run the test

Once your first test is ready, click **Run Test** to watch Maestro Studio execute these steps automatically on your device.

<figure><img src="/files/pMMU5gjW1tirxc86NHGi" alt=""><figcaption></figcaption></figure>

After a successful run, the recording file will be available in the `.maestro` directory.
{% endstep %}
{% endstepper %}

### Next steps

Now that you have created a test using the interactive features of Maestro Studio, you can explore more advanced capabilities:

* [Environments and variables](/maestro-studio/environments-and-variables.md): Learn how to pass dynamic data like names or phone numbers using variables.
* [Run cloud tests from Maestro Studio](/maestro-studio/run-cloud-tests-from-maestro-studio.md): Learn how to execute this test on using Maestro Cloud.

To learn more about test structure and advanced logic, visit the [Maestro Flows documentation](/maestro-flows/readme.md).


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-studio/run-tests-with-maestro-studio.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
