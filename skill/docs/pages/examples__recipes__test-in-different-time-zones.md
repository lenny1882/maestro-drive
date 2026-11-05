> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/recipes/test-in-different-time-zones.md).

# Test in different time zones (Android)

Change the Android device time zone through the Settings app, by region or by UTC offset, so you can test time-dependent features in any zone.

Features that depend on the time of day, such as delivery windows, opening hours, countdowns, or "today" and "yesterday" labels, can behave differently depending on the user's time zone. A test that passes on your laptop in London can fail on a device that is set to New York, or the other way round.

Locally, an emulator matches your machine timezone by default. In Maestro Cloud, devices start in a fixed zone (see [Default device timezones](/maestro-cloud/environment-configuration/app-locales-and-device-timezones.md#default-device-timezones)). Maestro doesn't drive an app, it drives the whole device, so on Android we can drive a change in the device settings.

{% hint style="warning" %}

#### Android only

The iOS Simulator has no time zone setting. It uses the time zone of the Mac it runs on, so iOS devices on Maestro Cloud are always on Pacific Time.
{% endhint %}

{% hint style="info" %}

#### Credits

This approach was inspired by the team at [GlossGenius](https://glossgenius.com/), who needed to test how their app handles daylight saving time changes.
{% endhint %}

### The workflow

The time zone setting is a few screens deep in Settings, and the picker it opens depends on how the current zone was chosen. The Flows in this recipe handle that for you:

1. Open the Settings app and go to **System** > **Date & time**.
2. Turn off **Set automatically**, so you can pick the time zone yourself.
3. Open the time zone picker and switch it to the mode you need: by region, or by UTC offset.
4. Choose the zone.

Choose a Flow based on what your test needs:

* **By region**, when your app shows local times. The zone follows daylight saving time, just as a user's phone does.
* **By UTC offset**, when you need a fixed offset that doesn't change during the year. The offset list only has whole hours, so you can't use it for zones such as India (GMT+05:30).

Both Flows were tested on Android 14-16 (API 34-36), on local emulators and on Maestro Cloud. Other Android versions may name the screens slightly differently.

#### **1. Set the time zone by region**

`REGION` is the country as Settings lists it, such as `Japan`, `United States`, or `Canada`. `CITY` is the city Settings names for the zone, such as `Los Angeles`, `Toronto`, or `Vancouver`. For a country with more than one time zone, the Flow uses it to pick the zone from a list of cities.

Always pass `REGION` and `CITY` together, even for a country with a single time zone. The Flow ends by checking that the time zone shows `CITY`, such as `Tokyo` for `Japan`.

```yaml
# set_timezone.yaml
appId: com.example.app
env:
  REGION: ${REGION || "United States"}
  CITY: ${CITY || "New York"}
---
- launchApp:
    appId: com.android.settings

- scrollUntilVisible:
    element: "System"
    speed: 80
- tapOn: "System"
- tapOn: "Date & time"

# Turn off the automatic time zone, which greys out the time zone row
- runFlow:
    when:
      visible:
        text: "GMT.*"
        enabled: false
    commands:
      - tapOn: "Set automatically"

# Tap the time zone summary. Tapping "Time zone" would tap the section header.
- tapOn:
    text: "GMT.*"
    enabled: true

# If the current zone was picked by UTC offset, the page shows only "Select UTC offset".
# Switch back to picking by region from the overflow menu.
- runFlow:
    when:
      notVisible: "Region"
    commands:
      - tapOn: "More options"
      - tapOn: "Select by region"

- tapOn: "Region"
- inputText: ${REGION}
- tapOn:
    text: ${REGION}
    id: "android:id/title"

# A single-zone country returns straight to the page with "Region" on it.
# A country with several zones opens a list of cities instead, one per zone.
- runFlow:
    when:
      notVisible: "Region"
    commands:
      - scrollUntilVisible:
          element: ${CITY}
          centerElement: true
      - tapOn: ${CITY}

- assertVisible: "${CITY} \\(GMT.*\\)"
```

#### **2. Set a fixed UTC offset**

`OFFSET` is the entry as the **Select UTC offset** list shows it, such as `GMT-05:00` or `GMT+09:00`.

```yaml
# set_utc_offset.yaml
appId: com.example.app
env:
  OFFSET: ${OFFSET || "GMT-05:00"}
---
- launchApp:
    appId: com.android.settings

- scrollUntilVisible:
    element: "System"
    speed: 80
- tapOn: "System"
- tapOn: "Date & time"

# Turn off the automatic time zone, which greys out the time zone row
- runFlow:
    when:
      visible:
        text: "GMT.*"
        enabled: false
    commands:
      - tapOn: "Set automatically"

# Tap the time zone summary. Tapping "Time zone" would tap the section header.
- tapOn:
    text: "GMT.*"
    enabled: true

# The page opens in whichever mode the current zone was picked with.
# Picked by region: the overflow menu opens the offset list directly.
# Picked by offset: the page has a "Select UTC offset" row that opens it.
- runFlow:
    when:
      visible: "Region"
    commands:
      - tapOn: "More options"
      - tapOn: "Select by UTC offset"
- runFlow:
    when:
      visible:
        text: "Select UTC offset"
    commands:
      - tapOn: "Select UTC offset"

- scrollUntilVisible:
    element: ${OFFSET}
    centerElement: true
- tapOn: ${OFFSET}
```

Interacting with a system app takes a few precautions that your own app's Flows don't need:

* **The time zone row is greyed out until automatic time zone is off.** Rather than reading the state of the **Set automatically** switch, the Flows check whether the row that starts with `GMT` is disabled. This works whatever the switch's position on screen.
* **Settings remembers how the current zone was picked.** A device whose zone was picked by region opens the region picker, and one whose zone was picked by UTC offset opens the offset list. Maestro Cloud Android devices start on UTC, picked by offset. The `when` conditions switch modes through the **More options** menu only when needed, so the same Flow works on a fresh emulator and on Cloud.
* **`speed: 80` makes the first scroll fast.** **System** is near the bottom of Settings. A higher speed makes each swipe so short that Android treats it as a tap and opens whichever row is under it.
* **The offset you see isn't the zone ID.** Picking `GMT-05:00` sets the zone `Etc/GMT+5`, because those IDs reverse the sign. This matters only if you check the zone outside the Settings app, for example with `adb shell getprop persist.sys.timezone`.

#### **3. Implementation**

The time zone is a device setting, so the device keeps it after the test. Set it at the start of every Flow that depends on it, rather than relying on an earlier Flow. Call the Flow as a subflow, then launch your app, so it starts in the new zone:

```yaml
# main_test.yaml
appId: com.example.app
---
- runFlow:
    file: ../utils/set_timezone.yaml
    env:
      REGION: Canada
      CITY: Vancouver
- launchApp
- assertVisible: "Delivery between 9 AM and 11 AM"
```

`launchApp` restarts your app if it was already running, so it reads the new time zone.

To run either Flow on its own, for example to set up a device before a test run:

```bash
maestro test set_timezone.yaml
```

Because `REGION`, `CITY`, and `OFFSET` use the `${NAME || "default"}` form, the Flows use their defaults when run on their own, and the values you pass when you call them from another Flow or with `-e`. A plain value in the subflow's `env` header would replace the values you pass in.

### Related content

Explore these pages to learn more about the concepts used in this recipe:

* [Parameters and constants](/maestro-flows/flow-control-and-logic/parameters-and-constants.md): Learn how default values let a subflow run standalone or as part of a larger suite.
* [Conditions](/maestro-flows/flow-control-and-logic/conditions.md): Review how the `when` parameter lets one Flow cope with different starting states.
* [App locales and device timezones](/maestro-cloud/environment-configuration/app-locales-and-device-timezones.md): Check the default time zones of Maestro Cloud devices.
* [launchApp](/reference/commands-available/launchapp.md): Review the options for starting and restarting your app.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/examples/recipes/test-in-different-time-zones.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
