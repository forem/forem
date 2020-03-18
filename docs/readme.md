---
items:
  - technical-overview
  - installation
  - getting-started
  - backend
  - frontend
  - internal
  - design
  - deployment.md
  - tests
  - contributing.md
  - contributing_api.md
  - faqs.md
  - troubleshooting.md
  - licensing.md
  - self-hosting.md
  - maintainers
---

# Welcome to DEV's developer documentation

On this site you'll find instructions to setup a [local instance of
DEV][installation], documentation on the [architecture of DEV][architecture],
[how to contribute][contributing], and many other useful documents.

This documentation site is the product of a number of volunteer contributors
working alongside the DEV Core Team, special thanks to all those who have
contributed to the documentation.

# Running the documentation locally

Like DEV, this site is open source and the code is [hosted on GitHub][docs]. If
you find any incorrect information, or a even a typo, we'd love to see a pull
request. Follow these steps to get the documentation site running locally.

DEV's documentation is built with [GitDocs NodeJS library][gitdocs].

The first step to running the documentations locally is to install the `GitDocs`
package globally.

With npm:

```shell
npm install gitdocs -g
```

Alternatively, you can use Yarn:

```shell
yarn global add gitdocs
```

Once installed, you should run `gitdocs serve` from the root of the dev.to
project or from the `/docs` directory.

```shell
gitdocs serve
```

This will start a server where you can browse the documentation:
<http://localhost:8000/>

If you add new pages or rename existing pages, you'll need to restart the server
for those changes to take effect.

# Contributing to the docs

If you're looking for more information on contributing, check out the
[Contributing article][contributing].

[installation]: /installation/
[architecture]: /technical-overview/architecture/
[contributing]: /contributing/
[docs]: https://github.com/thepracticaldev/dev.to/tree/master/docs/
[gitdocs]: https://www.npmjs.com/package/gitdocs/
