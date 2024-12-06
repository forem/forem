# Hypershield

:zap: Shield sensitive data in Postgres and MySQL

Great for business intelligence tools like [Blazer](https://github.com/ankane/blazer)

[![Build Status](https://github.com/ankane/hypershield/workflows/build/badge.svg?branch=master)](https://github.com/ankane/hypershield/actions)

## How It Works

Hypershield creates *shielded views* (in the `hypershield` schema by default) that hide sensitive tables and columns. The advantage of this approach over column-level privileges is you can use `SELECT *`.

By default, it hides columns with:

- `encrypted`
- `password`
- `token`
- `secret`

Give database users access to these views instead of the original tables.

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'hypershield'
```

And run:

```sh
rails generate hypershield:install
```

Hypershield is disabled in non-production environments by default. You can do a dry run with:

```sh
rake hypershield:refresh:dry_run
```

Next, set up your production database.

- [Postgres](#postgres)
- [MySQL](#mysql)

When that’s done, deploy to production and run:

```sh
rails db:migrate
```

The schema will automatically refresh.

## Database Setup

### Postgres

Create a new schema in your database

```sql
CREATE SCHEMA hypershield;
```

Grant privileges

```sql
GRANT USAGE ON SCHEMA hypershield TO myuser;

-- replace migrations with the user who manages your schema
ALTER DEFAULT PRIVILEGES FOR ROLE migrations IN SCHEMA hypershield
    GRANT SELECT ON TABLES TO myuser;

-- keep public in search path for functions
ALTER ROLE myuser SET search_path TO hypershield, public;
```

And connect as the user and make sure there’s no access the original tables

```sql
SELECT * FROM public.users LIMIT 1;
```

### MySQL

Create a new schema in your database

```sql
CREATE SCHEMA hypershield;
```

Grant privileges

```sql
GRANT SELECT, SHOW VIEW ON hypershield.* TO myuser;
FLUSH PRIVILEGES;
```

And connect as the user and make sure there’s no access the original tables

```sql
SELECT * FROM mydb.users LIMIT 1;
```

## Configuration

Set configuration in `config/initializers/hypershield.rb`.

Specify the schema to use and columns to show and hide

```ruby
Hypershield.schemas = {
  hypershield: {
    hide: ["encrypted", "password", "token", "secret"],
    show: ["ahoy_visits.visitor_token", "ahoy_visits.visit_token"]
  }
}
```

Log Hypershield SQL statements

```ruby
Hypershield.log_sql = true
```

Enable or disable Hypershield in an environment

```ruby
Hypershield.enabled = Rails.env.production?
```

## History

View the [changelog](CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/hypershield/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/hypershield/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/hypershield.git
cd hypershield
bundle install

# Postgres
createdb hypershield_test
bundle exec rake test

# MySQL
mysqladmin create hypershield_test
ADAPTER=mysql2 bundle exec rake test
```
