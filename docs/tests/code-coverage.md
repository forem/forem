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

To get the code coverage of a particular spec in a single file, append the
line-number for that spec:

```shell
bundle exec rspec spec/models/user_spec.rb:24
```

or

```shell
bin/rspec spec/models/user_spec.rb:24
```

Once your tests have completed, the `coverage/index.html` will be regenerated
with some stats concerning the overall health of our test suite including a code
coverage metric.

A few things to note:

- "Coverage" indicates whether or not the test suite runs through the code in
  question. It does not equate to actually testing for functionality, and
  shouldn’t be thought of that way.
- Running Rspec in general will overwrite the existing `coverage/index.html` so,
  if you want to reference the results of a particular run, save a copy of the
  file before re-running the test suite.

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
terminal window. Please note that jest will fail if test coverage thresholds are
not met.
