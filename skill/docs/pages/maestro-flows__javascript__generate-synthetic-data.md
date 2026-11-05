> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/javascript/generate-synthetic-data.md).

# Generate synthetic data

Generate random test data with the built-in faker object for names, emails, numbers, and more.

In Maestro, you can use the built-in DataFaker integration to generate dynamic, randomized data for your test. This is useful for bypassing unique-field constraints (like sign-up forms) and creating realistic testing environments without manual data entry.

### The `faker` object

Maestro provides a global `faker` object available within the JavaScript engine. This object is a wrapper around the DataFaker library and follows the same usage patterns and providers found in its Java documentation.

{% hint style="info" %}

#### DataFaker

For additional information about DataFaker, check its [documentation](https://www.datafaker.net/documentation/getting-started/#usage).
{% endhint %}

### Common data providers

The `faker` object provides access to a wide variety of data types, ranging from standard user information to specialized domains.&#x20;

{% hint style="info" %}

#### Providers available

Check the DataFaker to see all [Fake Data Providers](https://www.datafaker.net/documentation/providers/).
{% endhint %}

#### Basic identity data

Generate standard user information for forms:

* First Name: `faker.name().firstName()`
* Full Name: `faker.name().fullName()`
* Credit Card: `faker.finance().creditCard()` or via expression: `faker.expression('#{finance.creditcard}')`

#### Numbers&#x20;

Generate random ranges or specific number patterns:

* Between Range: `faker.expression("#{number.numberBetween '1' '10'}")`
* Digits: `faker.number().digits(5)`

#### Placeholder&#x20;

DataFaker also supports "fun" providers for non-critical placeholder text:

* Lord of the Rings: `faker.lordOfTheRings().character()` or `faker.lordOfTheRings().location()`

### Usage examples

You can use `faker` within `evalScript` to store values in the `output` object, or directly inside UI commands.

{% tabs %}
{% tab title="In-line data generation" %}

```yaml
- launchApp
- inputText:
    text: ${faker.name().firstName()}
- inputText:
    text: ${faker.internet().emailAddress()}
```

{% endtab %}

{% tab title="Complex expressions" %}
Using expressions allows you to combine multiple faker providers into a single string:

```yaml
- evalScript: '${output.bio = faker.expression("#{name.fullName} lives in #{address.city}")}'
- console.log: ${output.bio}
```

{% endtab %}
{% endtabs %}


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-flows/javascript/generate-synthetic-data.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
