## 1.7.0 (2024-01-05)

- Added check for `add_unique_constraint`

## 1.6.4 (2023-10-17)

- Fixed false positives with `revert`

## 1.6.3 (2023-09-20)

- Added support for Trilogy

## 1.6.2 (2023-09-13)

- Fixed foreign key options with `add_reference` and `safe_by_default`
- Fixed `safety_assured` with `revert`

## 1.6.1 (2023-08-09)

- Fixed `safety_assured` for custom checks with `safe_by_default`

## 1.6.0 (2023-07-22)

- Added check for `change_column_default`

## 1.5.0 (2023-07-02)

- Added check for `add_column` with stored generated columns
- Fixed `add_reference` with `foreign_key` and `index: false`

## 1.4.4 (2023-03-08)

- Fixed `add_foreign_key` with `name` and `column` options with `safe_by_default`

## 1.4.3 (2023-02-19)

- Fixed check for `change_column` to account for charset with MySQL and MariaDB

## 1.4.2 (2023-01-29)

- Added `alphabetize_schema` option

## 1.4.1 (2023-01-05)

- Added support for multiple databases to `target_version`

## 1.4.0 (2022-10-31)

- Added check for `add_exclusion_constraint`
- Added support for `RACK_ENV`
- Fixed error when `Rails` defined without `Rails.env`
- Fixed error with `change_column_null` when table does not exist

## 1.3.2 (2022-10-09)

- Improved error message for `add_column` with `default: nil` with Postgres 10

## 1.3.1 (2022-09-21)

- Fixed check for `add_column` with `default: nil` with Postgres 10

## 1.3.0 (2022-08-30)

- Added check for `add_column` with `uuid` type and volatile default value

## 1.2.0 (2022-06-10)

- Added check for index corruption with Postgres 14.0 to 14.3

## 1.1.0 (2022-06-08)

- Added check for `force` option with `create_join_table`
- Improved errors for extra arguments
- Fixed ignoring extra arguments with `safe_by_default`
- Fixed missing options with `remove_index` and `safe_by_default`

## 1.0.0 (2022-03-21)

New safe operations with MySQL and MariaDB

- Setting `NOT NULL` on an existing column with strict mode enabled

New safe operations with Postgres

- Changing between `text` and `citext` when not indexed
- Changing a `string` column to a `citext` column when not indexed
- Changing a `citext` column to a `string` column with no `:limit` when not indexed
- Changing a `cidr` column to an `inet` column
- Increasing `:precision` of an `interval` or `time` column

New unsafe operations with Postgres

- Adding a column with a callable default value
- Decreasing `:precision` of a `datetime` column
- Decreasing `:limit` of a `timestamptz` column
- Passing a default value to `change_column_null`

Other

- Added experimental support for lock timeout retries
- Added `target_sql_mode` option
- Added error for `change_column_null` with default value with `safe_by_default` option
- Fixed instructions for `remove_columns` with options
- Dropped support for Postgres < 10, MySQL < 5.7, and MariaDB < 10.2

## 0.8.0 (2022-02-09)

- Fixed error with versioned schema with Active Record 7.0.2+
- Dropped support for Ruby < 2.6 and Active Record < 5.2

## 0.7.9 (2021-12-15)

- Fixed error with multiple databases with Active Record 7

## 0.7.8 (2021-08-03)

- Fixed issue with `add_reference ..., foreign_key: {to_table: ...}` with `safe_by_default`

## 0.7.7 (2021-06-07)

- Removed timeouts and `auto_analyze` from schema load

## 0.7.6 (2021-01-17)

- Fixed `NOT NULL` constraint check for quoted columns
- Fixed deprecation warning with Active Record 6.1

## 0.7.5 (2021-01-12)

- Added checks for `add_check_constraint` and `validate_check_constraint`

## 0.7.4 (2020-12-16)

- Added `safe_by_default` option to install generator
- Fixed warnings with Active Record 6.1

## 0.7.3 (2020-11-24)

- Added `safe_by_default` option

## 0.7.2 (2020-10-25)

- Added support for float timeouts

## 0.7.1 (2020-07-27)

- Added `target_version` option to replace database-specific options

## 0.7.0 (2020-07-22)

- Added `check_down` option
- Added check for `change_column` with `null: false`
- Added check for `validate_foreign_key`
- Improved error messages
- Made auto analyze less verbose in Postgres
- Decreasing the length limit of a `varchar` column or adding a limit is not safe in Postgres
- Removed safety checks for `db` rake tasks (Rails 5+ handles this)

## 0.6.8 (2020-05-13)

- `change_column_null` on a column with a `NOT NULL` constraint is safe in Postgres 12+

## 0.6.7 (2020-05-13)

- Improved comments in initializer
- Fixed string timeouts for Postgres

## 0.6.6 (2020-05-08)

- Added warnings for missing and long lock timeouts
- Added install generator

## 0.6.5 (2020-05-06)

- Fixed deprecation warnings with Ruby 2.7

## 0.6.4 (2020-04-16)

- Added check for `add_reference` with `foreign_key: true`

## 0.6.3 (2020-04-04)

- Increasing precision of `decimal` or `numeric` column is safe in Postgres 9.2+
- Making `decimal` or `numeric` column unconstrained is safe in Postgres 9.2+
- Changing between `timestamp` and `timestamptz` when session time zone is UTC in Postgres 12+
- Increasing the length of a `varchar` column from under 255 up to 255 in MySQL and MariaDB
- Increasing the length of a `varchar` column over 255 in MySQL and MariaDB

## 0.6.2 (2020-02-03)

- Fixed PostgreSQL version check

## 0.6.1 (2020-01-28)

- Fixed timeouts for PostgreSQL

## 0.6.0 (2020-01-24)

- Added `statement_timeout` and `lock_timeout`
- Adding a column with a non-null default value is safe in MySQL 8.0.12+ and MariaDB 10.3.2+
- Added `change_column_null` check for MySQL and MariaDB
- Added `auto_analyze` for MySQL and MariaDB
- Added `target_mysql_version` and `target_mariadb_version`
- Switched to `up` for backfilling

## 0.5.1 (2019-12-17)

- Fixed migration name in error messages

## 0.5.0 (2019-12-05)

- Added ability to disable checks
- Added Postgres-specific check for `change_column_null`
- Added optional remove index check

## 0.4.2 (2019-10-27)

- Allow `add_reference` with concurrent indexes

## 0.4.1 (2019-07-12)

- Added `target_postgresql_version`
- Added `unscoped` to backfill instructions

## 0.4.0 (2019-05-27)

- Added check for `add_foreign_key`
- Fixed instructions for adding default value with NOT NULL constraint
- Removed support for Rails 4.2

## 0.3.1 (2018-10-18)

- Fixed error with `remove_column` and `type` argument
- Improved message customization

## 0.3.0 (2018-10-15)

- Added support for custom checks
- Adding a column with a non-null default value is safe in Postgres 11+
- Added checks for `add_belongs_to`, `remove_belongs_to`, `remove_columns`, and `remove_reference`
- Customized messages

## 0.2.3 (2018-07-22)

- Added check for `change_column_null`
- Added support for alphabetize columns with Makara
- Fixed migration reversibility with `auto_analyze`

## 0.2.2 (2018-02-14)

- Friendlier output
- Better method of hooking into Active Record

## 0.2.1 (2018-02-07)

- Recommend `disable_ddl_transaction!` over `commit_db_transaction`
- Suggest `jsonb` over `json` in Postgres 9.4+
- Changing `varchar` to `text` is safe in Postgres 9.1+
- Do not check number of columns for unique indexes

## 0.2.0 (2018-01-07)

- Added customizable error messages
- Updated instructions for adding a column with a default value

## 0.1.9 (2017-06-14)

- Added `start_after` option

## 0.1.8 (2017-05-31)

- Fixed error with `create_table`
- Added check for executing arbitrary SQL

## 0.1.7 (2017-05-29)

- Added check for `force` option with `create_table`
- Added `auto_analyze` option

## 0.1.6 (2017-03-23)

- Adding an index to a newly created table is now safe

## 0.1.5 (2016-07-23)

- Fixed error with Ruby 2.3 frozen strings

## 0.1.4 (2016-03-22)

- Added alphabetize columns

## 0.1.3 (2016-03-12)

- Disabled dangerous rake tasks in production
- Added ability to use `SAFETY_ASSURED` env var

## 0.1.2 (2016-02-24)

- Skip checks on down migrations and rollbacks
- Added check for indexes with more than 3 columns

## 0.1.1 (2015-11-29)

- Fixed `add_index` check for MySQL

## 0.1.0 (2015-11-22)

- First release
