## 3.5.3 (February 16, 2024)

Bugfixes:
  - Correct polymorphic table name alias reference in join clauses (#388)

## 3.5.2 (January 16, 2024)

Bugfixes:
  - Assign attributes to the duped model on a lower level when determining whether a model has changed to avoid invoking unrelated callbacks (#386)

## 3.5.1 (January 8, 2024)

Bugfixes:
  - Fix touching for counted models without `updated_at` (#383)

## 3.5.0 (August 25, 2023)

Improvements:
  - Allow passing context to `counter_culture_fix_counts` (#375)

## 3.4.0 (July 12, 2023)

Improvements:
  - Ability to skip counter culture updates in a block (#371)

## 3.3.1 (June 26, 2023)

Bugfixes:
  - Read primary key on polymorphic associations if it's explicitly set (#370)

## 3.3.0 (October 11, 2022)

Improvements:
  - Allow reading from replica in `counter_culture_fix_counts` (#330)
  - Test against Ruby 3.1 (#357)

Bugfixes:
  - Don't decrement counter cache when calling `.destroy` on an already-destroyed model (#351)
  - Don't immediately call `Proc` passed to `column_names` to avoid startup issue (#352)

## 3.2.1 (February 24, 2022)

Bugfixes:
  - Fix `counter_culture_fix_counts` when passing it symbols for column names (#341)

## 3.2.0 (January 24, 2022)

Improvements:
  - Allow specifiying `polymorphic_classes` to avoid a potentially expensive
    `DISTINCT` query when calling `counter_culture_fix_counts` (#336)

Bugfixes:
  - Fix primary key name for enumerable relations (#337)

## 3.1.0 (November 29, 2021)

Improvements:
  - Allow specifiying a `Proc` to `column_names` to avoid loading a scope on
    startup (#335)

## 3.0.0 (October 26, 2021)

Breaking changes:
  - Dropped support for Ruby < 2.6
  - Dropped support for Rails < 5.2

Note that there are no specific breaking changes that would cause older
versions of Ruby or Rails to stop working, we have simply stopped testing
against them.

Improvements:
  - Support PostgreSql's `money` type for use with a delta column (#333)

## 2.9.0 (August 27, 2021)

Improvements:
  - Allow `execute_after_commit` to be a `Proc` for dynamic control (#326)

## 2.8.0 (March 16, 2021)

Improvements:
  - New `execute_after_commit` option (#309)

## 2.7.0 (November 16, 2020)

Improvements:
  - New `column_name` option for `counter_culture_fix_counts` (#300)

## 2.6.2 (October 21, 2020)

Improvements:
  - Remove superfluous dependency to after_commit_action gem (#297)

## 2.6.1 (September 8, 2020)

Bugfixes:
  - Address Ruby 2.7.0 deprecation warning (#292)

## 2.6.0 (July 29, 2020)

Improvements:
  - Use []= method instead of attribute writer method internally to avoid conflicts with read-only attributes (#287)
  - More detailed logging when performing reconciliation (#288)

## 2.5.1 (May 18, 2020)

Bugfixes:
  - Fix migration generation in Rails 6+ (#281)

## 2.5.0 (May 12, 2020)

Bugfixes:
  - Fix `counter_culture_fix_counts` with Rails 4.2

Changes:
  - Dropped support for Ruby 2.3 and 2.4

## 2.4.0 (May 9, 2020)

Improvements:
  - Allow specifying `start` and `finish` options to `counter_culture_fix_counts` (#279)

## 2.3.0 (January 28, 2020)

Improvements:
  - Allow using scopes in `column_names` (#272)

## 2.2.4 (August 21, 2019)

Bugfixes:
  - Test and fix behavior in Rails 6.0.0 release (#268)

## 2.2.3 (June 20, 2019)

Improvements:
  - Start testing against MySQL and PostgreSQL as well as sqlite3 (#257)

Bugfixes:
  - Fix edge cases in MySQL (#257)

## 2.2.2 (May 5, 2019)

Bugfixes:
  - Don't fail reconciliation in PostgreSQL if the Rails-level primary key is not a DB primary key (#254)

## 2.2.1 (April 17, 2019)

Improvements:
  - Improve logging when `verbose` is set (#256)

## 2.2.0 (April 9, 2019)

Improvements:
  - Add `where` option to `counter_culture_fix_counts` (#250)
  - Add `verbose` option to `counter_culture_fix_counts` (#251)

Changes:
  - Dropped support for Ruby 2.2
  - Dropped support for Rails 3.2, 4.0 and 4.1

## 2.1.4 (January 21, 2019)

Improvements:
  - Avoid instantiating model class during `counter_culture` call (#246)

## 2.1.3 (January 19, 2019)

Bugfixes:
  - Don't update running total on soft-deleted records (#244)

## 2.1.2 (December 7, 2018)

Bugfixes:
  - Properly handle `destroy` and `really_destroy` when using Paranoia (#239)

## 2.1.1 (November 7, 2018)

Bugfixes:
  - Don't double-decrement when discarding and then hard-destroying a record (#237)

## 2.1.0 (October 19, 2018)

Bugfixes:
  - Fix behavior with Models that are part of a module (ex: `Users::Admin`) (#234)

## 2.0.1 (August 19, 2018)

Bugfixes:
  - Properly set timestamps of PaperTrail versions (#224, #225, #226)

## 2.0.0 (June 12, 2018)

Breaking changes:
  - execute_after_commit was removed
  - Removed workaround for incorrect counts when triggering updates from an `after_create` hook. Your options if this applies to you:
    * continue using counter_culture 1.12.0
    * upgrade to Rails 5.1.5 which fixes the underlying issue in Rails
    * avoid triggering further updates on the same model in `after_create`; simply set the attribute in `before_create` instead

Bugfixes:
  - Multiple updates in one transaction will now be processed correctly (#222)

## 1.12.0 (June 8, 2018)

Improvements:
  - Adds support for the [Discard](https://github.com/jhawthorn/discard) soft-delete gem (#220)

## 1.11.0 (May 4, 2018)

Bugfixes:
  - Fix `with_papertrail` behavior while still addressing the deprecation warning, and actually recording the correct counts (#218, see [airblade/paper_trail#1076](https://github.com/airblade/paper_trail/issues/1076))

## 1.10.1 (April 20, 2018)

Improvements:
  - Added the ability to update timestamps while fixing count by passing `touch: true` to `counter_culture_fix_counts` (#212)

## 1.9.2 (April 13, 2018)

Bugfixes:
  - When using paranoia, call increment / decrement only once when calling destroy or restore on the same model multiple times

Improvements:
  - Address deprecation warning when enabling paper_trail touch in paper_trail version 9.0
  - Address `Arel` deprecation warnings in Rails 5.2

Changes:
  - Test against Ruby 2.2 through 2.5, Rails 3.2 through 5.2
  - Don't test Rails 3.2 through 4.1 against Ruby 2.4 or 2.5 as those versions of Rails will not work with those versions of Ruby
  - Avoid various deprecation warnings being triggered in the test

## 1.9.1 (March 1, 2018)

Bugfixes:
  - Address an edge-case test regression caused by Rails 5.1.5 that was causing counts to be off when saving changes from an `after_create` callback

## 1.9.0 (November 29, 2017)

Improvements:
  - Switch generated migration files to use new hash syntax
  - Support for Rails 5 migration file format for generated migrations

## 1.8.2 (September 27, 2017)

Bugfixes:
  - Actually use `batch_size` parameter in `counter_culture_fix_counts` (#200)

## 1.8.1 (September 5, 2017)

Improvements:
  - Use ActiveRecord version, not Rails version, in `Reconciler`, makeing it possible to use `counter_culture_fix_counts` without Rails

## 1.8.0 (August 30, 2017)

Improvements:
  - Quote all table names to work correctly with PostgreSQL schemata
  - Use ActiveRecord version, not Rails version, to make things work for projects that use ActiveRecord but not Rails

## 1.7.0 (June 12, 2017)

Improvements:
  - Support for creating `paper_trail` versions when counters change

## 1.6.2 (April 26, 2017)

Bugfixes:
  - Restore compatibility with older Rails versions

## 1.6.1 (April 26, 2017)

Bugfixes:
  - Fix `counter_culture_fix_counts` for a multi-level relation where an intermediate link is `has_one`, rather than `belongs_to`

## 1.6.0 (April 24, 2017)

Improvements:
  - Keeps counts updated correctly when using the paranoia gem and restoring soft-deleted records

## 1.5.1 (April 17, 2017)

Bugfixes:
  - Support for `nil` values in polymorphic relationships

## 1.5.0 (March 21, 2017)

New features:
  - Support for counter caches on one-level polymorphic relationships

## 1.4.0 (March 21, 2017)

Improvements:
  - Avoid Rails 5.1 deprecation warnings

## 1.3.1 (February 23, 2017)

Bugfixes:
  - Removed requirement for Rails 5 added by mistake (in fact, this gem supports and tests Rails versions as far back as Rails 3.2 now)

## 1.3.0 (February 21, 2017)
Removed features:
  - Removed support for `has_one`; this did not work properly. If you need this, consider adding the `counter_culture` call on the model with the `belongs_to` instead.

## 1.2.0 (February 21, 2017)

New features:
  - Add support for custom timestamp column with `touch` option

## 1.1.1 (January 13, 2017)

Bugfixes:
  - Don't blow up if the `column_names` hash contains a `nil` column name

## 1.1.0 (December 23, 2016)

Improvements:
  - Support for `has_one` associations

## 1.0.0 (November 15, 2016)

Breaking changes:
  - By default, counter_culture will now update counts inside the same transaction that triggered it. In older versions, counter cache updates happened outside of that transaction. To preserve the old behavior, use the new [`execute_after_commit` option](README.md#executing-counter-cache-updates-after-commit).

## 0.2.3 (October 18, 2016)

Improvements:
  - When running `fix_counts` on a table, wrap each batch in a transaction because that is faster on large tables.

## 0.2.2 (July 11, 2016)

Bugfixes:
  - Use `ActiveSupport.on_load` for better Rails 5 compatibility (see [rails/rails#23589](https://github.com/rails/rails/issues/23589))

## 0.2.1 (June 15, 2016)

Improvements:
  - Add [`:delta_magnitude` option](https://github.com/magnusvk/counter_culture#dynamic-delta-magnitude)

## 0.2.0 (April 22, 2016)

Improvments:
  - Major refactor of the code that reduces ActiveRecord method pollution. Documented API is unchanged, but behind the scenes a lot has changed.
  - Ability to configure batch size of `counter_culture_fix_size`

## 0.1.34 (October 27, 2015)

Bugfixes:
  - Fixes an issue when using a default scope that adds a join in conjunction with counter_culture

## 0.1.33 (April 2, 2015)

Bugfixes:
  - Fixes an issue with STI classes and inheritance

## 0.1.32 (March 16, 2015)

Improvements:
  - Restores compatibility with Rails 3.2 (fixes #100)

## 0.1.31 (March 7, 2015)

Bugfixes:
  - Avoid issue with has_and_belongs_to_many and transactions by using new after_commit_action version (fixes #88)

## 0.1.30 (February 10, 2015)

Bugfixes:
  - Correctly use custom relation primary keys (fixes #93)

## 0.1.29 (December 25, 2014)

Bugfixes:
  - Fix fixing counts with multi-level STI models

## 0.1.28 (December 7, 2014)

Bugfixes:
  - fixes development and test dependencies

## 0.1.27 (November 13, 2014)

Bugfixes:
  - re-add after_commit_action as a dependency, that had gone missing in 0.1.26

## 0.1.26 (November 12, 2014)

Bugfixes:
  - makes fix_counts work correctly with self-referential tables

## 0.1.25 (July 30, 2014)

Bugfixes:
  - makes fix_counts work correctly with custom primary keys

## 0.1.24 (June 27, 2014)

Bugfixes:
  - correctly uses custom primary keys when incrementing / decrementing counts

## 0.1.23 (May 24, 2014)

Bugfixes:
  - fixes problems fixing conditional counter caches with batching

## 0.1.22 (May 24, 2014)

Improvements:
  - support for single-table inheritance in counter_culture_fix_counts

## 0.1.21 (May 24, 2014)

Bugfixes:
  - makes the migration generator compatible with Rails 4.1

## 0.1.20 (May 14, 2014)

Bugfixes:
  - counter_culture_fix counts now supports float values, where it forced integer values previously

## 0.1.19 (January 29, 2014)

Bugfixes:
  - Use correct date / time formatting for touch option (fixes a problem with MySQL databases)

## 0.1.18 (October 16, 2013)

Bugfixes:
  - Correctly fix counter caches, even when there are no dependent records

## 0.1.17 (October 7, 2013)

Bugfixes:
  - Avoid Rails 4 deprecation warning

## 0.1.16 (October 5, 2013)

Features:
  - Added support for touch option that updates timestamps when updating counter caches

## 0.1.15 (October 5, 2013)

Features:
  - Added a simple migration generator to simplify adding counter cache columns

Improvements:
  - delta_column now supports float values

Bugfixes:
  - Prevent running out of memory when running counter_culture_fix_counts in large tables
