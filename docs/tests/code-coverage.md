---
title: Code Coverage
---

# Code coverage

## Rails

Rspec will generate code coverage at the end of the tests.

To get the code coverage of the entire Rails codebase, you must run the full
Ruby test suite. You can run the full test suite with the `rspec` command:

```shell
bundle exec rspec
```

or

```shell
bin/rspec
```

To get the code coverage of a single file, you can run:

```shell
bundle exec rspec spec/models/user_spec.rb
```

or

```shell
bin/rspec spec/models/user_spec.rb
```

Once your tests have completed, the `coverage/index.html` will be regenerated
with some stats concerning the overall health of our test suite including a code
coverage metric.

To turn off coverage report generation please set environment variable
`COVERAGE` value to `false`.

## Preact

Preact tests will generate code coverage at the end of the tests.

To get the code coverage of the Preact codebase, you must run the full JS test
suite. You can run the full test suite with the npm task `test`:

```shell
npm run test
```

or

```shell
yarn test
```

Once the tests have completed, the test coverage metric will be visible in the
terminal window. Please note that jest will fail if test coverage thresholds are not met.
