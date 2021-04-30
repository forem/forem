---
title: Troubleshooting
---

## Tests

### Connection timeout

While running test cases, if you get an error message
`postgresql connection timeout`, please re-run the tests by increasing the
statement timeout, for example:

```shell
STATEMENT_TIMEOUT=10000 bundle exec rspec
```

## PostgreSQL

### How do I fix the Error `role "ec2-user" does not exist` on an AWS instance?

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

## CORS

If you are experiencing CORS issues locally or need to display more information
about the CORS headers, add the following variable to your `.env`:

```shell
export DEBUG_CORS=true
```
