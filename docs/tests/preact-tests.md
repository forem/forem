---
title: Preact Tests
---

# Preact Tests

The test code is located within the same directory as each component,
inside a `__tests__` directory.

```shell
$ tree app/javascript/article-form -L 1
app/javascript/article-form
├── __tests__
└── articleForm.jsx
```

The testing library being used is [Jest](https://jestjs.io/).

You can run those tests with:

```shell
npm run test
```

or

```shell
yarn test
```

At the end of the tests execution you will see the code coverage for the Preact components tests.
