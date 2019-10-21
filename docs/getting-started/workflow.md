---
title: Suggested Workflow
---

# Suggested workflow

We use [Spring](https://github.com/rails/spring), and it is already included in the project.

1.  Use the provided bin stubs to automatically start Spring, i.e. `bin/rails server`, `bin/rspec spec/models/`, `bin/rails db:migrate`.
1.  If Spring isn't picking up on new changes, use `spring stop`. For example, Spring should always be restarted if there's a change in the environment keys.
1.  Check Spring's status whenever with `spring status`.

Caveat: `bin/rspec` is not equipped with Spring because it affects Simplecov's result. Instead, use `bin/spring rspec`.
