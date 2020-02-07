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

## How do I fix the Error `role "ec2-user" does not exist` on an AWS instance?

After installing and configuring PostgreSQL on an AWS EC2 (or AWS Cloud9)
instance and running `bin/setup`, this error could occur.

To fix it, run the following two commands in a terminal (assuming your
PostgreSQL user is named **postgres**):

```
sudo -u postgres createuser -s ec2-user
sudo -u postgres createdb ec2-user
```

The first command creates the user **ec2-user** and the second one creates the
database for this user because every user needs its database. Even if the first
command fails, run the second command to create the missing database.
