---
items:
  - technical-overview.md
  - installation
  - getting-started
  - backend
  - frontend
  - design
  - tests
  - contributing.md
  - contributing_api.md
  - faqs.md
  - licensing.md
  - self-hosting.md
---

# Welcome to DEV's developer documentation

Here you can find instructions on how to setup your own local copy of DEV, how to navigate the code, how to contribute, and how to troubleshoot issues, among other things.

# Running the documentation locally

DEV's documentation is built with [GitDocs NodeJS library](https://www.npmjs.com/package/gitdocs).

The first step to running the documentations it locally is to install the `GitDocs` package globally.

With npm:

```shell
npm install gitdocs -g
```

Alternatively, you can use Yarn:

```shell
yarn global add gitdocs
```

Once installed, you can run `gitdocs serve` from the root of the dev.to project or from the `/docs` directory.

```shell
gitdocs serve
```

This will start a server where you can browse the documentation: <http://localhost:8000/>

When you add new markdown pages or rename existing ones, you'll have to restart
the server before you notice any changes.

# Contributing to the docs

If you're looking for more information on contributing, check out the [Contributing article](https://docs.dev.to/contributing/).
