> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-studio/run-tests-with-maestro-studio.md).

# Run tests with Maestro Studio

Build and run mobile tests visually with Maestro Studio. Install the app, create tests via screen inspection, and automate without writing code from scratch.

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

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2FBN8g0L5dTQ0eKrBI31mA%2Fcreate%20workspace.gif?alt=media&amp;token=68d8f333-426b-4d48-8b5f-be0f8a7eefda" alt=""><figcaption></figcaption></figure>

3. Click on **Select device** at the top left and select your active virtual device from the list.

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2FaXzY1dFDIZyqGbRfrK88%2Fconnect%20device.gif?alt=media&amp;token=72a3b8f5-8459-4a8e-963c-95b2d63dc3f3" alt=""><figcaption></figcaption></figure>
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

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2Fhef0h8dd4YQ97Npcp88p%2Fcreate%20new%20file.gif?alt=media&amp;token=5338005a-6bc7-46f4-b122-66c09cb3874b" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}

### Test the app initialization

Before you begin building the test, run the app initialization. Click **Run Test** and observe the app initializing with a clear state.

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2FwZP56oJ9Y1dwi9RQHvPX%2Frun%20test_launch%20app.gif?alt=media&amp;token=2ec2d423-b922-4072-8efe-ae0742b79970" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}

### Build your test

The fastest way to build a test is to **right-click directly on any element** in your app. A menu appears with the available Maestro commands for that element. Click the one you want, and it gets added to your test automatically.

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2FLamKKFRnt9FSoRIhASsa%2Ftest%20creation_1.gif?alt=media&amp;token=3c323655-8d96-4aef-a237-1d3dee9d8f21" alt=""><figcaption></figcaption></figure>

You can also type a hyphen in the editor to see all available Maestro commands.

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2Fadb3frgjzmjLaEKUlzLM%2Ftest__2.gif?alt=media&amp;token=cd8c5b9d-3641-4e83-aa85-013f8626a1c3" alt=""><figcaption></figcaption></figure>

Autocomplete suggests commands, arguments, and real selectors from your connected device's screen, so you spend less time looking up syntax.

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2FTLiV8zQehmwVC42geHdS%2Ftest__4.gif?alt=media&amp;token=66ea0de9-e1f3-405a-a0bb-fd2729358408" alt=""><figcaption></figcaption></figure>

{% endstep %}

{% step %}

### Review and run the test

Once your first test is ready, click **Run Test** to watch Maestro Studio execute these steps automatically on your device.

<figure><img src="https://173198800-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FeQi66gxHTt2vx4HjhM9V%2Fuploads%2FV0CdgYTbExCkHzi1OCGm%2Frun.gif?alt=media&amp;token=b125afcd-13d9-4490-8cde-0a32bf5ba6f7" alt=""><figcaption></figcaption></figure>

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
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-studio/run-tests-with-maestro-studio.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
