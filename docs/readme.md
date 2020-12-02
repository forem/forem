---
items:
  - technical-overview
  - installation
  - getting-started
  - contributing
  - backend
  - frontend
  - admin
  - design
  - tests
  - faqs.md
  - troubleshooting.md
  - licensing.md
  - self-hosting.md
  - maintainers
  - component: Divider
  - creators
---

# Welcome to Forem's developer documentation

On this site you'll find instructions to setup a [local instance of
Forem][installation], documentation on the [architecture of
Forem][architecture], [how to contribute][contributing], and many other useful
documents.

This documentation site is the product of a number of volunteer contributors
working alongside the Forem Core Team, special thanks to all those who have
contributed to the documentation.

# Running the documentation locally

Like Forem, this site is open source and the code is [hosted on GitHub][docs].
If you find any incorrect information, or a even a typo, we'd love to see a pull
request.

Forem's documentation is built with [GitDocs NodeJS library][gitdocs].

To start the gitdocs server, you should run `yarn gitdocs serve` from the root
of the `forem` project or from the `/docs` directory.

```shell
yarn gitdocs serve
```

This will start a server where you can browse the documentation:
<http://localhost:8000/>

If you add new pages or rename existing pages, you'll need to restart the server
for those changes to take effect.

# Contributing to the docs

If you're looking for more information on contributing, check out the
[Contributing guide][contributing].

[installation]: /docs/installation/
[architecture]: /docs/technical-overview/architecture/
[contributing]: /docs/contributing/
[docs]: https://github.com/forem/forem/tree/master/docs/
[gitdocs]: https://www.npmjs.com/package/gitdocs/
