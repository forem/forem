---
title: Unit and Functional Tests
---

# Unit and Functional Tests

A unit test is about testing a single function/method in isolation with all of
its possible outputs.

A functional test is about testing a single functionality, which can span
multiple methods and a controller.

Other common terms in Rails are "model tests," "controller tests," and others.

You can find model tests in `spec/models`, controller tests in
`spec/controllers` and additional functional tests in various directories within
the `spec` directory.

You can run all models tests, for example, with:

```shell
bundle exec rspec spec/models
```

To run an individual file you can use, for example:

```shell
bundle exec rspec spec/models/user_spec.rb
```

To run a specific test case you can use, for example:

```shell
bundle exec rspec spec/models/user_spec.rb:10
```

where `10` is the line number of the test case that you want to execute.

## Testing Controllers

Historically, it has been common to use Rspec to write tests for Rails
controllers. This pattern isn't necessarily discouraged in the DEV codebase, but
Rspec has introduced a more effective way to test controllers via Request Specs.

Request specs test the actions on a controller across the entire stack,
effectively acting as Integration Tests. You can read more about request specs
in our documentation on [Integration Tests][integration_tests].

You can read the official guide [Testing Rails Applications][rails_guides] to
learn more.

[integration_tests]: /tests/integration-tests/
[rails_guides]: https://guides.rubyonrails.org/testing.html
