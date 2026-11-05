> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/examples/readme.md).

# Examples overview

Real-world examples and recipes for common Maestro automation scenarios.

This section of the documentation is a curated library of real-world scenarios designed to bridge the gap between basic commands and complex, production-ready automation.

While the core documentation explains how commands work, this section focuses on implementation patterns, solving specific technical hurdles like system-level interactions, dynamic content, and scalable architecture.

### Implementation Recipes

These guides provide targeted solutions for specific technical requirements:

* [Choose images from the gallery](/examples/recipes/choose-images-from-the-gallery.md): Learn the specific sequence needed to navigate out of your app, interact with the system photo picker, and return to your Flow.
* [Check the clipboard content](/examples/recipes/check-the-clipboard-content.md): See how to verify that your app correctly copied text or links to the device clipboard using JavaScript assertions.
* [Download and open a file](/examples/recipes/download-and-open-a-file.md): A guide on handling "Save to Device" flows and verifying that files (like PDFs or images) are accessible.
* [Custom scrolling for screen fragments](/examples/recipes/custom-scrolling-for-screen-fragments.md): Master scrolling in complex layouts where elements are hidden inside sub-containers or fragments.
* [Get the last matching element](/examples/recipes/get-the-last-matching-element.md): Learn how to target a specific instance of an element when multiple identical items (like "Delete" buttons) appear in a list.
* [Implementing the Page Object Model (POM)](/examples/recipes/implementing-the-page-object-model-pom.md): Learn how to separate your element selectors from your test logic. This is the industry-standard approach for reducing maintenance and making tests readable for the whole team.
* [Test in different time zones (Android)](/examples/recipes/test-in-different-time-zones.md): Learn how to set the Android device time zone through the Settings app, by region or by UTC offset, to test features that depend on the time of day.

### Real world examples

See how Maestro handles real-world complexity in popular applications.

* [Automate Android Contacts Flow](/examples/real-world-examples/automate-android-contacts-flow.md): A perfect starting point to see how Maestro interacts with native Android system apps using text and ID selectors.
* [Automate Facebook Sign-Up (Android)](/examples/real-world-examples/automate-facebook-sign-up-android.md): Covers complex form filling, handling multiple screens, and navigating onboarding.
* [Advanced: Wikipedia on Android](/examples/real-world-examples/advanced-wikipedia-on-android.md): Demonstrates deep navigation, search interactions, and content verification.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/examples/readme.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
