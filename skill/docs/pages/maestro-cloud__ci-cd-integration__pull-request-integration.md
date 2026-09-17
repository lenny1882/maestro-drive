> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cloud/ci-cd-integration/pull-request-integration.md).

# Pull request integration

Native pull request integration allows you to run Maestro Flows asynchronously on every code change. You can configure it to block pull requests from being merged if test failures are detected.

{% hint style="info" %}
**Maestro Cloud Plan required.** Pull request integration is available on the [Maestro Cloud Plan](https://signin.maestro.dev/sign-up).
{% endhint %}

{% hint style="info" %}
Maestro Cloud currently supports native pull request integration for:

* **GitHub**
* **GitHub Enterprise** only.
  {% endhint %}

{% stepper %}
{% step %}

#### Trigger uploads on every pull request

You must configure your CI environment to trigger a Maestro Cloud upload for every pull request. You can accomplish this by using one of the following options:

{% tabs %}
{% tab title="GitHub Actions" %}
Trigger your workflow on `pull_request` events against your baseline branch.

{% code title="" %}

```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
```

{% endcode %}
{% endtab %}

{% tab title="Maestro CLI" %}
Add the `--async` flag and PR-specific metadata to your `maestro cloud` command.

```bash
maestro cloud \
  --async \
  --api-key <YOUR_API_KEY> \
  --branch <BRANCH_NAME> \
  --repo-owner <REPO_OWNER> \
  --repo-name <REPO_NAME> \
  --pull-request-id <PR_ID> \
  --commit-sha <COMMIT_SHA> \
  --app-file <APP_FILE> --flows .maestro/
```

The following table describes each one of the required flags you must inform.

| Argument            | Description                                                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `--branch`          | The name of the git branch being tested (e.g., `feature-branch`). Maestro uses this to group results by branch in the console. |
| `--repo-owner`      | The owner (individual or organization) of the repository on GitHub. Required for posting status checks.                        |
| `--repo-name`       | The name of the repository. Combined with `--repo-owner`, this identifies the target project for integration.                  |
| `--pull-request-id` | The number of the pull request. Essential for linking the test run to a specific PR and enabling automated comments.           |
| `--commit-sha`      | The full 40-character SHA of the commit. This ensures test results are associated with the exact state of the code.            |
| {% endtab %}        |                                                                                                                                |

{% tab title="API" %}
If using the upload API directly, include the following fields in the JSON payload:

* `branch`
* `repoOwner`
* `repoName`
* `pullRequestId`
* `commitSha`

The following table describes each one of the required fields you must inform.

| Field           | Description                                                                                                                    |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `branch`        | The name of the git branch being tested (e.g., `feature-branch`). Maestro uses this to group results by branch in the console. |
| `repoOwner`     | The owner (individual or organization) of the repository on GitHub. Required for posting status checks.                        |
| `repoName`      | The name of the repository. Combined with `--repo-owner`, this identifies the target project for integration.                  |
| `pullRequestId` | The number of the pull request. Essential for linking the test run to a specific PR and enabling automated comments.           |
| `commitSha`     | The full 40-character SHA of the commit. This ensures test results are associated with the exact state of the code.            |
| {% endtab %}    |                                                                                                                                |
| {% endtabs %}   |                                                                                                                                |
| {% endstep %}   |                                                                                                                                |

{% step %}

#### Grant access to pull requests

Maestro requires permission to update pull request statuses. To accomplish this, you must install the [Maestro Cloud app](https://github.com/apps/maestro-cloud-app) and grant access to your repositories to the desired repositories.
{% endstep %}

{% step %}

#### Test the integration

Once configured, open a pull request. The Maestro Cloud status check appears in the checks section. A passing check indicates all Flows ran successfully, while a failing check indicates that at least one Flow failed.

<figure><img src="/files/0UsMoz6OCCqTQWLjC7sI" alt=""><figcaption></figcaption></figure>
{% endstep %}
{% endstepper %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cloud/ci-cd-integration/pull-request-integration.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
