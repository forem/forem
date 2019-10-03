---
title: Preparing the Database
---

# Preparing the database

The next step is to create and prepare the database. Thankfully, DEV is a
Rails application, so this is relatively easy.

We can use Rails to create our database, load the schema, and add some seed
data:

```shell
rails db:setup
```

`db:setup` actually runs the following rake commands in order so
alternatively, you could run each of these to produce the same result:

```shell
rails db:create
rails db:schema:load
rails db:seed
```
