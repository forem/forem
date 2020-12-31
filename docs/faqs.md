---
title: FAQs
---

# Frequently Asked Questions

## How do I log in after starting up Forem for the first time?

Seeding the database create an admin user (see
[Database](/getting-started/db/#default-admin-user)) with the following
credentials:

```
email: admin@forem.local
password: password
```

Once logged in as this admin user, you can turn on any authentication methods
you'd like (see [Authentication](/backend/authentication/))

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

## How do I see comments in the Feed?

On the home Feed, we only show comments above certain "score". It's likely the
comments in the local environment will never meet this score. If you want to see
comments locally, you will need to update the score of your local comments
manually. Here's how:

1. Open the terminal.
2. Run `rails dbconsole` to open the PostgreSQL terminal. Alternatively, run
   `psql PracticalDeveloper_development` to open `psql`, the PostgreSQL
   terminal.
3. Enter `update comments set score = 30;`.
4. Type `exit` to leave the PostgreSQL terminal.

> Note: dbconsole reads database information from config/database.yml which is
> always better since database configs might change in the future.

Once you refresh the app, you should be able to see some comments in the Feed.

## How do I make someone follow me on my local environment?

In certain cases, for example when testing various functionalities, you may need
to be able to make some user follow you. Here's how:

1. Open the rails console by running `rails c` in your terminal.
2. Get any user you want to follow you, for example `user = User.first`.
3. Then make this user follow you: `user.follow(your_username)`.

Boom, you have a new follower!

## How do I remove / leave organization I created?

1. Open the rails console by running `rails c` in your terminal.
2. Enter the following commands:
   ```ruby
   user = User.find_by(username: "your_username")
   organization_id = Organization.find_by(slug: "organization_slug").id
   user.organization_memberships.where(organization_id: organization_id).destroy_all
   ```

## How do I add credits to my account?

If you ever want to add Listings locally, you must have credits on your account
to "pay" for listing. Here's how:

1. Open the rails console `rails console`.
2. Enter the following commands:

   ```ruby
   user = User.find_by(username: "your_username")
   Credit.add_to(user, 1000)
   ```

^ This will add 1000 credits to your account. But you know, you can't really buy
anything with it :D
