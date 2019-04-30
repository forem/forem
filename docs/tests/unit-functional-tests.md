---
title: Unit and Functional Tests
---

# Unit and Functional Tests

A unit test is about testing a single function/method in isolation with all of its possible outputs.

A functional test is about testing a single functionality, which can span multiple methods and a controller.

Other common terms in Rails are "model tests", "controller tests" and others.

You can find model tests in `spec/models`, controller tests in `spec/controllers` and additional functional tests in various directories within the `spec` directory.

You can run all models tests, for example, with:

```shell
bundle exec rspec spec/models
```

To run an individual file you can use for example:

```shell
bundle exec rspec spec/models/user_spec.rb
```

To run a specific test case you can use for example:

```shell
bundle exec rspec spec/models/user_spec.rb:10
```

where `10` is the line number of the test case you want to execute.

You can read the official guide [Testing Rails Applications](https://guides.rubyonrails.org/testing.html) to learn more.
