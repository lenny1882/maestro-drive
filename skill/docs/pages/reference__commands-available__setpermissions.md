> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/setpermissions.md).

# setPermissions

Grant or deny app permissions during flow execution.

The `setPermissions` command configures permissions for an application. While the `launchApp` command performs this action by default, you can use `setPermissions` at other points in a flow, such as before a deeplink.

{% hint style="info" %}
`setPermissions` is available on Android and iOS.

Maestro has no control over Chrome’s permissions.
{% endhint %}

### Parameters

| Parameter     | Description                                                                                                                                                    |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `permissions` | A map of permissions to set. The key is the permission name, and the value is either `allow` or `deny`. Use the `all` key to apply a state to all permissions. |
| `appId`       | **(Optional)** The ID of the app to target. Defaults to the app under test.                                                                                    |

All parameters can be set via a variable or a JavaScript expression.

### Usage examples

The following examples demonstrate how to use the `setPermissions` command.

#### Grant all permissions

This example grants all permissions to the app under test.

```yaml
- setPermissions:
    permissions:
      all: allow
```

#### Set specific permissions for another app

This example sets the `camera` permission to `allow` and the `notifications` permission to `deny` for the app with the ID `com.example.app`.

```yaml
- setPermissions:
    appId: com.example.app
    permissions:
      camera: allow
      notifications: deny
```

#### Set a permission from a variable

Permission values are interpolated, so you can drive them from a parameter or an environment variable and run the same Flow for both the granted and denied cases.

```yaml
appId: com.example.app
env:
  CAMERA_STATE: allow
---
- setPermissions:
    permissions:
      camera: ${CAMERA_STATE}
```

### Related content

Learn how to use [permissions](/maestro-flows/flow-control-and-logic/permissions.md) on iOS and Android apps on flows.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/setpermissions.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
