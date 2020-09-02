---
title: FAQs
---

# Frequently Asked Questions

## How do I build my local copy of the Ruby source code documentation?

```shell
cd docs
make ruby-doc
```

Then open `.static/ruby-doc/index.html` in the `docs` directory and browse the
Ruby documentation

## How do I enable logging to standard output in development?

By default Rails logs to `log.development.log`.

If, instead, you wish to log to `STDOUT` you can add the variable:

```shell
export RAILS_LOG_TO_STDOUT=true
```

to your own `.env` file.

## How can I see comments in the Feed?

In the Feed we only show comments above certain "score". It's likely the
comments in the local environment will never meet this score that's why it must
be updated manually. Here's how:

1. Open the terminal
2. Run `psql PracticalDeveloper_development`
3. Enter `update comments set score = 30;`
4. Hit `exit`

Once you refresh the page, you should be able to see some comments in the Feed.

## How can I make someone follow me on local environment?

In certain cases, for example when testing various functionlities, you may need
to be able to make some user follow you. Here's how:

1. Open the rails console with `rails c`
2. Get any user with you want to follow you, for example `user = User.first`
3. Then make this user follow you: `user.follow(john_doe)`

Boom, you have a new follower!
