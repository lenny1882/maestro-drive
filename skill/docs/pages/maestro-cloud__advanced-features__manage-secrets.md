> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/advanced-features/manage-secrets.md).

# Manage secrets

Pass sensitive parameters like usernames and passwords to Maestro Cloud tests via environment variables using the -e CLI option.

Avoid storing sensitive values directly in your Flow files. Maestro allows you to pass parameters as environment variables during execution.

{% hint style="info" %}
**Maestro Cloud Plan required** Secret management via environment variables is available on the [Maestro Cloud Plan](https://maestro.dev/cloud).
{% endhint %}

### Define environment variables

You can provide environment variables using the Maestro CLI or through CI integrations like GitHub Actions.

{% tabs %}
{% tab title="Maestro CLI" %}
Use the `-e` option to pass parameters as key-value pairs:

```bash
maestro cloud \
  --api-key "<YOUR_API_KEY>" \
  --project-id "<YOUR_PROJECT_ID>" \
  -e USERNAME=$TEST_USERNAME \
  -e PASSWORD=$TEST_PASSWORD \
  --app-file "<APP_FILE>" \
  --flows "<FLOW_OR_FOLDER>"
```

{% endtab %}

{% tab title="GitHub Action" %}
You can provide parameters in the multiline `env` field of the GitHub Action:

```yaml
- uses: mobile-dev-inc/action-maestro-cloud@v1
  with:
    api-key: ${{ secrets.MOBILE_DEV_API_KEY }}
    app-file: <path to APK or iOS Simulator build>
    env: |
        USERNAME=${{ secrets.TEST_USERNAME }}
        PASSWORD=${{ secrets.TEST_PASSWORD }}
```

{% endtab %}
{% endtabs %}

{% hint style="info" %}
For more information about how to use parameters and constants in your Flow, access the [documentation](/maestro-flows/flow-control-and-logic/parameters-and-constants.md).
{% endhint %}

### Use variables in your Flows

Once defined, reference these variables in your Flow files using the `${VARIABLE_NAME}` syntax:

```yaml
appId: com.example.app
---
- launchApp
- inputText: ${USERNAME}
- tapOn: Next
- inputText: ${PASSWORD}
- tapOn: Login
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-cloud/advanced-features/manage-secrets.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
