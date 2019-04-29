---
title: Preparing the Database
---

# Preparing the database

We need to create our database, load the database schema, and load seed
data. This can be accomplished with:

```shell
rails db:setup
```

`db:setup` actually runs the following rake commands in order so
you could alternatively run each of these to produce the same result.

```shell
rails db:create
rails db:schema:load
rails db:seed
```
