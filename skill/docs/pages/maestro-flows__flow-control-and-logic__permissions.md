> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/permissions.md).

# Permissions

Managing system permissions is a common challenge in mobile test automation. Since OS prompts (like "Allow Camera Access") typically only appear once, your test journey can become inconsistent if the app state isn't reset.

Maestro solves this by allowing you to explicitly configure permissions either at launch or during the Flow, ensuring a predictable environment every time.

### Configure permissions on launch

The easiest way to manage permissions is during the [`launchApp`](/reference/commands-available/launchapp.md) command. By default, Maestro grants all permissions, but you can override this behavior to test specific scenarios.

To customize launch permissions, you need to specify them when calling `launchApp`. The following example denies all permissions but explicitly allows the camera and location:

```yaml
- launchApp:
    permissions:
      all: deny
      camera: allow
      location: allow
```

### Changing permissions mid-flow

Sometimes you need to change permissions while the app is running, for example, to test how your app handles a permission denial or to prepare for a specific feature flow like scanning a QR code. Use the [`setPermissions`](/reference/commands-available/setpermissions.md) command for this purpose.

```yaml
- setPermissions:
    permissions:
      notifications: allow
```

{% hint style="info" %}

#### Browser limitation

Maestro can manage permissions for iOS and Android applications, but it has no control over Chrome’s system permissions.
{% endhint %}

### Available permissions

Maestro uses standardized names to make your Flows cross-platform. For example, using `bluetooth` on Android targets both `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` automatically.

The following table list all permissions available in iOS and Android.

| Permission      | iOS | Android |
| --------------- | --- | ------- |
| `bluetooth`     | ❌   | ✅       |
| `calendar`      | ✅   | ✅       |
| `camera`        | ✅   | ✅       |
| `contacts`      | ✅   | ✅       |
| `health`        | ❌   | ❌       |
| `homekit`       | ✅   | ❌       |
| `location`      | ✅   | ✅       |
| `medialibrary`  | ✅   | ✅       |
| `microphone`    | ✅   | ✅       |
| `motion`        | ✅   | ❌       |
| `notifications` | ✅   | ✅       |
| `phone`         | ❌   | ✅       |
| `photos`        | ✅   | ❌       |
| `reminders`     | ✅   | ❌       |
| `siri`          | ✅   | ❌       |
| `sms`           | ❌   | ✅       |
| `speech`        | ✅   | ❌       |
| `storage`       | ❌   | ✅       |
| `usertracking`  | ✅   | ❌       |

{% hint style="success" %}
To grant all available permissions, use `all: allow` to represent all the permissions that the app can request.
{% endhint %}

#### **Android custom permissions**

If a specific Android permission isn't listed above, you can use the full Android Permission ID. The following example adds the `ADD_VOICEMAIL` permission:

```yaml
- setPermissions:
    permissions:
      com.android.voicemail.permission.ADD_VOICEMAIL: allow
```

{% hint style="info" %}
Note that `all: allow` also covers custom permissions, so you don't need to specify them individually unless you want to deny everything else.
{% endhint %}

#### Android special permissions

Not all permissions are prompted for in the app, like location is. Some require the user to leave the app and grant the permission within the Settings app.

`android.permission.MANAGE_EXTERNAL_STORAGE` permission has been required since Android 12 if an app wished to access files that weren't its own (e.g. file browsers, virus scanners).

Maestro can manage this like other permissions without additional user interaction, acting like an app's "second use" rather than first use. If it's declared in the app's AndroidManifest.xml then it'll be set automatically. If you want fine grained control, do as with custom permissions:

```yaml
- launchApp:
    clearState: true
    permissions:
      android.permission.MANAGE_EXTERNAL_STORAGE: deny
```

### Permission values

You can set permissions to one of the following states:

| Value   | Description                                                                                                                        |
| ------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `allow` | Grants the permission. On iOS, this also automatically dismisses the system prompt.                                                |
| `deny`  | Denies the permission. Android will request permission during the Flow execution if the app requires access to a specific feature. |
| `unset` | Resets the permission state, causing the system to prompt permission requests when running the Flow.                               |

Permission values can come from a variable or a JavaScript expression instead of being hard-coded:

```yaml
appId: com.example.app
env:
  CAMERA_PERMISSION_STATE: deny
---
- launchApp:
    permissions:
      camera: ${CAMERA_PERMISSION_STATE}
```

This lets one Flow cover both the granted and the denied journey, driven by `--env` or by the `env` block of the calling Flow.

{% hint style="info" %}

#### **Push notifications on iOS**

Unlike other permissions, iOS does not grant notification permissions silently. When the app requests permissions, the system prompt appears, and Maestro automatically taps **Allow**.

On Android, the permission is granted silently without a prompt.
{% endhint %}

#### iOS-specific values

iOS supports additional granular values for certain permissions.

| Permission | Value     | Description                                     |
| ---------- | --------- | ----------------------------------------------- |
| `location` | `always`  | Grants **Always Allow** location access.        |
|            | `inuse`   | Grants **While Using the App** location access. |
|            | `never`   | Same as `deny`.                                 |
| `photos`   | `limited` | Grants **Limited Access** to the photo library. |

### Usage examples

#### Deny all permissions

To ensure your app handles permission denied states, start your Flow by denying everything. This forces you to handle the edge cases where a user declines a system permission prompt.

```yaml
- launchApp:
    permissions:
        all: deny
```

#### Deny all but allow specific ones

This is a common pattern for testing specific features in isolation.

```yaml
- launchApp:
    permissions:
        all: deny
        medialibrary: allow
```

### Related resources

* [`launchApp`](/reference/commands-available/launchapp.md): See the full reference for launching apps.
* [`setPermissions`](/reference/commands-available/setpermissions.md): Command for altering permissions configuration mid-flow.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/permissions.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
