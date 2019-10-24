---
title: Preparing the Database
---

# Preparing the database

The next step is to create and prepare the database. Because DEV is a
Rails application, we have built-in tools to help us.

We can use Rails to create our database, load the schema, and add some seed
data:

```shell
rails db:setup
```

Note: If you've already run `bin/setup`, this will have already been done for you.

`db:setup` actually runs the following rake commands in order so
alternatively, you could run each of these to produce the same result:

```shell
rails db:create
rails db:schema:load
rails db:seed
```
