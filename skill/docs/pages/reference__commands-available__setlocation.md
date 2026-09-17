> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/reference/commands-available/setlocation.md).

# setLocation

The `setLocation` command applies a mock geolocation to the device.

### Arguments

The following arguments are available for the `setLocation` command.

| Argument    | Description               |
| ----------- | ------------------------- |
| `latitude`  | The latitude coordinate.  |
| `longitude` | The longitude coordinate. |

### Usage examples

The following example sets the device's location to Amsterdam.

```yaml
- setLocation:
    latitude: 52.3599976
    longitude: 4.8830301
```

### Limitations

Keep the following limitations in mind when using `setLocation`:

* On Android, this command requires API level `31` or higher.
* The command only updates the device's coordinate-based location. When running tests in Maestro Cloud, services that rely on IP-based geolocation still resolve to a US-based IP address.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/reference/commands-available/setlocation.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
