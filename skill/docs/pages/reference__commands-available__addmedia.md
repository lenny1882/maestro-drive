> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/addmedia.md).

# addMedia

Add images or videos to the device gallery for media picker testing.

The `addMedia` command adds one or more media files from your workspace to the device's gallery on both Android and iOS. This makes the files accessible to your application during a test flow.

The command accepts a list of strings, where each string is the relative path to a media file in your workspace.

### Usage examples

The following example adds a PNG image and an MP4 video to the device's gallery.

```yaml
- addMedia:
    - "./assets/foo.png"
    - "./assets/foo.mp4"
```

### Supported formats

This command supports the following file formats:

* `PNG`
* `JPEG`
* `JPG`
* `GIF`
* `MP4`


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/reference/commands-available/addmedia.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
