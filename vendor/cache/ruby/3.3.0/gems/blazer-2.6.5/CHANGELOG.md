## 2.6.5 (2022-08-31)

- Use monotonic time
- Fixed `comparison of Symbol with String failed` error with certain versions of Rails

## 2.6.4 (2022-05-24)

- Fixed error with caching

## 2.6.3 (2022-05-11)

- Fixed error with canceling queries

## 2.6.2 (2022-05-06)

- Fixed error with Postgres when prepared statements are disabled with Rails < 6.1

## 2.6.1 (2022-04-21)

- Added `region` setting to Amazon Athena
- Fixed error with MySQL for Rails < 7
- Fixed error with binary data

## 2.6.0 (2022-04-20)

- Fixed quoting issue with variables
- Custom adapters now need to specify how to quote variables in queries
- Added experimental support for Propshaft
- Fixed error with empty results with InfluxDB

## 2.5.0 (2022-01-04)

- Added support for Slack OAuth tokens
- Added experimental support for AnomalyDetection.rb
- Improved table preview for MySQL
- Fixed cohort analysis for MySQL

## 2.4.8 (2021-12-07)

- Added support for OpenSearch
- Removed `elasticsearch-xpack` dependency for Elasticsearch

## 2.4.7 (2021-09-25)

- Made Action Mailer optional
- Fixed error with multiple maps on dashboard

## 2.4.6 (2021-09-20)

- Added support for workgroup with Amazon Athena
- Added casting for timestamp with time zone columns with Amazon Athena
- Added support for setting credentials in config file with Amazon Athena
- Made output location optional with Amazon Athena
- Fixed casting error for `NULL` values with Amazon Athena
- Fixed issue with Google BigQuery only showing first page of results

## 2.4.5 (2021-09-15)

- Improved fix for some forked queries not appearing on home page

## 2.4.4 (2021-09-15)

- Fixed issue with some forked queries not appearing on home page

## 2.4.3 (2021-07-27)

- Added Prophet anomaly detection
- Fixed style for new select items

## 2.4.2 (2021-02-08)

- Added support for Apache Ignite

## 2.4.1 (2021-01-25)

- Added cohorts for MySQL
- Added support for Apache Hive and Apache Spark
- Fixed deprecation warning with Active Record 6.1

## 2.4.0 (2020-12-15)

- Added cohorts
- Fixed broken routes for some applications
- Forecasting and uploads are no longer experimental

## 2.3.1 (2020-11-23)

- Improved column names for uploads

## 2.3.0 (2020-11-16)

- Added support for archiving queries
- Added experimental support for uploads

## 2.2.8 (2020-11-01)

- Fixed error when deleting dashboard

## 2.2.7 (2020-09-07)

- Use `datetime` type in migration
- Fixed unpermitted parameters on dashboard page
- Fixed deprecation warnings in Ruby 2.7

## 2.2.6 (2020-07-21)

- Added experimental support for InfluxDB
- Added support for forecasting week, month, quarter, and year with Prophet
- Fixed forecasting link not showing up

## 2.2.5 (2020-06-03)

- Updated maps to fix deprecation error

## 2.2.4 (2020-05-30)

- Fixed error with new queries

## 2.2.3 (2020-05-30)

- Improved query parameter handling

## 2.2.2 (2020-04-13)

- Added experimental support for the Socrata Open Data API (SODA)
- Added experimental Prophet forecasting
- Fixed query search for non-ASCII characters

## 2.2.1 (2019-10-08)

- Added support for Sprockets 4
- Improved Snowflake table preview
- Fixed bug with refresh link not showing

## 2.2.0 (2019-07-12)

- Added schema to table preview for Postgres and Redshift
- Fixed bug with Slack notifications not sending
- Dropped support for Rails 4.2

## 2.1.0 (2019-06-04)

- Require latest Chartkick to prevent possible XSS - see [#245](https://github.com/ankane/blazer/issues/245)

## 2.0.2 (2019-05-26)

- Added support for variable transformation for blind indexing
- Added experimental support for Neo4j
- Added experimental support for Salesforce
- Fixed JavaScript sorting for numbers with commas

## 2.0.1 (2019-01-07)

- Added favicon
- Added search for checks and schema
- Added pie charts
- Added Trend anomaly detection
- Added forecasting
- Improved tooltips
- Improved docs for new installs
- Fixed error with canceling queries

## 2.0.0 (2019-01-03)

- Added support for Slack
- Added `async` option
- Added `override_csp` option
- Added smart variables, linked columns smart columns, and charts to inline docs
- Use SQL for Elasticsearch
- Fixed error with latest `google-cloud-bigquery`

Breaking changes

- Dropped support for Rails < 4.2

## 1.9.0 (2018-06-17)

- Prompt developers to check custom `before_action`
- Better ordering on home page
- Added support for Snowflake

## 1.8.2 (2018-02-22)

- Added support for Cassandra
- Fixes for Druid
- Added support for Amazon Athena
- Added support for Druid
- Fixed query cancellation

There was no 1.8.1 release.

## 1.8.0 (2017-05-01)

- Added support for Rails 5.1

## 1.7.10 (2017-04-03)

- Added support for Google BigQuery
- Require `drill-sergeant` gem for Apache Drill
- Better handling of checks with variables

## 1.7.9 (2017-03-20)

- Added beta support for Apache Drill
- Added email validation for checks
- Updated Chart.js to 2.5.0

## 1.7.8 (2017-02-06)

- Added support for custom adapters
- Fixed bug with scatter charts on dashboards
- Fixed table preview for SQL Server
- Fixed issue when `default_url_options` set

## 1.7.7 (2016-12-17)

- Fixed preview error for MySQL
- Fixed error with timeouts for MySQL

## 1.7.6 (2016-12-13)

- Added scatter chart
- Fixed issue with false values showing up blank
- Fixed preview for table names with certain characters

## 1.7.5 (2016-11-22)

- Fixed issue with check emails sometimes failing for default Rails 5 ActiveJob adapter
- Fixed sorting for new dashboards

## 1.7.4 (2016-11-06)

- Removed extra dependencies added in 1.7.1
- Fixed `send_failing_checks` for default Rails 5 ActiveJob adapter

## 1.7.3 (2016-11-01)

- Fixed JavaScript errors
- Fixed query cancel error
- Return search results for "me" or "mine"
- Include sample data in email when bad data checks fail
- Fixed deprecation warnings

## 1.7.2 (2016-10-30)

- Cancel all queries on page nav
- Prevent Ace from taking over find command
- Added ability to use hashes for smart columns
- Added ability to inherit smart variables and columns from other data sources

## 1.7.1 (2016-10-29)

- Do not fork when enter key pressed
- Use custom version of Chart.js to fix label overlap
- Improved performance of home page

## 1.7.0 (2016-09-07)

- Added ability to cancel queries on backend for Postgres and Redshift
- Only run 3 queries at a time on dashboards
- Better anomaly detection
- Attempt to reconnect when connection issues
- Fixed issues with caching

## 1.6.2 (2016-08-11)

- Added basic query permissions
- Added ability to use arrays and hashes for smart variables
- Added cancel button for queries
- Added `lat` and `lng` as map keys

## 1.6.1 (2016-07-30)

- Added support for Presto [beta]
- Added support for Elasticsearch timeouts
- Fixed error in Rails 5

## 1.6.0 (2016-07-28)

- Added support for MongoDB [beta]
- Added support for Elasticsearch [beta]
- Fixed deprecation warning in Rails 5

## 1.5.1 (2016-07-24)

- Added anomaly detection for data less than 2 weeks
- Added autolinking urls
- Added support for images

## 1.5.0 (2016-06-29)

- Added new bar chart format
- Added anomaly detection checks
- Added `async` option for polling

## 1.4.0 (2016-06-09)

- Added `slow` cache mode
- Fixed `BLAZER_DATABASE_URL required` error
- Fixed issue with duplicate column names

## 1.3.5 (2016-05-11)

- Fixed error with checks

## 1.3.4 (2016-05-11)

- Fixed issue with missing queries

## 1.3.3 (2016-05-08)

- Fixed error with Rails 4.1 and below

## 1.3.2 (2016-05-07)

- Added support for Rails 5
- Attempt to reconnect for checks

## 1.3.1 (2016-05-06)

- Fixed migration error

## 1.3.0 (2016-05-06)

- Added schedule for checks
- Switched to Chart.js for charts
- Better output for explain
- Support for MySQL timeouts
- Raise error when timeout not supported
- Added creator to dashboards and checks

## 1.2.1 (2016-04-26)

- Fixed checks

## 1.2.0 (2016-03-22)

- Added non-editable queries
- Added variable defaults
- Added `local_time_suffix` setting
- Better timeout message
- Hide variables from commented out lines
- Fixed regex as variable names

## 1.1.1 (2016-03-06)

- Added `before_action` option
- Added invert option for checks
- Added targets
- Friendlier error message for timeouts
- Fixed request URI too large
- Prevent accidental backspace nav on query page

## 1.1.0 (2015-12-27)

- Replaced pie charts with column charts
- Fixed error with datepicker
- Added fork button to edit query page
- Added a notice when editing a query that is part of a dashboard
- Added refresh for dashboards

## 1.0.4 (2015-11-04)

- Added recently viewed queries and dashboards to home page
- Fixed refresh when transform statement is used
- Fixed error when no user model

## 1.0.3 (2015-10-18)

- Added maps
- Added support for Rails 4.0

## 1.0.2 (2015-10-11)

- Fixed error when installing
- Added `schemas` option

## 1.0.1 (2015-10-08)

- Added comments to queries
- Added `cache` option
- Added `user_method` option
- Added `use_transaction` option

## 1.0.0 (2015-10-04)

- Added support for multiple data sources
- Added dashboards
- Added checks
- Added support for Redshift

## 0.0.8 (2015-09-05)

- Easier to edit queries with variables
- Dynamically expand editor height as needed
- No need for spaces in search

## 0.0.7 (2015-07-23)

- Fixed error when no `User` class
- Fixed forking a query with variables
- Set time zone after Rails initializes

## 0.0.6 (2015-06-18)

- Added fork button
- Fixed trending
- Fixed time zones for date select

## 0.0.5 (2015-01-31)

- Added support for Rails 4.2
- Fixed error with `mysql2` adapter
- Added `user_class` option
