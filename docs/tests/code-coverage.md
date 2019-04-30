---
title: Code Coverage
---

# Code coverage

## Rails

Rails tests will generate the code coverage at the end of the tests execution.

To get the code coverage of the whole Rails code base you need to run all the tests with:

```shell
bundle exec rspec
```

or

```shell
bin/rspec
```

To get the code coverage of a single file you can run

```shell
bundle exec rspec spec/models/user_spec.rb
```

or

```shell
bin/rspec spec/models/user_spec.rb
```

After the test run is complete, open `coverage/index.html` with a browser so you can check the the code coverage.

## Preact

Preact tests will generate the code coverage at the end of the tests execution.

To get the code coverage of the Preact code base you need to run all the tests with:

```shell
npm run test
```

or

```shell
yarn test
```

After the test run is complete, you will see the coverage on the console.
