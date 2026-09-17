> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/recipes/choose-images-from-the-gallery.md).

# Choose images from the gallery

Uploading an image or updating a profile picture is a staple feature in modern mobile apps. However, automating this process is difficult because the "Media Picker" isn't actually part of your app, it’s a system-level component that looks and behaves differently depending on the OS and the specific version of Android or iOS.

While Maestro provides the `addMedia` command to seed the device with images, the act of selecting that media requires navigating a variety of system UIs.

### The workflow

Since the media picker is an external system process, you cannot rely on your app's internal IDs. Instead, you need to target the native elements of the OS. The strategy here is to:

1. Ensure the gallery isn't empty. You can do this by using the [`addMedia`](/reference/commands-available/addmedia.md) command prior to this Flow or by having your test take a picture using the device camera.
2. Trigger the image picker in your app.
3. Use a series of optional taps that target known system IDs for different OS versions.
4. Fall back until a match is found.

#### **1. Reusable selection Flow**

This Flow (e.g., `pick_first_image.yaml`) acts as a universal adapter. It tries to identify the first thumbnail in the gallery by cycling through common IDs used by Google and Apple across various SDK versions.

```yaml
# pick_first_image.yaml
# Requirements: Images must already exist in the device gallery
# Strategy: Attempt platform-specific selectors with 'optional: true'

appId: ${APP_ID}
---
# Step 1: Android Media Selection
# Different Android versions use different underlying file managers.
- runFlow:
    when:
      platform: Android
    commands:
      # Targets the modern Android SDK 33/34 Media Provider
      - tapOn:
          id: 'com.google.android.providers.media.module:id/icon_thumbnail'
          optional: true
      
      # Fallback for older SDK 30 (DocumentsUI) selector
      - tapOn:
          id: 'com.google.android.documentsui:id/thumbnail'
          optional: true

# Step 2: iOS Media Selection
# iOS 18 introduced new grid layouts, while older versions rely on accessibility labels.
- runFlow:
    when:
      platform: iOS
    commands:
      # Targets the new iOS 18 grid layout
      - tapOn:
          id: 'PXGGridLayout-Info'
          index: 0
          optional: true
      
      # Fallback for iOS 17 and below using an accessibility label regex
      - tapOn:
          text: 'Photo, .*'
          index: 0
          optional: true
```

In a standard Maestro test, a failed `tapOn` would stop the execution. However, because we know that an iOS 18 selector will fail on an iOS 17 device, we mark these steps as optional by setting `optional: true`.

Maestro will try each selector in sequence. As soon as it finds a match, it performs the tap and moves forward. If a selector doesn't match, it simply skips to the next one without failing the test. This allows you to write a single, robust Flow that works across a fragmented ecosystem of device versions.

#### **2. Implementation**

To use this in your main test suite, ensure your gallery has content (via `addMedia` or a previous camera action), then invoke the subflow once the picker is open:

```yaml
# main_test.yaml
- tapOn: "Upload Profile Picture"
- runFlow: ../partials/pick_first_image.yaml
```

### Related content

Explore the following documentation pages if you'd like to dive deeper into the commands used in this recipe:

* [addMedia](/reference/commands-available/addmedia.md): Learn how to inject images or videos into the device gallery.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/examples/recipes/choose-images-from-the-gallery.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
