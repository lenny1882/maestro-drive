> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/real-world-examples/automate-android-contacts-flow.md).

# Automate Android Contacts Flow

Testing how your app interacts with system contacts, or simply testing the native Contacts app itself, is a great way to explore Maestro's ability to handle system-level applications. This recipe demonstrates how to create a new contact from scratch, utilizing Maestro's built-in data generation to ensure every test run is unique.

{% embed url="<https://player.vimeo.com/video/779079600?h=0b1fec8f26>" %}

### The Workflow

Since you will be interacting with a system app, the Flow focuses on navigating on the standard Android UI patterns and handling keyboard states.

1. Launch the target the native Android contacts package.
2. Use Maestro built-in commands to create realistic names, phone numbers, and emails on the fly.
3. Use the `back` command to dismiss the soft keyboard when it obstructs the view of subsequent input fields.
4. Save the contact to the device database.

#### **1. Contacts Flow**

This Flow interacts with the default Google Contacts app available on Android emulators. Create a YAML file in your testing directory and use the following code to define the Flow:

```yaml
# contacts.yaml
appId: com.android.contacts
---
- launchApp

# Start the creation process
- tapOn: "Create new contact"

# Maestro generates a realistic first name automatically
- tapOn: "First name"
- inputRandomPersonName

- tapOn: "Last name"
- inputRandomPersonName

- tapOn: "Phone"
- inputRandomNumber:
    length: 10

# The keyboard often covers the 'Email' field. 
# We use 'hideKeyboard' to dismiss it safely.
- hideKeyboard

- tapOn: "Email"
- inputRandomEmail

# Finalize the contact
- tapOn: "Save"
```

The above Flow automates the contact creation, but it is important to understand how it was structured for those starting with Maestro:

* By using `inputRandomPersonName` and `inputRandomEmail`, you avoid duplicate contact errors that would occur if you used hardcoded strings. This makes the test repeatable without needing a manual cleanup after every run.
* One common cause of flaky tests on Android is a soft keyboard covering the next button you need to press. Using the `hideKeyboard` command is a reliable way to hide the keyboard and bring the rest of the form back into view.
* Since system apps are updated by Google, their resource IDs can change. Targeting stable accessibility labels like `"First name"` or `"Save"` makes your Flow more resilient to OS updates.

**2. Implementation**

Depending on your needs, you can run this automation directly or integrate it into a larger test. If you have the[ Maestro CLI](https://docs.maestro.dev/maestro-cli/) installed and an active Android emulator running, you can execute this Flow immediately using the following command in your terminal:

```bash
maestro test contacts.yaml
```

You can also use the `contacts.yaml` as a subflow. In this case, if your app needs to ensure a contact exists before performing an action (like "Invite a Friend"), you can call this file as a subflow from your main test:

```yaml
# invite_friend_test.yaml
appId: com.your.app
---
# Ensure a contact is present in the OS before testing invites
- runFlow: contacts.yaml

# Resume testing your own app
- launchApp
- tapOn: "Invite Friends"
- assertVisible: "Invite"
```

#### Related content

Explore these pages to learn more about the automation patterns used in this recipe:

* [inputText](/reference/commands-available/inputtext.md): See all available random data generators, including addresses and email.
* [Generate synthetic data](/maestro-flows/javascript/generate-synthetic-data.md): Learn how to generate random test data.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/examples/real-world-examples/automate-android-contacts-flow.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
