# CHANGELOG

## [Unreleased](https://github.com/algolia/algoliasearch-rails/compare/2.2.1...master)

## [2.3.2](https://github.com/algolia/algoliasearch-rails/compare/2.3.1...2.3.2)
### Added
* Support for Pagy pagination provider [`#443`](https://github.com/algolia/algoliasearch-rails/pull/443)

## [2.3.1](https://github.com/algolia/algoliasearch-rails/compare/2.3.0...2.3.1)
### Added
* Allow ActiveJob queue configuration [`#439`](https://github.com/algolia/algoliasearch-rails/pull/439)
* allow to configure user agent and other default options [`#438`](https://github.com/algolia/algoliasearch-rails/pull/438)

## [2.3.0](https://github.com/algolia/algoliasearch-rails/compare/2.2.2...2.3.0)
### Fixed
* bugfix: don't consider objectID changed when using custom ID through method [`#436`](https://github.com/algolia/algoliasearch-rails/pull/436)

## [2.2.2](https://github.com/algolia/algoliasearch-rails/compare/2.2.1...2.2.2)
### Fixed
* fix: wrong method name [`#429`](https://github.com/algolia/algoliasearch-rails/pull/429)
* fix: check if `Sequel::Model` is defined [`#433`](https://github.com/algolia/algoliasearch-rails/pull/433)

## [2.2.1](https://github.com/algolia/algoliasearch-rails/compare/2.2.0...2.2.1)
### Fixed
* fix:settings changes detection issue with empty array [`#424`](https://github.com/algolia/algoliasearch-rails/pull/424)
* fix: settings changes detection issue for replica indexes with inherit option [`#426`](https://github.com/algolia/algoliasearch-rails/pull/426)
* fix: make sync opt to be selectable for auto setting update logic [`#425`](https://github.com/algolia/algoliasearch-rails/pull/425)

### Added
* Add relevancyStrictness to IndexSettings [`#427`](https://github.com/algolia/algoliasearch-rails/pull/427)

## [2.2.0](https://github.com/algolia/algoliasearch-rails/compare/2.1.4...2.2.0)
### Added
* Support to pass Algolia API client options [`#420`](https://github.com/algolia/algoliasearch-rails/pull/420)

### Fixed
* Issue with `FrozenError` for newer Ruby versions [`#418`](https://github.com/algolia/algoliasearch-rails/pull/418)
* Only check index settings when indexing is enabled [`#416`](https://github.com/algolia/algoliasearch-rails/pull/416)
* Index intialization documentation [`#419`](https://github.com/algolia/algoliasearch-rails/pull/419)

## [2.1.4](https://github.com/algolia/algoliasearch-rails/compare/2.1.4...2.1.3)
### Fixed
- File formatting [`#414`](https://github.com/algolia/algoliasearch-rails/pull/414)
- Document supported Rails versions [`#407`](https://github.com/algolia/algoliasearch-rails/pull/407)
- Fixed error when using `:check_settings => false` [`#413`](https://github.com/algolia/algoliasearch-rails/pull/413)

### Removed
- Old references to TravisCI [`#408`](https://github.com/algolia/algoliasearch-rails/pull/408)

## [2.1.3](https://github.com/algolia/algoliasearch-rails/compare/2.1.3...2.1.2)
### Fixed
- Prevent an extra get_settings call even if `check_settings` is false [`#367`](https://github.com/algolia/algoliasearch-rails/pull/367)

## [2.1.2](https://github.com/algolia/algoliasearch-rails/compare/2.1.2...2.1.1)
### Fixed
- Error with keys that got symbolized by default [`#403`](https://github.com/algolia/algoliasearch-rails/pull/403)

## [2.1.1](https://github.com/algolia/algoliasearch-rails/compare/2.1.1...2.1.0)
### Fixed
- Error with Ruby 3 in regards to default splat behavior [`#400`](https://github.com/algolia/algoliasearch-rails/pull/400)

## [2.1.0](https://github.com/algolia/algoliasearch-rails/compare/2.1.0...2.0.0)
### Added
- Add support for [virtual replicas](https://www.algolia.com/doc/guides/managing-results/refine-results/sorting/in-depth/replicas/#what-are-virtual-replicas) ([#386](https://github.com/algolia/algoliasearch-rails/pull/386))


## [2.0.0](https://github.com/algolia/algoliasearch-rails/compare/2.0.0...1.25.0)

### Breaking changes
- Adds support for `algolia` gem.
- Drops support for Ruby < 2.4
- Drops support for Rails < 5.1

## [1.25.0](https://github.com/algolia/algoliasearch-rails/compare/1.24.1...1.25.0) (2020-11-24)

### Added
- Pass array argument to geoloc ([#372](https://github.com/algolia/algoliasearch-rails/pull/372))
- Containerize the repo ([#391](https://github.com/algolia/algoliasearch-rails/pull/391))

### Fixed
- Use Zeitwerk for loading models in Rails 6 ([#364](https://github.com/algolia/algoliasearch-rails/pull/364))

## [1.24.1](https://github.com/algolia/algoliasearch-rails/releases/tag/1.24.1) (2020-07-15)

**Fixed**

* Fixes ruby warning 'Proc.new is deprecated'

## [1.24.0](https://github.com/algolia/algoliasearch-rails/releases/tag/1.24.0) (2020-02-21)

**Added**

* Adds indexLanguages in index settings

## [1.23.2](https://github.com/algolia/algoliasearch-rails/releases/tag/1.23.2) (2019-06-26)

**Fixed**

* Use `copy_index` when initiating a temporary index to preserve settings, synonyms, and rules.


## [1.23.0](https://github.com/algolia/algoliasearch-rails/releases/tag/1.23.0) (2019-06-25)

**Added**

* Introduce `rake algoliasearch:set_all_settings` command - PR [#315](https://github.com/algolia/algoliasearch-rails/pull/315)

    This command will push settings for all models to all indices: primary index,
    replicas and additional indices. It follows the `inherit: true` option.
    It should typically be added to your deployment script

* Add option to disable automatic settings - PR [#315](https://github.com/algolia/algoliasearch-rails/pull/315)

    By default, this gem check your settings to see when to push them. Depending on
    your implementation, it might create a lot of API calls. If you wish to disable
    the automatic change detection for settings, use the `check_settings` option:

    ```ruby
    class Musician < ActiveRecord::Base
      include AlgoliaSearch

      algoliasearch check_settings: false do
        # Settings...
      end
    end
    ```

**Fixed**

* Handle attribute_changed? in transactions - PR [#354](https://github.com/algolia/algoliasearch-rails/pull/354)


## [1.22.0](https://github.com/algolia/algoliasearch-rails/releases/tag/1.22.0) (2019-03-21)

🚨 The documentation for our Rails integration was refreshed 🎉
https://www.algolia.com/doc/framework-integration/rails/getting-started/setup/

**Added**

* Introduce `algolia_dirty?` on models to decide if a model should be reindex.

    This feature already exists via _changed? methods but might requires to implements many
    methods if you have multiple dynamic attributes. Dynamic attributes are attributes not mapping
    to a DB column. This feature allows you to group avoid all the _changed? method calls and
    group all the logic inside one unique method.

**Fixed**

* Fix _changed? method call for Rails 5.2+ with dynamic attribute - PR [#338](https://github.com/algolia/algoliasearch-rails/pull/338)

    Related issue: https://github.com/algolia/algoliasearch-rails/issues/140
    Documentation: https://www.algolia.com/doc/framework-integration/rails/indexing/indexing/#automatic-updates


## [1.21.0](https://github.com/algolia/algoliasearch-rails/releases/tag/1.21.0) (2019-02-12)

**Added**

* Add `AlgoliaSearch::IndexSettings::DEFAULT_BATCH_SIZE` constant - PR [#319](https://github.com/algolia/algoliasearch-rails/pull/319)

* Support ActiveModel Serializer 🎉 - PR [#266](https://github.com/algolia/algoliasearch-rails/pull/266)

    ```ruby
    class SerializedObject < ActiveRecord::Base
        include AlgoliaSearch

        algoliasearch do

            use_serializer SerializedObjectSerializer

            tags do
                ['tag1', 'tag2']
            end

        end
    end
    ```

**Fixed**

* Add support for all new recent engine settings - PR [#327](https://github.com/algolia/algoliasearch-rails/pull/327)

    Algolia regularly introduce new settings, all of them are supported by this gem.

2018-12-07 1.20.6

    * Better support for Rails 5.1 and deprecated `attribute_changed?`
    * Better support for `after_commit` for Sequel 5.0

2017-12-04 1.20.4

      * Remove Bundler and RubyGems requirements

2017-11-02 1.20.2

      * Upgrade algoliasearch gem to 1.17.0

2017-08-04 1.20.1

      * Make sure objectIDs are manipulated as strings

2017-07-31 1.20.0

      * Override the user-agent (#238)
      * Fixed NPE while running mocked tests (#242)
      * Add `paginationLimitedTo` setting (#243)
      * Make `algolia_without_auto_index_scope` thread-safe (#234)

2017-03-13 1.19.1

      * Make sure get_model_classes is not ActiveRecord compliant only

2017-03-13 1.19.0

      * Rewrote the algoliasearch:reindex rake task to better detect models to reindex
      * Fixed the handling of `raise_on_failture` for class methods

2017-02-16 1.18.0

      * Add new replica parameter, `inherit` (#198)

2017-01-05 1.17.1

      * Add missing `disablePrefixOnAttributes` and `disableTypoToleranceOnAttributes` attributes (#193)

2017-01-05 1.17.0

      * Do not enqueue indexing operations if the indexing is disabled
      * Add `searchableAttributes` and `numericAttributesForFiltering` index settings
      * Fixed here and there synchronous behaviors (mostly unit tests related)
      * Rename `slave` to `replica`
      * Upgraded `algoliasearch-client-{ruby,js}` deps

2016-11-25 1.16.3

      * Propagate `search_facet` to `search_for_facet_values` renaming (backward compatible)
      * Upgrade `algoliasearch` dependency to ~> 1.12.1
      * Add missing `typoTolerance` setting

2016-11-14 1.16.2

      * Add missing disableTypoToleranceOnAttributes and disableTypoToleranceOnWords index settings

2016-11-04 1.16.1

      * Added IndexSettings#get_attribute_names
      * Refactored IndexSettings#get_attributes
      * algolia_must_reindex? doesn't compute attribute values anymore

2016-10-02 1.16.0

      * Upgrade `algoliasearch` to 1.12.0
      * Add `search_facet` method

2016-10-02 1.15.1

      * Missing `advancedSyntax` index setting forward

2016-08-21 1.15.0

      * Upgrade to AlgoliaSearch JS API client 3.18.0
      * Upgrade to AlgoliaSearch Ruby API client 1.11.0
      * Official support of Rails 5.x
      * Reduce 404 logging if get_settings on a non-existing index
      * Here and there fixes

2015-08-19 1.14.1

      * Upgrade to AlgoliaSearch JS API client 3.7.5

2015-08-11 1.14.0

      * Add numericAttributesToIndex index setting

2015-08-07 1.13.4

      * Do not consider the per_environment option while initializing the temporary index.

2015-08-05 1.13.3

      * The `active_job.rb` file was not included in the gem

2015-08-01 1.13.2

      * Lazy load the `ActiveJob` class to ensure the underlying queuing system is initialized when we actually use it.

2015-07-20 1.13.1

      * Use `after_commit` instead of `after_save` to ensure we index once in the DB

2015-06-21 1.13.0

      * Ability to use a background queue to handle all automatic indexing operations
      * Fix a bug avoiding the gem to remove records when using the Sequel ORM

2015-05-28 1.12.2

      * Add a new `raise_on_failure` option, controlling whereas exceptions are raised while trying to reach Algolia's API.

2015-05-12 1.12.1

      * Upgrade to algoliasearch-client-js 3.3.0

2015-04-29 1.12.0

      * Add Sequel support.

2015-03-31 1.11.18

      * Embed AlgoliaSearch JS API client v3 as well. Default is still the v2 to keep the backward compatibility.

2015-03-08 1.11.17

      * Add missing index settings (including removeWordsIfNoResults, unretrievableAttributes and ignorePlurals)

2015-02-23 1.11.16

      * Include jQuery & Angular related builds in the gem

2015-02-23 1.11.15

      * Algoliasearch-client-js: embed jQuery & angular based builds as well

2015-02-23 1.11.14

      * Upgrade to algoliasearch-client-js 2.9.2

2015-02-03 1.11.13

      * Upgrade to algoliasearch-client-js 2.8.6

2015-01-29 1.11.12

      * Fixed potential namespace issue while trying to load the HTML sanitizer

2014-11-27 1.11.11

      * Upgraded algoliasearch JavaScript client to 2.7.5 to prepare TLD migration

2014-11-21 1.11.10

      * Ability to force the UTF-8 encoding of the underlying attributes before sending them to our API

2014-11-12 1.11.9

      * Upgraded algoliasearch JavaScript client to 2.7.4 & algoliasearch-client-ruby to 1.2.14

2014-10-29 1.11.8

      * Upgraded algoliasearch JavaScript client to 2.7.3

2014-10-16 1.11.7

      * Upgraded to algoliasearch-client-ruby>=1.2.12 to ensure we're not using SSLv3

2014-10-15 1.11.6

      * Upgraded algoliasearch JavaScript client to 2.7.1

2014-10-15 1.11.5

      * Upgraded algoliasearch JavaScript client from 2.5.3 to 2.7.0

2014-10-05 1.11.4

      * Do not compute the 'slaves' index settings on slaves (breaking the diff between current & configured version)

2014-09-16 1.11.3

      * While reindexing, fetch the master's settings to setup the temporary index

2014-09-02 1.11.2

      * Ability to search in a slave or extra index using the ```:index```/```:slave``` parameter

2014-08-25 1.11.1

      * While using a temporary index to reindex, do not set the "slaves" index setting (will be set at move-time)
      * Ability to strip HTML tags from attributes

2014-08-20 1.11.0

      * Do not rely of _changed? method to detect reindexing needs, if those methods are missing we probably need to reindex

2014-08-07 1.10.9

      * Upgrade to algoliasearch-client-js 2.5.3
      * Upgrade to typeahead 1.10.4

2014-08-07 1.10.8

      * Fixes searches on Mongoid introduced in 1.10.7 (author: @zarqman)

2014-07-17 1.10.7

      * Query optimization: load search results from database using a single query (author: @outoftime)

2014-07-10 1.10.6

      * Pass the configuration hash to the underlying ```Algolia.init``` method.

2014-07-09 1.10.5

      * Safely reindex your data using ```MyModel.reindex``` (index with a temporary index + move), ```MyModel.reindex!``` do it in-place without removing out-dated records

2014-06-28 1.10.4

      * Ability to disable all indexing tasks (testing purpose)

2014-06-17 1.10.3

      * Pagination: fixed a padding issue with recent versions of Kaminari

2014-05-09 1.10.2

      * Expose synoyms/placeholders features
      * Upgrade to algoliasearch-client-js 2.5.0 (fallback on JSONP if CORS is not available)

2014-04-29 1.10.1

      * Use :if and :unless constraints to detect if a record has changed as well

2014-04-28 1.10.0

      * Ability to configure slave indexes from the ```algoliasearch``` block
      * Ability to target multiple indexes from a single model class

2014-04-23  1.9.5

      * Add missing highlightPreTag/highlightPostTag settings

2014-03-30  1.9.4

      * Ability to index an array of objects using the `index_objects` method. Ref #15
      * Upgrade typeahead.js to 0.10.2 (fixed flickering)
      * Upgrade algoliasearch-client-ruby to 1.2.8 (fixed unhandled exception)
      * Upgrade algoliasearch-client-js to 2.4.5 (embed last ExplainResults helper fixes)

2014-03-26  1.9.3

      * Ruby 1.8 compatibility
      * Fixed a bug ignoring hitsPerPage parameter while using backend pagination (will_paginate/kaminari)

2014-03-17  1.9.2

      * Raise an exception while attempting to index a non-saved object (blank objectID)

2014-03-06  1.9.1

      * When using MongoId, the `reindex!` method was calling add_objects too many times. (credits go to sush.io)

2014-02-24  1.9.0

      * Upgrade to algoliasearch 1.2.5 and algoliasearch-client-js 2.4.2
      * Fixed pagination starting at 1 in Kaminari & WillPaginate and 0 in Algolia
      * As soon as :if or :unless are used, we need to remove the objects from the index
        if the constraints don't match

2014-02-15  1.8.2

      * Ability to retrieve facets and raw answer as well

2014-02-14  1.8.1

      * Fixed backend pagination not taking current page into account at display time.

2014-02-12  1.8.0

      * Upgrade to official Twitter Typeahead.js 0.10.1 (/!\ API has changed)
      * Fixed reindexing rake task (#12)

2014-02-04  1.7.2

      * Add a ```raw_search``` method, retrieving the JSON raw answer
      * Support STI subclasses (#11)
      * Updated dependencies

2014-01-31  1.7.1

      * Ensure methods are not conflicting with already defined ones (use algolia_METHOD_NAME)
      * Add ```:if``` and ```:unless``` options to control objects indexing (#10)

2014-01-07  1.7.0

      * Updated algoliasearch to 1.2 (httpclient instead of curb as underlying HTTP layer)
      * jruby, rbx and ruby 2.1 compatibility

2014-01-02  1.6.3

      * Expose new ```attributeForDistinct``` setting

2013-12-17  1.6.2

      * Updated deps (included algoliasearch 1.1.15 and algoliasearch-client-js 2.3.6)

2013-12-05  1.6.1

      * ```add_attribute``` can now be used to add extra attributes in addition to the existing ones
      * Use the ```geoloc``` and ```tags``` methods to generate the associated ```_tags``` and ```_geoloc``` attributes

2013-12-05  1.5.2

      * object's attributes must be fetched unscoped to ensure associations will not be impacted by the conditions
      * you can now use `Model.index` to access the underlying index object

2013-12-03  1.5.1

      * ability to specify which attribute is used as objectID

2013-11-29  1.4.5

      * updated algoliasearch-client-js to 2.3.3

2013-11-29  1.4.4

      * updated algoliasearch to 1.1.11

2013-11-29  1.4.3

      * updated algoliasearch-client-js to 2.3.2
      * updated algoliasearch to 1.1.10

2013-11-25  1.4.2

      * fixed const_get calls with ruby 1.9.3

2013-11-25  1.4.1

      * ability to specify a block associated to an attribute as value

2013-11-22  1.3.10

      * updated algoliasearch.js (2.3.2)

2013-11-21  1.3.9

      * updated custom typeahead.js (merged https://github.com/twitter/typeahead.js/pull/390)

2013-11-21  1.3.8

      * expose new index settings: separatorsToIndex and optionalWords

2013-11-19  1.3.7

      * handle namespaced models (s/::/_/)

2013-11-08  1.3.6

      * upgraded to algoliasearch 1.1.6 (array-based search parameters were not encoded)

2013-11-07  1.3.5

      * add without_auto_index_scope method disabling all indexing operations inside associated block

2013-11-07  1.3.4

      * updated algoliasearch to 1.1.6 (clear_index! is now a real clear, not a delete/create) and algoliasearch-client-js to 2.3.0
      * restore missing ensure_init call in the ```search``` method

2013-11-07  1.3.3

      * new :per_environment options suffixing index's name by the Rails environment
      * index's settings are now initialized on first usage, not at include time
      * plug attributesForFaceting setting

2013-10-17  1.3.2

      * while detecting settings changes, fixed array comparison

2013-10-17  1.3.1

      * upgraded to algoliasearch 1.1.4 (too aggressive wait_task calls)

2013-10-15  1.3.0

      * synchronous flag is now false by default
      * do not set settings if they didn't chang

2013-10-15  1.2.1

      * Updated deps, especially algoliasearch to 1.1.3 to solve thread-safety issues

2013-10-14  1.2.0

      * embeds a typeahead.js based UI

2013-10-04  1.1.8

      * Avoid concurrent access to the same index while running tests with TravisCI
      * to check if the full-reindexing has been done, checking the last task is enough

2013-10-02  1.1.7

      * Updated environment variables
      * Plug travis and various badges
      * Fixed attribute changes detection
      * Upgrade to algoliasearch-client-ruby 1.1.1

2013-10-01  1.1.6

      * Initial import

