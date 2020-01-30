---
title: Contributing to the Docs
---

# Contributing to DEV's developer documentation

Contributions to the documentation are always appreciated! Thank you for making
an effort to improve the developer experience of contributing to the DEV
project.

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

Since our documentation is built on GitDocs, which is built on Netlify, you can
use the generated deploy preview link to check out your documentation changes.
Once you make a PR, click on "Show all checks" and find the "deploy/netlify"
row. If your deploy preview is ready, you can click on "Details" to see the
preview. Please note that the deploy preview only reflects any documentation
changes you make (and not any changes elsewhere in the app).

# Useful links

The docs are a collection of [Markdown files][markdown] that also utilize
[FrontMatter][frontmatter].

For more information on how to use GitDocs read the [GitDocs
guide][gitdocs_guide].

# Regarding style

Generally speaking, the documentation hosted on this site is informal. There is
no need to make things more complicated by writing these articles like a
textbooks.

However, it's expected that contributions to these documents are reasonably
structured and mostly free of spelling and grammar errors. For this reason, if
you submit a PR you might be asked to make changes before your PR is merged.

Prettier is used to autowrap lines in these files to 80 characters. Using 80
characters per line allows us to retain a more specific git history over time.
If lines are not wrapped, changing a comma in a paragraph would attribute the
entire paragraph to one commit. By line wrapping we are helping git to correctly
attribute smaller changes to their commits. This keeps information from getting
lost over time.

For more information on effective technical writing, check out
[writethedocs.org][writethedocs].

[docs]: https://github.com/thepracticaldev/dev.to/tree/master/docs/
[gitdocs]: https://www.npmjs.com/package/gitdocs/
[markdown]: https://en.wikipedia.org/wiki/Markdown
[frontmatter]: https://jekyllrb.com/docs/front-matter/
[gitdocs_guide]: https://gitdocs.netlify.com/
[writethedocs]: https://www.writethedocs.org/guide/
