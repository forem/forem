---
title: Acceptance Tests
---

# Acceptance Tests

Acceptance tests are tests from the perspective of the end user.

It means that we are simulating what a user could do from their web browser
and testing the expected behavior of the app.

Acceptance tests can be found in the directory `spec/system` (in Rails terminology these are called "system tests").

You can run all acceptance tests with:

```shell
bundle exec rspec spec/system
```

To run an individual file you can use for example:

```shell
bundle exec rspec spec/system/user_views_a_reading_list_spec.rb
```

To run a specific test case you can use for example:

```shell
bundle exec rspec spec/system/user_views_a_reading_list_spec.rb:10
```

where `10` is the line number of the test case you want to execute.

You can read the official guide [Testing Rails Applications](https://guides.rubyonrails.org/testing.html#system-testing) to learn more.
