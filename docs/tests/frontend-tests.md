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
- For integration tests, use
  [preact-testing-library](https://github.com/testing-library/preact-testing-library).

## Running Tests

You can run those tests with:

```shell
npm run test
```

or

```shell
yarn test
```

Should you want to view only a single jest test, you can run:

```shell
npx jest app/javascript/<path-to-file>
```

## Running Tests in Watch Mode

You can run frontend tests in watch mode by running one of the following
commands:

```shell
npm run test:watch
```

or

```shell
yarn test:watch
```

In watch mode, after the first test run, jest provides several options for
filtering tests. These filtering options are enhanced via the
[jest-watch-typeahead](https://github.com/jest-community/jest-watch-typeahead/blob/master/README.md)
watch plugin. It allows you to filter by test filename or test name.

![Screenshot of the jest watch menu](/jest-watch-mode-screenshot.png)

## Debugging a Test

To troubleshoot any of your jest test files, add a debugger and run:

```shell
node --inspect-brk node_modules/.bin/jest --watch --runInBand <path-to-file>
```

You can read more about troubleshooting
[here](https://jestjs.io/docs/en/troubleshooting).

At the end of the test's execution, you will see the code coverage for the
Preact components in our codebase.

If tests require utility modules, create them in a `utilities` folder under the
`__tests__` folder. Jest is configured to not treat the `utilities` folder as a
test suite.

You can also debug jest in your favorite editor. See the
[Debugging](/frontend/debugging/) section of the frontend documentation.
