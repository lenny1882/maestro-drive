> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-cli/using-a-proxy-with-maestro-cli.md).

# Using a proxy with Maestro CLI

Lots of corporate environments require use of proxy server for internet traffic for security purposes. Some technically-minded folks prefer a proxy in their own home. Configuring Maestro CLI to use a proxy server is done through environment variables.

### Environment Variables

You configure proxy options through either of 2 variables:

* **JAVA\_OPTS** - Used by all Java (or JVM-based) applications on the system. This is useful when you might have more than one application with this need, and you only want to configure it once.
* **MAESTRO\_OPTS** - Exactly the same format, but applies only to Maestro, not to other application. This is useful when you might have specific configurations already in JAVA\_OPTS, or you're worried about breaking another JVM-based application

### Variable Settings

#### Using a System Proxy

To use a system proxy, set the value of the environment variable like this:

<pre><code><strong>MAESTRO_OPTS="-Djava.net.useSystemProxies=true"
</strong></code></pre>

#### Using a Custom Proxy

To use a custom proxy, set the environment variable with the host and port of the server to connect to:

```
MAESTRO_OPTS="-Dhttps.proxyHost=myproxy.com -Dhttps.proxyPort=8080"
```

### Configuring Variables

This section covers how to set the variables on different operating systems, and for different lengths of time.

#### Single use configuration

{% tabs %}
{% tab title="macOS / Linux" %}
For a single command

```bash
MAESTRO_OPTS="-Djava.net.useSystemProxies=true" maestro login
```

Until you close this terminal window

```bash
export MAESTRO_OPTS="-Djava.net.useSystemProxies=true"
maestro login
```

{% endtab %}

{% tab title="Windows" %}
To set a variable for the duration of this open Command Prompt:

```bat
set MAESTRO_OPTS=-Djava.net.useSystemProxies=true                                                                                                                                                
maestro login
```

To set a variable for the duration of this Powershell Prompt:

```powershell
$env:MAESTRO_OPTS="-Djava.net.useSystemProxies=true"
maestro login
```

{% endtab %}
{% endtabs %}

#### Permanent configuration

{% tabs %}
{% tab title="macOS" %}
To permanently add the environment variable to your .zshrc for all future shell sessions:

```bash
echo 'export MAESTRO_OPTS="-Djava.net.useSystemProxies=true"' >> ~/.zshrc
```

{% endtab %}

{% tab title="Linux" %}
To permanently add the environment variable to your .bashrc for all future shell sessions:

```bash
echo 'export MAESTRO_OPTS="-Djava.net.useSystemProxies=true"' >> ~/.bashrc
```

{% endtab %}

{% tab title="Windows" %}
To permanently add the environment variable for all future console sessions:

```
setx MAESTRO_OPTS=-Djava.net.useSystemProxies=true
```

{% endtab %}
{% endtabs %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation dynamically by asking a question.

Perform an HTTP GET request on the current page URL with the `ask` query parameter, and the optional `goal` query parameter:

```
GET https://docs.maestro.dev/maestro-cli/using-a-proxy-with-maestro-cli.md?ask=<question>&goal=<endgoal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is optional and describes the broader end goal you are ultimately trying to accomplish on behalf of the user. GitBook uses it to tailor the answer towards what is most useful for that goal.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
