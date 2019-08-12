---
title: Contributing to API spec docs
---

# Contributing to API spec docs

The API docs follow the [OpenAPI 3 specification](http://spec.openapis.org/oas/v3.0.2).

## Where The Docs Are Located

We auto generate the documentation from `api_v0.yml` within the `/docs` directory.
We use [ReDoc](https://github.com/Redocly/redoc) to turn the OpenAPI 3 format into a readable and searchable HTML documentation.

## Running and editing the Docs Locally

If you want to browse the documentation locally you can use:

```shell
yarn api-docs:serve
```

This will let you browse the auto generated version of the doc locally and it will reload the doc after every modification
of the spec file.

If you have Visual Studio Code we suggest you install the following extensions that enable validation and navigation within
the spec file:

- [OpenAPI (Swagger) editor](https://marketplace.visualstudio.com/items?itemName=42Crunch.vscode-openapi)
- [openapi-designer live preview](https://marketplace.visualstudio.com/items?itemName=philosowaffle.openapi-designer)
