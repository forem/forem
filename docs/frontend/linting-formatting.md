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

The code base uses a pre-commit hook that is enabled by the
[husky](https://github.com/typicode/husky) and
[lint-staged](https://github.com/okonet/lint-staged) tools. The pre-commit hook
runs eslint before frontend code is committed. If there are any issues that can
automatically be fixed, eslint will fix them. If there are linting issues that
cannot be resolved, the commit fails and the changes need to be handled
manually. Prettier also runs during the pre-commit hook.
