---
title: PostgreSQL
---

# Setup your application with PostgreSQL

Follow the instructions in the installation guide below that corresponds to your
operating system:

1. macOS
   - [Postgres.app](https://postgresapp.com/): PostgreSQL installation as a Mac
     app
   - [Homebrew](https://brew.sh/): if you use Homebrew you can easily install
     PostgreSQL with `brew install postgresql`
1. Linux (Ubuntu)
   - [Ubuntu `14.04`](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-14-04)
   - [Ubuntu `16.04 and higher`](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04)
1. [Windows](https://www.postgresql.org/download/windows/)

_You can find all installation options for a variety of operating systems
[on the official PostgreSQL download page](https://www.postgresql.org/download/)_.

## Configuration

By default, the application is configured to connect to a local database named
`PracticalDeveloper_development`. If you need to specify a username and a
password, you can go about it by using the environment variable `DATABASE_URL`
with a connection string.

The
[official Rails guides](https://guides.rubyonrails.org/configuring.html#connection-preference)
go into depth on how Rails merges the existing `database.yml` with the
connection string.

### Setup `DATABASE_URL` in application.yml

1. Open your `config/application.yml`

1. Add the following:

```yml
DATABASE_URL: postgresql://USERNAME:PASSWORD@localhost
```

1. Replace `USERNAME` with your database username, `PASSWORD` with your database
   password.

You can find more details on connection strings in
[PostgreSQL's own documentation](https://www.postgresql.org/docs/10/static/libpq-connect.html#LIBPQ-CONNSTRING).

NOTE: due to how Rails merges `database.yml` and `DATABASE_URL` it's recommended
not to add the database name in the connection string. This will default to your
development database name also during tests, which will effectively empty the
development DB each time tests are run.

## Connection Pooling

We use [PgBouncer](http://www.pgbouncer.org) to manage connection pooling.

Database pooling creates a shared pool of connections to our database, rather
than creating new connection each time. PgBouncer is a wrapper around our
database connection and ensures that we only have a finite set of "cached"
connections to the database. This means that our app doesn't need to actually
connect to the database, it only needs to connect to the pool of connections.
The number of connections to the database (the connection limit) is dependent on
our
[Heroku Postgres plan](https://devcenter.heroku.com/articles/heroku-postgres-plans).
PgBouncer ensures that we do not exceed our plan's connection limit.
