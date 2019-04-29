---
title: Preparing the Database
---

# Preparing the Database

We need to create our database, load the database schema, and load seed
data. This can be accomplished with:

`rake db:setup`

`db:setup` actually runs the following rake commands in order so
you could alternatively run each of these to produce the same result.

```
rake db:create
rake db:schema:load
rake db:seed
```
