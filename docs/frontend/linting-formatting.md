---
title: Linting and Formatting
---

# Linting and Formatting

The project uses [eslint](https://eslint.org/) with the
[Prettier plugin](https://github.com/prettier/eslint-plugin-prettier). eslint
handles linting, but eslint rules related to code formatting, they get handled
by prettier. For the most part, out of the box rules provided by the
configurations that are extended are used but there are some tweaks.

DEV also has some objects that live in the global scope, e.g. Pusher. The eslint
globals section of the eslint configuration is what enables these to be reported
as existing when eslint runs.

```javascript
globals: {
  InstantClick: false,
  filterXSS: false,
  Pusher: false,
  algoliasearch: false,
}
```

## Husky and lint-staged

The code base uses pre-commit hooks that are enabled by the
[husky](https://github.com/typicode/husky) and
[lint-staged](https://github.com/okonet/lint-staged) tools. Pre-commit hooks run
tasks such as eslint before code is committed. If there are listing issues that
can be fixed, they will get auto fixed and committed. If there are issues that
cannot be resolved, the commit fails and the changes need to be handled
manually.
