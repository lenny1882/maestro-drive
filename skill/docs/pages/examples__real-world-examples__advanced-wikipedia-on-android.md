> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/real-world-examples/advanced-wikipedia-on-android.md).

# Advanced: Wikipedia on Android

This guide demonstrates how to use Maestro to automate complex user journeys in the Wikipedia Android app. You will learn how to manage multi-step onboarding, interact with dynamic feeds using scrolling, and integrate JavaScript for data-driven testing.

### Prerequisites

Before starting, ensure you have the project files and the app ready:

1. **Install Maestro CLI**: Follow the [installation guide](/maestro-cli/how-to-install-maestro-cli.md).
2. **Download Samples**: Run `maestro download-samples` to fetch the source code and the `wikipedia.apk`.
3. **Navigate to Project**: Open your terminal and enter the directory after download the samples (`cd wikipedia-android-advanced`).

### Project Structure

The project is [organized into subflows](/maestro-flows/flow-control-and-logic/nested-flows.md) to ensure maintainability and reusability across different test suites:

```
├── run-test.yml           # Root test suite orchestrator
├── onboarding/            # App initialization flows
├── dashboard/             # Feed and navigation flows
├── auth/                  # Login and signup flows
└── scripts/               # JavaScript for dynamic data generation
```

### 1. Onboarding Flow

The onboarding subflow handles the initial setup of the application. By using `clearState: true`, the test ensures a fresh installation state, which is critical for verifying that new users can navigate the language settings and introductory screens without interference from previous sessions.

{% tabs %}
{% tab title="main.yml" %}
This Flow serves as the entry point for the onboarding sequence. It orchestrates the addition and removal of languages before progressing through the introductory informational screens like "New ways to explore" and "Reading lists".

```yaml
# onboarding/main.yml
appId: org.wikipedia
---
- runFlow: "add-language.yml"
- runFlow: "remove-language.yml"
- tapOn: "Continue"
- assertVisible: "New ways to explore"
- tapOn: "Continue"
- assertVisible: "Reading lists with sync"
- tapOn: "Continue"
- assertVisible: "Send anonymous data"
- tapOn: "Get started"
```

{% endtab %}

{% tab title="add-language.yml" %}
This Flow navigates the language settings menu to search for and add "Greek" to the app's configuration. It concludes by tapping "Navigate up" to return to the previous screen.

```yaml
# onboarding/add-language.yml
appId: org.wikipedia
---
- tapOn: "ADD OR EDIT.*"
- tapOn: "ADD LANGUAGE"
- tapOn:
    id: ".*menu_search_language"
- inputText: "Greek"
- assertVisible: "Ελληνικά"
- tapOn: "Ελληνικά"
- tapOn: "Navigate up"
```

{% endtab %}

{% tab title="remove-language.yml" %}
This Flow verifies the deletion process by selecting the newly added language and removing it. It uses index-based selection and assertions to ensure the UI updates correctly after the deletion.

```yaml
# onboarding/remove-language.yml
appId: org.wikipedia
---
- tapOn: "ADD OR EDIT.*"
- tapOn: "More options"
- tapOn: "Remove language"
- tapOn:
    id: ".*wiki_language_checkbox"
    index: 1
- tapOn:
    id: ".*menu_delete_selected"
- tapOn: "OK"
- assertNotVisible: "Ελληνικά"
- tapOn: "Navigate up"
```

{% endtab %}
{% endtabs %}

{% embed url="<https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FJjfcEdmJ9ojsT3Jtpsi8%2Fuploads%2FVo4wMmQYyyTK2CQUQW2r%2F2026-02-14_20-45-06.mp4?alt=media&token=9b148457-166c-439a-af49-247c9b857c35>" %}

### 2. Dashboard Navigation

The dashboard contains dynamic content that varies daily. These tests illustrate how to interact with elements that are not immediately visible on the screen and how to share data between different views using the system clipboard.

{% tabs %}
{% tab title="main.yaml" %}
This orchestrator Flow for the dashboard sequentially executes tests for searching, checking saved articles, interacting with the feed, and performing copy-paste operations.

```yaml
# dashboard/main.yml
appId: org.wikipedia
---
- runFlow: "search.yml"
- runFlow: "saved.yml"
- runFlow: "feed.yml"
- runFlow: "copy-paste.yml"
```

{% endtab %}

{% tab title="search.yml" %}
This test validates the core search functionality. It enters a query, selects a result based on its resource ID, and saves the article to the user's reading list to be verified in a later flow.

```yaml
# dashboard/search.yml
appId: org.wikipedia
---
- tapOn: "Search Wikipedia"
- inputText: "Sun"
- assertVisible: Star at the centre of the Solar System
- tapOn:
    id: ".*page_list_item_title"
- tapOn:
    id: ".*page_save"
- back
- back
- back
- back
```

{% endtab %}

{% tab title="saved.yml" %}
This flow visits the "Saved" section of the app to ensure that the "Sun" article saved in the search flow is present and displays the correct description.

```yaml
# dashboard/saved.yml
appId: org.wikipedia
---
- tapOn: "Saved"
- tapOn: "Default list for your saved articles"
- assertVisible: "Sun"
- assertVisible: "Star at the centre of the Solar System"
- back
```

{% endtab %}

{% tab title="feed.yaml" %}
This Flow shows how to execute vertical scrolling on the Explore tab. It uses `scrollUntilVisible` to locate the "Today on Wikipedia" section before interacting with it.

```yaml
# dashboard/feed.yml
appId: org.wikipedia
---
- tapOn: "Explore"
- scrollUntilVisible:
    element: "Today on Wikipedia.*"
- tapOn: "Today on Wikipedia.*"
- back
```

{% endtab %}

{% tab title="copy-paste.yml" %}
This Flow captures a title from the feed using `copyTextFrom`. It then navigates to the search bar and uses the `${maestro.copiedText}` variable to paste the captured text as input.

```yaml
# dashboard/copy-paste.yml
appId: org.wikipedia
---
- tapOn: "Explore"
- scrollUntilVisible:
    element: "Top read"
- copyTextFrom:
    id: ".*view_list_card_item_title"
    index: 0
- tapOn: "Explore"
- tapOn: "Search Wikipedia"
- inputText: "${maestro.copiedText}"
- back
- back
- back
```

{% endtab %}
{% endtabs %}

{% embed url="<https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FJjfcEdmJ9ojsT3Jtpsi8%2Fuploads%2FnsQacGnlnOE1bRdhyuNz%2F2026-02-14_20-45-45.mp4?alt=media&token=d203db96-4434-4edb-abfe-e54df2e85330>" %}

### 3. Authentication and scripting

Maestro supports JavaScript execution to handle logic that is difficult to achieve with YAML alone. These examples show how to generate unique registration data and fetch valid test credentials from an external API.

{% tabs %}
{% tab title="signup.yml" %}
This test automates the account creation form by running `generateCredentials.js` to populate the username, password, and email fields with unique data.

```yaml
# auth/signup.yml
appId: org.wikipedia
---
- tapOn: "More"
- tapOn: "LOG IN.*"
- runScript: "../scripts/generateCredentials.js"
- tapOn: "Username"
- inputText: "${output.credentials.username}"
- tapOn: "Password"
- inputText: "${output.credentials.password}"
- tapOn: "Repeat password"
- inputText: "${output.credentials.password}"
- tapOn: "Email.*"
- inputText: "${output.credentials.email}"
- back
- back
```

{% endtab %}

{% tab title="login.yaml" %}
This Flow fetches a real user from an API using `fetchTestUser.js`. It then populates the login form with the retrieved username.

```yaml
# auth/login.yml
appId: org.wikipedia
---
- tapOn: "More"
- tapOn: "LOG IN.*"
- tapOn:
    id: ".*create_account_login_button"
- runScript: "../scripts/fetchTestUser.js"
- tapOn: "Username"
- inputText: "${output.test_user.username}"
- tapOn: "Password"
- inputText: "No provided"
- tapOn: "LOG IN"
- back
- back
```

{% endtab %}

{% tab title="generateCredentials.js" %}
This script creates unique credentials by appending a timestamp to placeholders using `.replace()`. The data is exported via the `output` object.

```javascript
function username() {
  const date = new Date().getTime().toString();
  return `test_user_${date}`;
}

function email() {
  const date = new Date().getTime().toString();
  return `test-user-${date}@test.com`;
}

function password() {
  const date = new Date().getTime().toString();
  return `test-user-password-${date}`;
}

output.credentials = {
  email: email(),
  password: password(),
  username: username(),
};
```

{% endtab %}

{% tab title="fetchTestUsers.js" %}
This script uses [`http.get`](/maestro-flows/javascript/make-http-requests.md) to fetch user data from a placeholder API. It then parses the JSON response to provide a username and email to the Maestro Flow.

```javascript
// Fetches test user from API
function getTestUserFromApi() {
  const url = `https://jsonplaceholder.typicode.com/users/1`;
  var response = http.get(url);
  var data = json(response.body);

  return {
    username: data.username,
    email: data.email,
  };
}

output.test_user = getTestUserFromApi();

```

{% endtab %}
{% endtabs %}

{% embed url="<https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FJjfcEdmJ9ojsT3Jtpsi8%2Fuploads%2FXxBfpgWeGvrWckRkIG4W%2F2026-02-14_20-47-53.mp4?alt=media&token=a1071fd7-924b-41da-8ab3-9a8bc230d85e>" %}

### Running the test

To run the entire end-to-end journey, use the `run-test.yml` file.

```yaml
## run-test.yaml
appId: org.wikipedia
tags:
  - android
  - passing
---
- launchApp:
    clearState: true
- runFlow: "onboarding/main.yml"
- runFlow: "dashboard/main.yml"
- runFlow: "auth/signup.yml"
- runFlow: "auth/login.yml"
```

This Flow ensures that the app is launched in a clean state before executing the onboarding, dashboard navigation, and authentication flows in sequence.

```bash
maestro test run-test.yml
```

{% tabs %}
{% tab title="Maestro CLI" %}
{% embed url="<https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FJjfcEdmJ9ojsT3Jtpsi8%2Fuploads%2FCFvg2bU1j7mF3lXegvw9%2F2026-02-14_20-43-05.mp4?alt=media&token=a9f88ea5-46a1-444d-b2af-9f796f2e30c3>" %}
{% endtab %}

{% tab title="Maestro Studio" %}
{% embed url="<https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FJjfcEdmJ9ojsT3Jtpsi8%2Fuploads%2FyfLmUXpwzfW3xnvM5YrD%2F2026-02-14_20-13-46.mp4?alt=media&token=f26277e2-55ba-4f92-a73b-476cbd5cfeab>" %}
{% endtab %}
{% endtabs %}

### Related content

* [Nested Flows](/maestro-flows/flow-control-and-logic/nested-flows.md): Build modular, reusable tests by embedding existing Flows into complex user journeys.
* [inputText](/reference/commands-available/inputtext.md): Learn how to simulate realistic keyboard entries.
* [Make HTTP requests](/maestro-flows/javascript/make-http-requests.md): Make HTTP API calls from your flows to set up test data or verify backend state.
* [JavaScript overview](/maestro-flows/javascript/javascript-overview.md): Unlock advanced logic and conditional testing power by integrating scripts into your YAML.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/examples/real-world-examples/advanced-wikipedia-on-android.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
