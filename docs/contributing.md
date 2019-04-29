---
title: Contributing to Docs
---

# Contributing to Docs

The documentation you are reading is powered by [GitDocs](https://github.com/timberio/gitdocs).

## Where The Docs Are Located

This documentation is located in the [DEV.to codebase](https://github.com/thepracticaldev/dev.to) within the `/docs` directory.

The docs are a collection of [Markdown files](https://en.wikipedia.org/wiki/Markdown) that also utilize [FrontMatter](https://jekyllrb.com/docs/front-matter/).

For more information on how to use GitDocs read the [GitDocs guide](https://gitdocs.netlify.com)

## Running the Docs Locally

Install the [GitDocs NodeJs library](https://www.npmjs.com/package/gitdocs)

```shell
npm install gitdocs -g
```

Specifying `-g` will install the library globally which is what you want to do.

If you use yarn you can instead issue:

```shell
yarn global add gitdocs
```

Once installed, to run gitdocs you need to navigate to the root
directory of the DEV.to codebase and run

```shell
gitdocs serve
```

This will start a server where you can browse the documentation: <http://localhost:8000/>

When you add new markdown pages or rename existing ones, you'll have to restart
the server before you notice any changes.
