---
title: Acceptance Tests
---

# Acceptance Tests

Acceptance tests are tests from the perspective of the end-user.

In the Rails world, we sometimes refer to these as Feature or System tests. In
Rails 5.1, a tool called Capybara was included to help us simulate a human's
actions inside of our tests.

Generally, we are simulating what a user could do from their web browser and
ensuring that the app behaves as intended.

When a feature is heavily reliant on interaction from a user via the browser,
it's a good idea to write automated Acceptance tests to uncover any bugs that
might not be apparent from manual testing. It's important to note that Rails
System tests can be fairly slow, so it's better to focus on testing core
functionality or pieces of your code that you think might be prone to
regressions.

Acceptance tests can be found in the directory `spec/system`.

You can run all acceptance tests with:

```shell
bundle exec rspec spec/system
```

To run an individual file you can use:

```shell
bundle exec rspec spec/system/user_views_a_reading_list_spec.rb
```

To run a specific test case you can use:

```shell
bundle exec rspec spec/system/user_views_a_reading_list_spec.rb:10
```

where `10` is the line number of the test case that you want to execute.

You can read the official guide
[Testing Rails Applications](https://guides.rubyonrails.org/testing.html#system-testing)
to learn more.
