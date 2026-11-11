> For the complete documentation index, see [llms.txt](https://docs.maestro.dev/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.maestro.dev/maestro-flows/flow-control-and-logic/test-in-different-locales/locales-supported-by-maestro.md).

# Locales supported by Maestro

Complete list of locale codes supported by Maestro for internationalization testing.

This reference page provides a list of the Language and Country codes supported by Maestro when using the `--device-locale` flag.

{% hint style="info" %}
Access the [Test in different locales](/maestro-flows/flow-control-and-logic/test-in-different-locales.md) guide for more information.
{% endhint %}

### Android locales

On Android, Maestro combines language and country codes to set the device environment. You can typically use just the language code, or a combination for regional specificity (e.g., `pt-BR`).

#### **Android language codes**

| Country code | Country name   |
| ------------ | -------------- |
| AU           | Australia      |
| AT           | Austria        |
| BE           | Belgium        |
| BR           | Brazil         |
| GB           | Britain        |
| BG           | Bulgaria       |
| CA           | Canada         |
| HR           | Croatia        |
| CZ           | Czech Republic |
| DK           | Denmark        |
| EG           | Egypt          |
| FI           | Finland        |
| FR           | France         |
| DE           | Germany        |
| GR           | Greece         |
| HK           | Hong-Kong      |
| HU           | Hungary        |
| IN           | India          |
| ID           | Indonesia      |
| IE           | Ireland        |
| IL           | Israel         |
| IT           | Italy          |
| JP           | Japan          |
| KR           | Korea          |
| LV           | Latvia         |
| LI           | Liechtenstein  |
| LT           | Lithuania      |
| NL           | Netherlands    |
| NZ           | New Zealand    |
| NO           | Norway         |
| PH           | Philippines    |
| PL           | Poland         |
| PT           | Portugal       |
| CN           | PRC            |
| RO           | Romania        |
| RU           | Russia         |
| RS           | Serbia         |
| SG           | Singapore      |
| SK           | Slovakia       |
| SI           | Slovenia       |
| ES           | Spain          |
| SE           | Sweden         |
| CH           | Switzerland    |
| TW           | Taiwan         |
| TH           | Thailand       |
| TR           | Turkey         |
| UA           | Ukraine        |
| US           | USA            |
| VN           | Vietnam        |
| ZA           | Zimbabwe       |

#### **Android country codes**

| Country code | Country name   |
| ------------ | -------------- |
| AU           | Australia      |
| AT           | Austria        |
| BE           | Belgium        |
| BR           | Brazil         |
| GB           | Britain        |
| BG           | Bulgaria       |
| CA           | Canada         |
| HR           | Croatia        |
| CZ           | Czech Republic |
| DK           | Denmark        |
| EG           | Egypt          |
| FI           | Finland        |
| FR           | France         |
| DE           | Germany        |
| GR           | Greece         |
| HK           | Hong-Kong      |
| HU           | Hungary        |
| IN           | India          |
| ID           | Indonesia      |
| IE           | Ireland        |
| IL           | Israel         |
| IT           | Italy          |
| JP           | Japan          |
| KR           | Korea          |
| LV           | Latvia         |
| LI           | Liechtenstein  |
| LT           | Lithuania      |
| NL           | Netherlands    |
| NZ           | New Zealand    |
| NO           | Norway         |
| PH           | Philippines    |
| PL           | Poland         |
| PT           | Portugal       |
| CN           | PRC            |
| RO           | Romania        |
| RU           | Russia         |
| RS           | Serbia         |
| SG           | Singapore      |
| SK           | Slovakia       |
| SI           | Slovenia       |
| ES           | Spain          |
| SE           | Sweden         |
| CH           | Switzerland    |
| TW           | Taiwan         |
| TH           | Thailand       |
| TR           | Turkey         |
| UA           | Ukraine        |
| US           | USA            |
| VN           | Vietnam        |
| ZA           | Zimbabwe       |

### iOS locales

iOS locales are typically provided as a single combined string, like `en_US`.

| Locale code | Locale name             |
| ----------- | ----------------------- |
| en\_AU      | Australia (English)     |
| nl\_BE      | Belgium (Dutch)         |
| fr\_BE      | Belgium (French)        |
| pt-BR       | Brazil (Portuguese)     |
| ms\_BN      | Brunei Darussalam       |
| zh\_CN      | China (Simplified)      |
| zh-Hans     | China (Simplified)      |
| zh-Hant     | China (Traditional)     |
| en\_CA      | Canada (English)        |
| fr\_CA      | Canada (French)         |
| cs\_CZ      | Czech Republic          |
| fi\_FI      | Finland                 |
| fr\_FR      | France                  |
| de\_DE      | Germany                 |
| el\_GR      | Greece                  |
| zh\_HK      | Hong Kong               |
| hu\_HU      | Hungary                 |
| hi\_IN      | India (Hindi)           |
| en-IN       | India (English)         |
| id\_ID      | Indonesia               |
| en-IE       | Ireland                 |
| he\_IL      | Israel                  |
| it\_IT      | Italy                   |
| ja\_JP      | Japan                   |
| ko\_KR      | Korea                   |
| es-419      | Latin America (Spanish) |
| ms\_MY      | Malaysia                |
| es-MX       | Mexico (Spanish)        |
| nl\_NL      | Netherlands             |
| en\_NZ      | New Zealand             |
| nb\_NO      | Norway                  |
| tl\_PH      | Philippines             |
| pl\_PL      | Poland                  |
| zh\_CN      | PRC                     |
| ro\_RO      | Romania                 |
| ru\_RU      | Russia                  |
| en\_SG      | Singapore               |
| sk\_SK      | Slovakia                |
| en-ZA       | South Africa (English)  |
| es\_ES      | Spain                   |
| sv\_SE      | Sweden                  |
| zh\_TW      | Taiwan                  |
| th\_TH      | Thailand                |
| tr\_TR      | Turkey                  |
| uk\_UA      | Ukraine                 |
| en\_GB      | UK (English)            |
| es\_US      | USA (Spanish)           |
| en\_US      | USA (English)           |
| vi\_VN      | Vietnam                 |


---

# Agent Instructions
This documentation is published with GitBook. GitBook is the documentation platform designed so that both humans and AI agents can read, navigate, and reason over technical content effectively. Learn more at gitbook.com.

## Querying This Documentation
If you need additional information that is not directly available in this page, you can query the documentation by asking a question.

Perform an HTTP GET request on the following URL with the `ask` and `goal` query parameters:

```
GET https://docs.maestro.dev/maestro-flows/flow-control-and-logic/test-in-different-locales/locales-supported-by-maestro.md?ask=<question>&goal=<user_goal>
```

`ask` is the immediate question: it should be specific, self-contained, and written in natural language.
`goal` is what the user is ultimately trying to achieve, the reason they need the answer. Sharing it helps GitBook give you a better, more relevant answer. A goal is most helpful when it describes the outcome the user wants rather than restating the question. For example, with `ask=how do I create an API token`, a goal like `automate deployments from our CI pipeline` lets GitBook tailor the answer to that use case.

The response will contain a direct answer to the question and relevant excerpts and sources from the documentation.

Use this mechanism when the answer is not explicitly present in the current page, you need clarification or additional context, or you want to retrieve related documentation sections.
