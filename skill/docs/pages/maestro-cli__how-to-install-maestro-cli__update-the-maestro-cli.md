> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli/update-the-maestro-cli.md).

# Update the Maestro CLI

Keeping your Maestro CLI up to date ensures you have access to the latest features, command improvements, and security patches. Depending on your original installation method, follow the appropriate steps below.

### Standard update

If you originally used the installation script to set up Maestro on macOS, Linux, or WSL2, you can upgrade to the latest version by running the script again:

```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
```

This command automatically fetches the most recent release and replaces your existing binary.

After running the update, verify that you are running the expected version by checking the CLI metadata:

```bash
maestro --version
```

### Alternative update methods

If you installed Maestro using a package manager or manual download, use these specific commands:

#### **Homebrew (macOS)**

If you used the Homebrew tap, update using the standard brew commands:

```bash
brew update
brew upgrade mobile-dev-inc/tap/maestro
```

#### Manual update (Windows)

For native Windows installations not using `curl`:

1. Download the latest [maestro.zip](https://github.com/mobile-dev-inc/maestro/releases/latest/download/maestro.zip) package.
2. Extract the contents into your existing Maestro folder (e.g., `C:\maestro`).
3. Replace all existing files to update the binary.

### Install a specific version

There are scenarios where you may need to downgrade or lock your suite to a specific version for compatibility across a team or CI/CD environment.

To install a specific version, set the `MAESTRO_VERSION` environment variable before running the update script:

```
export MAESTRO_VERSION={version}; curl -Ls "https://get.maestro.mobile.dev" | bash
```

{% hint style="info" %}
You can find a full list of valid versions on the [GitHub releases page](https://github.com/mobile-dev-inc/maestro/releases).
{% endhint %}

You have to pass the version of Maestro CLI you want to install. To do this, replace the `{version}` parameter with your desired Maestro version.

For example, to install version 1.39.0 of Maestro CLI:

```bash
export MAESTRO_VERSION=1.39.0; curl -Ls "https://get.maestro.mobile.dev" | bash
```


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli/update-the-maestro-cli.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
