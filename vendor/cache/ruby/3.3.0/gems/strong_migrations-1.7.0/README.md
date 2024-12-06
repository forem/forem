# Strong Migrations

Catch unsafe migrations in development

&nbsp;&nbsp;✓&nbsp;&nbsp;Detects potentially dangerous operations<br />&nbsp;&nbsp;✓&nbsp;&nbsp;Prevents them from running by default<br />&nbsp;&nbsp;✓&nbsp;&nbsp;Provides instructions on safer ways to do what you want

Supports PostgreSQL, MySQL, and MariaDB

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

[![Build Status](https://github.com/ankane/strong_migrations/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/strong_migrations/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "strong_migrations"
```

And run:

```sh
bundle install
rails generate strong_migrations:install
```

Strong Migrations sets a long statement timeout for migrations so you can set a [short statement timeout](#app-timeouts) for your application.

## How It Works

When you run a migration that’s potentially dangerous, you’ll see an error message like:

```txt
=== Dangerous operation detected #strong_migrations ===

Active Record caches attributes, which causes problems
when removing columns. Be sure to ignore the column:

class User < ApplicationRecord
  self.ignored_columns = ["name"]
end

Deploy the code, then wrap this step in a safety_assured { ... } block.

class RemoveColumn < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :users, :name }
  end
end
```

An operation is classified as dangerous if it either:

- Blocks reads or writes for more than a few seconds (after a lock is acquired)
- Has a good chance of causing application errors

## Checks

Potentially dangerous operations:

- [removing a column](#removing-a-column)
- [adding a column with a default value](#adding-a-column-with-a-default-value)
- [backfilling data](#backfilling-data)
- [adding a stored generated column](#adding-a-stored-generated-column)
- [changing the type of a column](#changing-the-type-of-a-column)
- [renaming a column](#renaming-a-column)
- [renaming a table](#renaming-a-table)
- [creating a table with the force option](#creating-a-table-with-the-force-option)
- [adding a check constraint](#adding-a-check-constraint)
- [executing SQL directly](#executing-SQL-directly)

Postgres-specific checks:

- [adding an index non-concurrently](#adding-an-index-non-concurrently)
- [adding a reference](#adding-a-reference)
- [adding a foreign key](#adding-a-foreign-key)
- [adding a unique constraint](#adding-a-unique-constraint)
- [adding an exclusion constraint](#adding-an-exclusion-constraint)
- [adding a json column](#adding-a-json-column)
- [setting NOT NULL on an existing column](#setting-not-null-on-an-existing-column)

Config-specific checks:

- [changing the default value of a column](#changing-the-default-value-of-a-column)

Best practices:

- [keeping non-unique indexes to three columns or less](#keeping-non-unique-indexes-to-three-columns-or-less)

You can also add [custom checks](#custom-checks) or [disable specific checks](#disable-checks).

### Removing a column

#### Bad

Active Record caches database columns at runtime, so if you drop a column, it can cause exceptions until your app reboots.

```ruby
class RemoveSomeColumnFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :some_column
  end
end
```

#### Good

1. Tell Active Record to ignore the column from its cache

  ```ruby
  class User < ApplicationRecord
    self.ignored_columns = ["some_column"]
  end
  ```

2. Deploy the code
3. Write a migration to remove the column (wrap in `safety_assured` block)

  ```ruby
  class RemoveSomeColumnFromUsers < ActiveRecord::Migration[7.1]
    def change
      safety_assured { remove_column :users, :some_column }
    end
  end
  ```

4. Deploy and run the migration
5. Remove the line added in step 1

### Adding a column with a default value

#### Bad

In earlier versions of Postgres, MySQL, and MariaDB, adding a column with a default value to an existing table causes the entire table to be rewritten. During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :some_column, :text, default: "default_value"
  end
end
```

In Postgres 11+, MySQL 8.0.12+, and MariaDB 10.3.2+, this no longer requires a table rewrite and is safe (except for volatile functions like `gen_random_uuid()`).

#### Good

Instead, add the column without a default value, then change the default.

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :some_column, :text
    change_column_default :users, :some_column, "default_value"
  end

  def down
    remove_column :users, :some_column
  end
end
```

See the next section for how to backfill.

### Backfilling data

#### Bad

Active Record creates a transaction around each migration, and backfilling in the same transaction that alters a table keeps the table locked for the [duration of the backfill](https://wework.github.io/data/2015/11/05/add-columns-with-default-values-to-large-tables-in-rails-postgres/).

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :some_column, :text
    User.update_all some_column: "default_value"
  end
end
```

Also, running a single query to update data can cause issues for large tables.

#### Good

There are three keys to backfilling safely: batching, throttling, and running it outside a transaction. Use the Rails console or a separate migration with `disable_ddl_transaction!`.

```ruby
class BackfillSomeColumn < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    User.unscoped.in_batches do |relation|
      relation.update_all some_column: "default_value"
      sleep(0.01) # throttle
    end
  end
end
```

### Adding a stored generated column

#### Bad

Adding a stored generated column causes the entire table to be rewritten. During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :some_column, :virtual, type: :string, as: "...", stored: true
  end
end
```

#### Good

Add a non-generated column and use callbacks or triggers instead (or a virtual generated column with MySQL and MariaDB).

### Changing the type of a column

#### Bad

Changing the type of a column causes the entire table to be rewritten. During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.

```ruby
class ChangeSomeColumnType < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :some_column, :new_type
  end
end
```

Some changes don’t require a table rewrite and are safe in Postgres:

Type | Safe Changes
--- | ---
`cidr` | Changing to `inet`
`citext` | Changing to `text` if not indexed, changing to `string` with no `:limit` if not indexed
`datetime` | Increasing or removing `:precision`, changing to `timestamptz` when session time zone is UTC in Postgres 12+
`decimal` | Increasing `:precision` at same `:scale`, removing `:precision` and `:scale`
`interval` | Increasing or removing `:precision`
`numeric` | Increasing `:precision` at same `:scale`, removing `:precision` and `:scale`
`string` | Increasing or removing `:limit`, changing to `text`, changing `citext` if not indexed
`text` | Changing to `string` with no `:limit`, changing to `citext` if not indexed
`time` | Increasing or removing `:precision`
`timestamptz` | Increasing or removing `:limit`, changing to `datetime` when session time zone is UTC in Postgres 12+

And some in MySQL and MariaDB:

Type | Safe Changes
--- | ---
`string` | Increasing `:limit` from under 63 up to 63, increasing `:limit` from over 63 to the max (the threshold can be different if using an encoding other than `utf8mb4` - for instance, it’s 85 for `utf8mb3` and 255 for `latin1`)

#### Good

A safer approach is to:

1. Create a new column
2. Write to both columns
3. Backfill data from the old column to the new column
4. Move reads from the old column to the new column
5. Stop writing to the old column
6. Drop the old column

### Renaming a column

#### Bad

Renaming a column that’s in use will cause errors in your application.

```ruby
class RenameSomeColumn < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :some_column, :new_name
  end
end
```

#### Good

A safer approach is to:

1. Create a new column
2. Write to both columns
3. Backfill data from the old column to the new column
4. Move reads from the old column to the new column
5. Stop writing to the old column
6. Drop the old column

### Renaming a table

#### Bad

Renaming a table that’s in use will cause errors in your application.

```ruby
class RenameUsersToCustomers < ActiveRecord::Migration[7.1]
  def change
    rename_table :users, :customers
  end
end
```

#### Good

A safer approach is to:

1. Create a new table
2. Write to both tables
3. Backfill data from the old table to the new table
4. Move reads from the old table to the new table
5. Stop writing to the old table
6. Drop the old table

### Creating a table with the force option

#### Bad

The `force` option can drop an existing table.

```ruby
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, force: true do |t|
      # ...
    end
  end
end
```

#### Good

Create tables without the `force` option.

```ruby
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # ...
    end
  end
end
```

If you intend to drop an existing table, run `drop_table` first.

### Adding a check constraint

:turtle: Safe by default available

#### Bad

Adding a check constraint blocks reads and writes in Postgres and blocks writes in MySQL and MariaDB while every row is checked.

```ruby
class AddCheckConstraint < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :users, "price > 0", name: "price_check"
  end
end
```

#### Good - Postgres

Add the check constraint without validating existing rows:

```ruby
class AddCheckConstraint < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :users, "price > 0", name: "price_check", validate: false
  end
end
```

Then validate them in a separate migration.

```ruby
class ValidateCheckConstraint < ActiveRecord::Migration[7.1]
  def change
    validate_check_constraint :users, name: "price_check"
  end
end
```

#### Good - MySQL and MariaDB

[Let us know](https://github.com/ankane/strong_migrations/issues/new) if you have a safe way to do this (check constraints can be added with `NOT ENFORCED`, but enforcing blocks writes).

### Executing SQL directly

Strong Migrations can’t ensure safety for raw SQL statements. Make really sure that what you’re doing is safe, then use:

```ruby
class ExecuteSQL < ActiveRecord::Migration[7.1]
  def change
    safety_assured { execute "..." }
  end
end
```

### Adding an index non-concurrently

:turtle: Safe by default available

#### Bad

In Postgres, adding an index non-concurrently blocks writes.

```ruby
class AddSomeIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :some_column
  end
end
```

#### Good

Add indexes concurrently.

```ruby
class AddSomeIndexToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :users, :some_column, algorithm: :concurrently
  end
end
```

If you forget `disable_ddl_transaction!`, the migration will fail. Also, note that indexes on new tables (those created in the same migration) don’t require this.

With [gindex](https://github.com/ankane/gindex), you can generate an index migration instantly with:

```sh
rails g index table column
```

### Adding a reference

:turtle: Safe by default available

#### Bad

Rails adds an index non-concurrently to references by default, which blocks writes in Postgres.

```ruby
class AddReferenceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :city
  end
end
```

#### Good

Make sure the index is added concurrently.

```ruby
class AddReferenceToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :users, :city, index: {algorithm: :concurrently}
  end
end
```

### Adding a foreign key

:turtle: Safe by default available

#### Bad

In Postgres, adding a foreign key blocks writes on both tables.

```ruby
class AddForeignKeyOnUsers < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :users, :orders
  end
end
```

or

```ruby
class AddReferenceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :order, foreign_key: true
  end
end
```

#### Good

Add the foreign key without validating existing rows:

```ruby
class AddForeignKeyOnUsers < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :users, :orders, validate: false
  end
end
```

Then validate them in a separate migration.

```ruby
class ValidateForeignKeyOnUsers < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :users, :orders
  end
end
```

### Adding a unique constraint

#### Bad

In Postgres, adding a unique constraint creates a unique index, which blocks reads and writes.

```ruby
class AddUniqueContraint < ActiveRecord::Migration[7.1]
  def change
    add_unique_constraint :users, :some_column
  end
end
```

#### Good

Create a unique index concurrently, then use it for the constraint.

```ruby
class AddUniqueContraint < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :users, :some_column, unique: true, algorithm: :concurrently
    add_unique_constraint :users, using_index: "index_users_on_some_column"
  end

  def down
    remove_unique_constraint :users, :some_column
  end
end
```

### Adding an exclusion constraint

#### Bad

In Postgres, adding an exclusion constraint blocks reads and writes while every row is checked.

```ruby
class AddExclusionContraint < ActiveRecord::Migration[7.1]
  def change
    add_exclusion_constraint :users, "number WITH =", using: :gist
  end
end
```

#### Good

[Let us know](https://github.com/ankane/strong_migrations/issues/new) if you have a safe way to do this (exclusion constraints cannot be marked `NOT VALID`).

### Adding a json column

#### Bad

In Postgres, there’s no equality operator for the `json` column type, which can cause errors for existing `SELECT DISTINCT` queries in your application.

```ruby
class AddPropertiesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :properties, :json
  end
end
```

#### Good

Use `jsonb` instead.

```ruby
class AddPropertiesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :properties, :jsonb
  end
end
```

### Setting NOT NULL on an existing column

:turtle: Safe by default available

#### Bad

In Postgres, setting `NOT NULL` on an existing column blocks reads and writes while every row is checked.

```ruby
class SetSomeColumnNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :some_column, false
  end
end
```

#### Good

Instead, add a check constraint.

For Rails 6.1+, use:

```ruby
class SetSomeColumnNotNull < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :users, "some_column IS NOT NULL", name: "users_some_column_null", validate: false
  end
end
```

For Rails < 6.1, use:

```ruby
class SetSomeColumnNotNull < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      execute 'ALTER TABLE "users" ADD CONSTRAINT "users_some_column_null" CHECK ("some_column" IS NOT NULL) NOT VALID'
    end
  end
end
```

Then validate it in a separate migration. A `NOT NULL` check constraint is [functionally equivalent](https://medium.com/doctolib/adding-a-not-null-constraint-on-pg-faster-with-minimal-locking-38b2c00c4d1c) to setting `NOT NULL` on the column (but it won’t show up in `schema.rb` in Rails < 6.1). In Postgres 12+, once the check constraint is validated, you can safely set `NOT NULL` on the column and drop the check constraint.

For Rails 6.1+, use:

```ruby
class ValidateSomeColumnNotNull < ActiveRecord::Migration[7.1]
  def change
    validate_check_constraint :users, name: "users_some_column_null"

    # in Postgres 12+, you can then safely set NOT NULL on the column
    change_column_null :users, :some_column, false
    remove_check_constraint :users, name: "users_some_column_null"
  end
end
```

For Rails < 6.1, use:

```ruby
class ValidateSomeColumnNotNull < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      execute 'ALTER TABLE "users" VALIDATE CONSTRAINT "users_some_column_null"'
    end

    # in Postgres 12+, you can then safely set NOT NULL on the column
    change_column_null :users, :some_column, false
    safety_assured do
      execute 'ALTER TABLE "users" DROP CONSTRAINT "users_some_column_null"'
    end
  end
end
```

### Changing the default value of a column

#### Bad

Rails < 7 enables partial writes by default, which can cause incorrect values to be inserted when changing the default value of a column.

```ruby
class ChangeSomeColumnDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :some_column, from: "old", to: "new"
  end
end

User.create!(some_column: "old") # can insert "new"
```

#### Good

Disable partial writes in `config/application.rb`. For Rails < 7, use:

```ruby
config.active_record.partial_writes = false
```

For Rails 7+, use:

```ruby
config.active_record.partial_inserts = false
```

### Keeping non-unique indexes to three columns or less

#### Bad

Adding a non-unique index with more than three columns rarely improves performance.

```ruby
class AddSomeIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, [:a, :b, :c, :d]
  end
end
```

#### Good

Instead, start an index with columns that narrow down the results the most.

```ruby
class AddSomeIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, [:b, :d]
  end
end
```

For Postgres, be sure to add them concurrently.

## Assuring Safety

To mark a step in the migration as safe, despite using a method that might otherwise be dangerous, wrap it in a `safety_assured` block.

```ruby
class MySafeMigration < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :users, :some_column }
  end
end
```

Certain methods like `execute` and `change_table` cannot be inspected and are prevented from running by default. Make sure what you’re doing is really safe and use this pattern.

## Safe by Default

Make operations safe by default.

- adding and removing an index
- adding a foreign key
- adding a check constraint
- setting NOT NULL on an existing column

Add to `config/initializers/strong_migrations.rb`:

```ruby
StrongMigrations.safe_by_default = true
```

## Custom Checks

Add your own custom checks with:

```ruby
StrongMigrations.add_check do |method, args|
  if method == :add_index && args[0].to_s == "users"
    stop! "No more indexes on the users table"
  end
end
```

Use the `stop!` method to stop migrations.

Note: Since `remove_column` always requires a `safety_assured` block, it’s not possible to add a custom check for `remove_column` operations.

## Opt-in Checks

### Removing an index non-concurrently

Postgres supports removing indexes concurrently, but removing them non-concurrently shouldn’t be an issue for most applications. You can enable this check with:

```ruby
StrongMigrations.enable_check(:remove_index)
```

## Disable Checks

Disable specific checks with:

```ruby
StrongMigrations.disable_check(:add_index)
```

Check the [source code](https://github.com/ankane/strong_migrations/blob/master/lib/strong_migrations/error_messages.rb) for the list of keys.

## Down Migrations / Rollbacks

By default, checks are disabled when migrating down. Enable them with:

```ruby
StrongMigrations.check_down = true
```

## Custom Messages

To customize specific messages, create an initializer with:

```ruby
StrongMigrations.error_messages[:add_column_default] = "Your custom instructions"
```

Check the [source code](https://github.com/ankane/strong_migrations/blob/master/lib/strong_migrations/error_messages.rb) for the list of keys.

## Migration Timeouts

It’s extremely important to set a short lock timeout for migrations. This way, if a migration can’t acquire a lock in a timely manner, other statements won’t be stuck behind it. We also recommend setting a long statement timeout so migrations can run for a while.

Create `config/initializers/strong_migrations.rb` with:

```ruby
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour
```

Or set the timeouts directly on the database user that runs migrations. For Postgres, use:

```sql
ALTER ROLE myuser SET lock_timeout = '10s';
ALTER ROLE myuser SET statement_timeout = '1h';
```

Note: If you use PgBouncer in transaction mode, you must set timeouts on the database user.

## App Timeouts

We recommend adding timeouts to `config/database.yml` to prevent connections from hanging and individual queries from taking up too many resources in controllers, jobs, the Rails console, and other places.

For Postgres:

```yml
production:
  connect_timeout: 5
  variables:
    statement_timeout: 15s
    lock_timeout: 10s
```

Note: If you use PgBouncer in transaction mode, you must set the statement and lock timeouts on the database user as shown above.

For MySQL:

```yml
production:
  connect_timeout: 5
  read_timeout: 5
  write_timeout: 5
  variables:
    max_execution_time: 15000 # ms
    lock_wait_timeout: 10 # sec

```

For MariaDB:

```yml
production:
  connect_timeout: 5
  read_timeout: 5
  write_timeout: 5
  variables:
    max_statement_time: 15 # sec
    lock_wait_timeout: 10 # sec
```

For HTTP connections, Redis, and other services, check out [this guide](https://github.com/ankane/the-ultimate-guide-to-ruby-timeouts).

## Lock Timeout Retries [experimental]

There’s the option to automatically retry statements for migrations when the lock timeout is reached. Here’s how it works:

- If a lock timeout happens outside a transaction, the statement is retried
- If it happens inside the DDL transaction, the entire migration is retried (only applicable to Postgres)

Add to `config/initializers/strong_migrations.rb`:

```ruby
StrongMigrations.lock_timeout_retries = 3
```

Set the delay between retries with:

```ruby
StrongMigrations.lock_timeout_retry_delay = 10.seconds
```

## Existing Migrations

To mark migrations as safe that were created before installing this gem, create an initializer with:

```ruby
StrongMigrations.start_after = 20230101000000
```

Use the version from your latest migration.

## Target Version

If your development database version is different from production, you can specify the production version so the right checks run in development.

```ruby
StrongMigrations.target_version = 10 # or "8.0.12", "10.3.2", etc
```

The major version works well for Postgres, while the full version is recommended for MySQL and MariaDB.

For safety, this option only affects development and test environments. In other environments, the actual server version is always used.

If your app has multiple databases with different versions, with Rails 6.1+, you can use:

```ruby
StrongMigrations.target_version = {primary: 13, catalog: 15}
```

## Analyze Tables

Analyze tables automatically (to update planner statistics) after an index is added. Create an initializer with:

```ruby
StrongMigrations.auto_analyze = true
```

## Faster Migrations

Only dump the schema when adding a new migration. If you use Git, add to `config/environments/development.rb`:

```rb
config.active_record.dump_schema_after_migration = `git status db/migrate/ --porcelain`.present?
```

## Schema Sanity

Columns can flip order in `db/schema.rb` when you have multiple developers. One way to prevent this is to [alphabetize them](https://www.pgrs.net/2008/03/12/alphabetize-schema-rb-columns/). Add to `config/initializers/strong_migrations.rb`:

```ruby
StrongMigrations.alphabetize_schema = true
```

## Permissions

We recommend using a [separate database user](https://ankane.org/postgres-users) for migrations when possible so you don’t need to grant your app user permission to alter tables.

## Smaller Projects

You probably don’t need this gem for smaller projects, as operations that are unsafe at scale can be perfectly safe on smaller, low-traffic tables.

## Additional Reading

- [Rails Migrations with No Downtime](https://pedro.herokuapp.com/past/2011/7/13/rails_migrations_with_no_downtime/)
- [PostgreSQL at Scale: Database Schema Changes Without Downtime](https://medium.com/braintree-product-technology/postgresql-at-scale-database-schema-changes-without-downtime-20d3749ed680)
- [An Overview of DDL Algorithms in MySQL](https://mydbops.wordpress.com/2020/03/04/an-overview-of-ddl-algorithms-in-mysql-covers-mysql-8/)
- [MariaDB InnoDB Online DDL Overview](https://mariadb.com/kb/en/innodb-online-ddl-overview/)

## Credits

Thanks to Bob Remeika and David Waller for the [original code](https://github.com/foobarfighter/safe-migrations) and [Sean Huber](https://github.com/LendingHome/zero_downtime_migrations) for the bad/good readme format.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/strong_migrations/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/strong_migrations/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/strong_migrations.git
cd strong_migrations
bundle install

# Postgres
createdb strong_migrations_test
bundle exec rake test

# MySQL and MariaDB
mysqladmin create strong_migrations_test
ADAPTER=mysql2 bundle exec rake test
```
