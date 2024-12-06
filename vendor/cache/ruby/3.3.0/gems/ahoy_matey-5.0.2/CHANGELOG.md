## 5.0.2 (2023-10-05)

- Excluded visits from Rails health check

## 5.0.1 (2023-10-01)

- Fixed error with geocoding with anonymity sets

## 5.0.0 (2023-10-01)

- Changed visits to expire with anonymity sets
- Fixed error when Active Job is not available
- Fixed deprecation warning with Rails 7.1
- Dropped support for Ruby < 3 and Rails < 6.1
- Dropped support for Mongoid 6

## 4.2.1 (2023-02-23)

- Updated Ahoy.js to 0.4.2

## 4.2.0 (2023-02-07)

- Added primary key type to generated migration
- Updated Ahoy.js to 0.4.1

## 4.1.0 (2022-06-12)

- Ensure `exclude_method` is only called once per request
- Fixed error with Mongoid when `Mongoid.raise_not_found_error` is `true`
- Fixed association for Mongoid

## 4.0.3 (2022-01-15)

- Support for `importmap-rails` is no longer experimental
- Fixed asset precompilation error with `importmap-rails`

## 4.0.2 (2021-11-06)

- Added experimental support for `importmap-rails`

## 4.0.1 (2021-08-18)

- Added support for `where_event`, `where_props`, and `where_group` for SQLite
- Fixed results with `where_event` for MySQL, MariaDB, and Postgres `hstore`
- Fixed results with `where_props` and `where_group` when used with other scopes for MySQL, MariaDB, and Postgres `hstore`

## 4.0.0 (2021-08-14)

- Disabled geocoding by default (this was already the case for new installations with 3.2.0+)
- Made the `geocoder` gem an optional dependency
- Updated Ahoy.js to 0.4.0
- Updated API to return 400 status code when missing required parameters
- Dropped support for Ruby < 2.6 and Rails < 5.2

## 3.3.0 (2021-08-13)

- Added `country_code` to geocoding
- Updated Ahoy.js to 0.3.9
- Fixed install generator for MariaDB

## 3.2.0 (2021-03-01)

- Disabled geocoding by default for new installations
- Fixed deprecation warning with Active Record 6.1

## 3.1.0 (2020-12-04)

- Added `instance` method
- Added `request` argument to `user_method`
- Updated Ahoy.js to 0.3.8
- Removed `exclude_method` call when geocoding

## 3.0.5 (2020-09-09)

- Added `group_prop` method
- Use `datetime` type in migration

## 3.0.4 (2020-06-07)

- Updated Ahoy.js to 0.3.6

## 3.0.3 (2020-04-17)

- Updated Ahoy.js to 0.3.5

## 3.0.2 (2020-04-03)

- Added `cookie_options`

## 3.0.1 (2019-09-21)

- Made `Ahoy::Tracker` work outside of requests
- Fixed storage of `false` values with customized store
- Fixed error with `user_method` and `Rails::InfoController`
- Gracefully handle `ActionDispatch::RemoteIp::IpSpoofAttackError`

## 3.0.0 (2019-05-29)

- Made Device Detector the default user agent parser
- Made v2 the default bot detection version
- Removed a large number of dependencies
- Removed search keyword detection (most search engines today prevent this)
- Removed support for Rails < 5

## 2.2.1 (2019-05-26)

- Updated Ahoy.js to 0.3.4
- Fixed v2 bot detection
- Added latitude and longitude to installation

## 2.2.0 (2019-01-04)

- Added `amp_event` helper
- Improved bot detection for Device Detector

## 2.1.0 (2018-05-18)

- Added option for IP masking
- Added option to use anonymity sets instead of cookies
- Added `user_agent_parser` option
- Fixed `visitable` for Rails 4.2
- Removed `search_keyword` from new installs

## 2.0.2 (2018-03-14)

- Fixed error on duplicate records
- Fixed message when visit not found for geocoding
- Better compatibility with GeoLite2
- Better browser compatibility for Ahoy.js

## 2.0.1 (2018-02-26)

- Added `Ahoy.server_side_visits = :when_needed` to automatically create visits server-side when needed for events and `visitable`
- Better handling of visit duration and expiration in JavaScript

## 2.0.0 (2018-02-25)

- Removed dependency on jQuery
- Use `navigator.sendBeacon` by default in supported browsers
- Added `geocode` event
- Added `where_event` method for querying events
- Added support for `visitable` and `where_props` to Mongoid
- Added `preserve_callbacks` option
- Use `json` for MySQL by default
- Fixed log silencing

Breaking changes

- Simpler interface for data stores
- Renamed `track_visits_immediately` to `server_side_visits` and enabled by default
- Renamed `mount` option to `api` and disabled by default
- Enabled `protect_from_forgery` by default
- Removed deprecated options
- Removed throttling
- Removed most built-in stores
- Removed support for Rails < 4.2

## 1.6.1 (2018-02-02)

- Added `gin` index on properties for events
- Fixed `visitable` options when name not provided

## 1.6.0 (2017-05-01)

- Added support for Rails 5.1

## 1.5.5 (2017-03-23)

- Added support for Rails API
- Added NATS and NSQ stores

## 1.5.4 (2017-01-22)

- Fixed issue with duplicate events
- Added support for PostGIS for `where_properties`

## 1.5.3 (2016-10-31)

- Fixed error with Rails 5 and Mongoid 6
- Fixed regression with server not generating visit and visitor tokens
- Accept UTM parameters as request parameters (for native apps)

## 1.5.2 (2016-08-26)

- Better support for Rails 5

## 1.5.1 (2016-08-19)

- Restored throttling after removing side effects

## 1.5.0 (2016-08-19)

- Removed throttling due to unintended side effects with its implementation
- Ensure basic token requirements
- Fixed visit recreation on cookie expiration
- Fixed issue where `/ahoy/visits` is called indefinitely when `Ahoy.cookie_domain = :all`

## 1.4.2 (2016-06-21)

- Fixed issues with `where_properties`

## 1.4.1 (2016-06-20)

- Added `where_properties` method
- Added Kafka store
- Added `mount` option
- Use less intrusive version of `safely`

## 1.4.0 (2016-03-23)

- Use `ActiveRecordTokenStore` by default (integer instead of uuid for id)
- Detect database for `rails g ahoy:stores:active_record` for easier installation
- Use `safely` as default exception handler
- Fixed issue with log silencer
- Use multi-column indexes on `ahoy_events` table creation

## 1.3.1 (2016-03-22)

- Raise errors in test environment

## 1.3.0 (2016-03-06)

- Added throttling
- Added `max_content_length` and `max_events_per_request`

## 1.2.2 (2016-03-05)

- Fixed issue with latest version of `browser` gem
- Added support for RabbitMQ
- Added support for Amazon Kinesis Firehose
- Fixed deprecation warnings in Rails 5

## 1.2.1 (2015-08-14)

- Fixed `SystemStackError: stack level too deep` when used with `activerecord-session_store`

## 1.2.0 (2015-06-07)

- Added support for PostgreSQL `jsonb` column type
- Added Fluentd store
- Added latitude, longitude, and postal_code to visits
- Log exclusions

## 1.1.1 (2015-01-05)

- Better support for Authlogic
- Added `screen_height` and `screen_width`

## 1.1.0 (2014-11-02)

- Added `geocode` option
- Report errors to service by default
- Fixed association mismatch

## 1.0.2 (2014-07-10)

- Fixed BSON for Mongoid 3
- Fixed Doorkeeper integration
- Fixed user tracking in overridden authenticate method

## 1.0.1 (2014-06-27)

- Fixed `visitable` outside of requests

## 1.0.0 (2014-06-18)

- Added support for any data store, and Mongoid out of the box
- Added `track_visits_immediately` option
- Added exception catching and reporting
- Visits expire after inactivity, not fixed interval
- Added `visit_duration` and `visitor_duration` options

## 0.3.2 (2014-06-15)

- Fixed bot exclusion for visits
- Fixed user method

## 0.3.1 (2014-06-12)

- Fixed visitor cookies when set on server
- Added `domain` option for server cookies

## 0.3.0 (2014-06-11)

- Added `current_visit_token` and `current_visitor_token` method
- Switched to UUIDs
- Quiet endpoint requests
- Skip server-side bot events
- Added `request` argument to `exclude_method`

## 0.2.2 (2014-05-26)

- Added `exclude_method` option
- Added support for batch events
- Fixed cookie encoding
- Fixed `options` variable from being modified

## 0.2.1 (2014-05-16)

- Fixed IE 8 error
- Added `track_bots` option
- Added `$authenticate` event

## 0.2.0 (2014-05-13)

- Added event tracking (merged ahoy_events)
- Added ahoy.js

## 0.1.8 (2014-05-11)

- Fixed bug with `user_type` set to `false` instead of `nil`

## 0.1.7 (2014-05-11)

- Made cookie functions public for ahoy_events

## 0.1.6 (2014-05-07)

- Better user agent parser

## 0.1.5 (2014-05-01)

- Added support for Doorkeeper
- Added options to `visitable`
- Added `landing_params` method

## 0.1.4 (2014-04-27)

- Added `ahoy.ready()` and `ahoy.log()` for events

## 0.1.3 (2014-04-24)

- Supports `current_user` from `ApplicationController`
- Added `ahoy.reset()`
- Added `ahoy.debug()`
- Added experimental support for native apps
- Prefer `ahoy` over `Ahoy`

## 0.1.2 (2014-04-15)

- Attach user on Devise sign up
- Ability to specify visit model

## 0.1.1 (2014-03-20)

- Made most database columns optional
- Performance hack for referer-parser

## 0.1.0 (2014-03-19)

- First major release
