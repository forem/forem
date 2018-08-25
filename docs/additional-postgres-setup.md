# Setup your application with PostgreSQL

Follow the instructions in the installation guide below that corresponds to your operating system:

1.  macOS
    * [Postgres.app](https://postgresapp.com/): PostgreSQL installation as a Mac app
    * [Homebrew](https://brew.sh/): if you use Homebrew you can easily install PostgreSQL with `brew install postgresql`
2.  Linux (Ubuntu)
    * [Ubuntu `14.04`](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-14-04)
    * [Ubuntu `16.04 and higher`](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04)
3.  [Windows](https://www.postgresql.org/download/windows/)

_You can find all installation options for a variety of operating systems [on the official PostgreSQL download page](https://www.postgresql.org/download/)_.

## Configuration

By default the application is configured to connect to a local database named `PracticalDeveloper_development`. If you need to specify a username and a password you can go about it two ways: using the environment variable `DATABASE_URL` (preferred method) or modifying the file `database.yml`.

### Setup `DATABASE_URL` in application.yml

1.  Open your `config/application.yml`

2.  Add the following:

```yml
DATABASE_URL: postgresql://USERNAME:PASSWORD@localhost/PracticalDeveloper_development
```

3.  Replace `USERNAME` with your database username, `PASSWORD` with your database password.

### Modify connection params in `database.yml`

The other option is to change the `database.yml` directly.

Update your `database.yml` file with `username` and `password`:

```yaml
development:
    <<: *default
    username: USERNAME
    password: PASSWORD
test:
    <<: *default
    username: USERNAME
    password: PASSWORD
```

**Keep in mind not to commit `database.yml` under any circumstances to any repository.**

## Troubleshooting tests

* While running test cases, if you get an error message `postgresql connection timeout`. Go to your `spec/support/database_cleaner.rb` file. And rename `:truncation` with `:deletion`.

_Please, do not commit `database_cleaner.rb` to the repository either._
