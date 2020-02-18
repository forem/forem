---
title: Frontend Tests
---

# Frontend Tests

The test code is located within the same directory as each component, inside a
`__tests__` directory.

```shell
$ tree app/javascript/article-form -L 1
app/javascript/article-form
├── __tests__
└── articleForm.jsx
```

The testing library being used is [Jest](https://jestjs.io/).

- For unit tests, use jest's [expect API](https://jestjs.io/docs/en/expect)
- For snapshot testing of Preact components, use
  [preact-render-spy](https://github.com/mzgoddard/preact-render-spy) and
  [preact-render-to-json](https://github.com/nathancahill/preact-render-to-json).

You can run those tests with:

```shell
npm run test
```

or

```shell
yarn test
```

At the end of the test's execution, you will see the code coverage for the
Preact components in our codebase.

If tests require utility modules, create them in a `utilities` folder under the
`__tests__` folder. Jest is configured to not treat the `utilities` folder as a
test suite.
