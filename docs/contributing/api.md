---
title: Contributing to the API Specification Docs
---

# Contributing to API specification docs

The API v0 is described with the
[OpenAPI 3 specification](https://spec.openapis.org/oas/v3.0.3).

Swagger.io has
[great docs](https://swagger.io/docs/specification/basic-structure/) that are
helpful to understand the specification better.

## Where you can find the spec file

We auto-generate the documentation from `api_v0.yml` within the `/docs`
directory. We use [ReDoc](https://github.com/Redocly/redoc) to turn the OpenAPI
3 format into a readable and searchable HTML documentation.

## Updating API docs

Whenever you make changes to the API docs, make sure to bump the version at the
top of `api_v0.yml`, in `info.version`.

## Running and editing the docs locally

If you want to browse the documentation locally you can use:

```shell
yarn api-docs:serve
```

This will let you browse the auto-generated version of the doc locally, and it
will reload the documentation after every change of the specification file.

## Linting and validation

We use [spectral](https://github.com/stoplightio/spectral) and
[ibm-openapi-validator](https://github.com/IBM/openapi-validator) to validate
the spec file. The validation is performed as a `pre-commit` hook.

You can also manually validate the document, running:

```shell
yarn api-docs:lint
```

If you have Visual Studio Code, we suggest you install the following extensions
that enable validation and navigation within the spec file:

- [OpenAPI (Swagger) editor](https://marketplace.visualstudio.com/items?itemName=42Crunch.vscode-openapi)
- [openapi-designer live preview](https://marketplace.visualstudio.com/items?itemName=philosowaffle.openapi-designer)
