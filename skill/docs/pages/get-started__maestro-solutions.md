> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/get-started/maestro-solutions.md).

# Maestro solutions

The Maestro ecosystem is a unified platform composed of three interconnected layers. Each tool is designed to solve a specific challenge in the mobile and web automation lifecycle:

* **Maestro Studio**: Desktop IDE for writing and running Maestro flows
* **Maestro CLI**: Command line tool for running Maestro flows
* **Maestro Cloud**: Hosted platform for consistent, parallel Maestro execution

### **Maestro Studio (The IDE)**

Maestro Studio is a visual interface built on top of the CLI, designed for rapid test creation and real-time element inspection. By mirroring your device screen and allowing you to build [Flows](https://docs.maestro.dev/maestro-flows/) through simple point-and-click interactions, it serves as the primary tool for zero-code authoring and interactive debugging.

You can start building your first Flows today by visiting the [Maestro Studio](https://docs.maestro.dev/maestro-studio/) documentation.

### **Maestro CLI**

The CLI is the open-source heart of Maestro and the core engine that powers both Maestro Studio and Maestro Cloud. It serves as the workhorse for developers and DevOps engineers, interpreting your YAML files to orchestrate test execution. Because everything else is built on top of the CLI, it acts as the foundational backbone for all local automation and CI/CD integration.

To learn more about its technical capabilities and orchestration features, check out the [Maestro CLI](https://docs.maestro.dev/maestro-cli/) documentation.

### **Maestro Cloud**

Maestro Cloud is a managed execution solution designed to scale your testing infrastructure without the overhead of managing local device farms. It leverages the Maestro CLI to run your tests on a distributed cloud of virtual devices, enabling massive parallelization and providing fast and reliable feedback loops for production-ready reliability.

Explore how to scale your regression suites in the [Maestro Cloud](/maestro-cloud/readme.md) documentation.

### Which solution should I use?

Use the table below to determine which tool fits your current workflow:

| **Feature**     | **Maestro Studio**      | **Maestro CLI**         | **Maestro Cloud**                                                   |
| --------------- | ----------------------- | ----------------------- | ------------------------------------------------------------------- |
| **Best For**    | Authoring & Debugging   | Local execution & CI/CD | Reliable & scalable parallel test execution                         |
| **Interface**   | Visual (GUI)            | Terminal (Command Line) | Upload via CLI, see runs via web, notifications via Slack + Webhook |
| **Execution**   | Real-time / Interactive | Sequential (Local)      | Parallel (Simultaneous)                                             |
| **Target User** | Testers & Developers    | Engineers & DevOps      | Growth & Professional Teams                                         |
| **Environment** | Local Device/Emulator   | Local Device/Emulator   | Hosted Virtual Devices                                              |

### The typical learning path

Most teams follow a three-stage journey to automation success:

1. **Creation**: Start with [Maestro Studio](https://docs.maestro.dev/maestro-studio/) to visually build and debug your first [Flows](https://docs.maestro.dev/maestro-flows/).
2. **Automation**: Use the[ Maestro CLI](https://docs.maestro.dev/maestro-cli/) to run those Flows locally and integrate them into your basic development workflow.
3. **Scaling**: Once your test suite grows, transition to [Maestro Cloud](/maestro-cloud/readme.md) to run those same tests in parallel for instant feedback on every Pull Request.

### Next steps

If you already know the Maestro solution you are going to use, access the desired documentation:

* [Maestro Studio](https://docs.maestro.dev/maestro-studio/)
* [Maestro CLI](https://docs.maestro.dev/maestro-cli/)
* [Maestro Cloud](/maestro-cloud/readme.md)

If you don't know how to create tests with Maestro, access the [QuickStart](/get-started/quickstart.md) guide to get up and running in minutes.


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/get-started/maestro-solutions.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
