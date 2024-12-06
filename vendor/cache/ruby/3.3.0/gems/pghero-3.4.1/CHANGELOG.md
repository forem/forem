## 3.4.1 (2024-02-07)

- Added current stats to query details page
- Improved tune page for latest PgTune

## 3.4.0 (2023-11-28)

- Added support for explaining normalized queries with Postgres 16
- Added Docker image for `linux/arm64`

## 3.3.4 (2023-09-05)

- Fixed support for aliases in config file

## 3.3.3 (2023-04-18)

- Fixed error with system stats for Azure Database

## 3.3.2 (2023-04-12)

- Fixed error with suggested indexes and empty statements

## 3.3.1 (2023-03-15)

- Fixed error with Uglifier

## 3.3.0 (2023-03-11)

- Improved handling of lock timeouts
- Improved syntax highlighting

## 3.2.0 (2023-02-21)

- Added support for pg_query 4
- Added `pghero:clean_space_stats` rake task
- Added support for specifying retention period with `clean_query_stats` and `clean_space_stats`
- Removed reset button when historical query stats are enabled

## 3.1.0 (2023-01-04)

- Fixed explain error message leaking data - [more info](https://github.com/ankane/pghero/issues/439)
- Explain analyze is now opt-in - [more info](https://github.com/ankane/pghero/issues/438)
- Added support for disabling explain and explain analyze
- Added support for visualize without explain analyze
- Added `explain_v2` method

## 3.0.1 (2022-10-09)

- Fixed message when database user does not have permission to reset query stats

## 3.0.0 (2022-09-13)

- Changed `capture_query_stats` to only reset stats for current database in Postgres 12+
- Changed `reset_query_stats` to only reset stats for current database (use `reset_instance_query_stats` to reset stats for entire instance)
- Added `visualize_url` option to config
- Removed `access_key_id`, `secret_access_key`, `region`, and `db_instance_identifier` methods (use `aws_` prefixed methods instead)
- Dropped support for Linux packages for EOL versions
- Dropped support for Ruby < 2.7 and Rails < 6
- Dropped support for pg_query < 2
- Dropped support for aws-sdk < 2

## 2.8.3 (2022-05-01)

- Added support for `google-apis-monitoring_v3`
- Added experimental support for Propshaft
- Fixed error with walsender queries on live queries page

## 2.8.2 (2021-12-15)

- Fixed sorting by name on space page when historical space stats are not enabled
- Fixed deprecation warnings with Active Record 7

## 2.8.1 (2021-03-25)

- Added support for pg_query 2

## 2.8.0 (2021-03-14)

- No longer show walsender in long running queries
- Show relative time on maintenance page
- Added support for `PGHERO_TZ` for Docker and Linux

## 2.7.4 (2021-02-01)

- Fixed error on redirect with Ruby 3
- Fixed error with unparsable sequences

## 2.7.3 (2020-11-23)

- Improved index suggestions when hash, GiST, GIN, or BRIN index present

## 2.7.2 (2020-09-10)

- Fixed error with historical query stats

## 2.7.1 (2020-09-07)

- Added `/health` endpoint to Docker image and Linux packages
- Fixed error with `cast_value`

## 2.7.0 (2020-08-04)

- Fixed CSRF vulnerability with non-session based authentication - [more info](https://github.com/ankane/pghero/issues/330)
- Added `database`, `user`, and `query_hash` options to `reset_query_stats` method

## 2.6.0 (2020-07-09)

- Added support for Postgres 13 beta 2
- Added support for non-integer explain timeout

## 2.5.1 (2020-06-23)

- Added support for `google-cloud-monitoring` >= 1
- Added support for `google-cloud-monitoring-v3`
- Fixed system stats not showing up in Rails 6 with environment variables

## 2.5.0 (2020-05-24)

- Added system stats for Google Cloud SQL and Azure Database
- Added experimental `filter_data` option
- Localized times on maintenance page
- Improved connection pooling
- Improved error message for non-Postgres connections
- Fixed more deprecation warnings in Ruby 2.7

## 2.4.2 (2020-04-16)

- Added `connections` method
- Fixed deprecation warnings in Ruby 2.7

## 2.4.1 (2019-11-21)

- Fixed file permissions on `highlight.pack.js`

## 2.4.0 (2019-11-11)

- Added `invalid_constraints` method
- Added `spec` option
- Added `override_csp` option
- Show all databases in Rails 6 when no config

## 2.3.0 (2019-08-18)

- Added support for Postgres 12 beta 1
- Added methods and tasks for cleaning up stats
- Dropped support for Rails < 5

## 2.2.1 (2019-06-04)

- Added `config_path` option
- Fixed error with sequences when temporary tables
- Fixed error when `config.action_controller.include_all_helpers = false`

## 2.2.0 (2018-09-03)

- Added check for connections idle in transaction
- Improved duplicate index logic to detect more duplicates
- Don't report concurrent indexes in-progress as invalid on dashboard
- Fixed error with large number of sequences
- Bumped `total_connections_threshold` to 500 by default

## 2.1.1 (2018-04-24)

- Added `explain_timeout_sec` option
- Fixed error with unparsable sequences
- Stopped throwing `Same sequence name in multiple schemas` error

## 2.1.0 (2017-11-30)

- Fixed issue with sequences in different schema than table
- No longer throw errors for unreadable sequences
- Fixed replication lag for Amazon Aurora
- Added `vacuum_progress` method

## 2.0.8 (2017-11-12)

- Added support for Postgres 10 replicas
- Added support for pg_query 1.0.0
- Show queries with insufficient privilege on live queries page
- Default to table schema for sequences

## 2.0.7 (2017-10-28)

- Fixed issue with sequences in different schema than table
- Fixed query details when multiple users have same query hash
- Fixed error with invalid indexes in non-public schema
- Raise error when capture query stats fails

## 2.0.6 (2017-09-24)

- More robust methods for multiple databases
- Added support for `RAILS_RELATIVE_URL_ROOT` for Linux and Docker

## 2.0.5 (2017-09-14)

- Fixed error with sequences in different schemas
- Better advice

## 2.0.4 (2017-08-28)

- Fixed `AssetNotPrecompiled` error
- Do not silently ignore sequence danger when user does not have permissions

## 2.0.3 (2017-08-22)

- Added SQL to recreate invalid indexes
- Added unused index marker to Space page
- Fixed `capture_query_stats` on Postgres < 9.4

## 2.0.2 (2017-08-09)

- Fixed error with suggested indexes
- Fixed error with `pg_replication_slots`

## 2.0.1 (2017-08-08)

- Fixed capture space stats

## 2.0.0 (2017-08-08)

New features

- Query details page
- Added check for inactive replication slots
- Added `table_sizes` method for full table sizes
- Added syntax highlighting
- Added `min_size` option to `analyze_tables`

Breaking changes

- Methods now return symbols for keys instead of strings
- Methods raise `PgHero::NotEnabled` error when a feature isn’t enabled
- Requires pg_query 0.9.0+ for suggested indexes
- Historical query stats require the `pghero_query_stats` table to have `query_hash` and `user` columns
- Removed `with` option - use:

```ruby
PgHero.databases[:database2].running_queries
```

instead of

```ruby
PgHero.with(:database2) { PgHero.running_queries }
```

- Removed options from `connection_sources` method
- Removed `locks` method

## 1.7.0 (2017-05-01)

- Fixed migrations for Rails 5.1+
- Added `analyze`, `analyze_tables`, and `analyze_all` methods
- Added `pghero:analyze` rake task
- Fixed system stats display issue

## 1.6.5 (2017-04-19)

- Added support for Rails API
- Added support for Amazon STS
- Fixed replica check when `hot_standby = on` for primary

## 1.6.4 (2017-03-12)

- Only show connection charts if there are connections
- Fixed duplicate indexes for multiple schemas
- Fixed display issue for queries without word break
- Removed maintenance tab for replicas

## 1.6.3 (2017-02-09)

- Added 10 second timeout for explain
- No longer show autovacuum in long running queries
- Added charts for connections
- Added new config format
- Removed Chartkick gem dependency for charts
- Fixed error when primary database is not PostgreSQL

## 1.6.2 (2016-10-26)

- Suggest GiST over GIN for `LIKE` queries again (seeing better performance)

## 1.6.1 (2016-10-24)

- Suggest GIN over GiST for `LIKE` queries

## 1.6.0 (2016-10-20)

- Removed mostly inactionable items (cache hit rate and index usage)
- Restored duplicate indexes to homepage
- Fixed issue with exact duplicate indexes
- Way better `blocked_queries` method

## 1.5.3 (2016-10-06)

- Fixed Rails 5 error with multiple databases
- Fixed duplicate index detection with expressions

## 1.5.2 (2016-10-01)

- Added support for PostgreSQL 9.6
- Fixed incorrect query start for live queries in transactions

## 1.5.1 (2016-09-27)

- Better tune page for PostgreSQL 9.5

## 1.5.0 (2016-09-21)

- Added user to query stats (opt-in)
- Added user to connection sources
- Added `capture_space_stats` method and rake task
- Added visualize button to explain page
- Better charts for system stats

## 1.4.2 (2016-09-06)

- Fixed `wrong constant name` error in development
- Added different periods for system stats

## 1.4.1 (2016-08-25)

- Removed external assets

## 1.4.0 (2016-08-24)

- Updated for Rails 5
- Fixed error when `pg_stat_statements` not enabled in `shared_libaries`

## 1.3.2 (2016-08-03)

- Improved performance of query stats

## 1.3.1 (2016-07-10)

- Improved grouping of query stats
- Added `blocked_queries` method

## 1.3.0 (2016-06-27)

- Added query hash for better query stats grouping
- Added sequence danger check
- Added `capture_query_stats` option to config

## 1.2.4 (2016-05-06)

- Fixed user methods

## 1.2.3 (2016-04-20)

- Added schema to queries
- Fixed deprecation warning on Rails 5
- Fix for pg_query >= 0.9.0

## 1.2.2 (2016-01-20)

- Better suggested indexes
- Removed duplicate indexes noise
- Fixed partial and expression indexes

## 1.2.1 (2016-01-07)

- Better suggested indexes
- Removed unused indexes noise
- Removed autovacuum danger noise
- Removed maintenance tab
- Fixed suggested indexes for replicas
- Fixed issue w/ suggested indexes where same table name exists in multiple schemas

## 1.2.0 (2015-12-31)

- Added suggested indexes
- Added duplicate indexes
- Added maintenance tab
- Added load stats for RDS
- Added `table_caching` and `index_caching` methods
- Added configurable cache hit rate threshold
- Show all connections in connections tab

## 1.1.4 (2015-12-08)

- Added check for transaction ID wraparound failure
- Added check for autovacuum danger

## 1.1.3 (2015-10-21)

- Fixed system stats

## 1.1.2 (2015-10-18)

- Added invalid indexes
- Fixed RDS stats for aws-sdk 2

## 1.1.1 (2015-07-23)

- Added `tables` option to `create_user` method
- Added ability to sort query stats by average_time and calls
- Only show unused indexes with no index scans in UI

## 1.1.0 (2015-06-26)

- Added historical query stats

## 1.0.1 (2015-04-17)

- Fixed connection bad errors
- Restore previous connection properly for nested with blocks
- Added analyze button to explain page
- Added explain button to live queries page

## 1.0.0 (2015-04-11)

- More platforms!
- Support for multiple databases!
- Added `replica?` method
- Added `replication_lag` method
- Added `ssl_used?` method
- Added `kill_long_running_queries` method
- Added env vars for settings

## 0.1.10 (2015-03-20)

- Added connections page
- Added message for insufficient privilege
- Added `ip` to `connection_sources`

## 0.1.9 (2015-01-25)

- Added tune page
- Removed minimum size for unused indexes

## 0.1.8 (2015-01-19)

- Added `total_percent` to `query_stats`
- Added `total_connections`
- Added `connection_stats` for Amazon RDS

## 0.1.7 (2014-11-12)

- Added support for pg_stat_statments on Amazon RDS
- Added `long_running_query_sec`, `slow_query_ms` and `slow_query_calls` options

## 0.1.6 (2014-10-09)

- Added methods to create and drop users
- Added locks

## 0.1.5 (2014-09-03)

- Added system stats for Amazon RDS
- Added code to remove unused indexes
- Require unused indexes to be at least 1 MB
- Use `pg_terminate_backend` to ensure queries are killed

## 0.1.4 (2014-08-31)

- Reduced long running queries threshold to 1 minute
- Fixed duration
- Fixed wrapping
- Friendlier dependencies for JRuby

## 0.1.3 (2014-08-04)

- Reverted `query_stats_available?` fix

## 0.1.2 (2014-08-03)

- Fixed `query_stats_available?` method

## 0.1.1 (2014-08-03)

- Added explain
- Added query stats
- Fixed CSS issues

## 0.1.0 (2014-07-23)

- First major release
