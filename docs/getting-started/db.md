---
title: Preparing the Database
---

# Preparing the database

The next step is to create and prepare the database. Because DEV is a Rails
application, we have built-in tools to help us.

We can use Rails to create our database, load the schema, and add some seed
data:

```shell
rails db:setup
```

Note: If you've already run `bin/setup`, this will have already been done for
you.

`db:setup` actually runs the following rake commands in order so alternatively,
you could run each of these to produce the same result:

```shell
rails db:create
rails db:schema:load
rails db:seed
```

## Seed Data

By default, the amount of articles and users generated is quite tiny so that
contributors experience a quick installation. If you require more data for your
local installation, you can tune amount of data generated with the environment
variable `SEEDS_MULTIPLIER`.

This variable, which defaults to `1`, allows the developer to increase the size
of their local DB. For example:

```shell
SEEDS_MULTIPLIER=2 rails db:setup
```

will result in creating double the default amount of items in the database.

It's currently used only for `articles` and `users`.

It can also be used for `rails db:seed` and `rails db:reset`.
