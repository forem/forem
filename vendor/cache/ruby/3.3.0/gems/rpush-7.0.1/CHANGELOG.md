# Changelog

## [v7.0.1](https://github.com/rpush/rpush/tree/v7.0.1) (2022-03-02)

[Full Changelog](https://github.com/rpush/rpush/compare/v7.0.0...v7.0.1)

**Merged pull requests:**

- Fix deprecation warnings from the redis gem [\#636](https://github.com/rpush/rpush/pull/636) ([sharang-d](https://github.com/sharang-d))

## [Unreleased](https://github.com/rpush/rpush/tree/HEAD)

[Full Changelog](https://github.com/rpush/rpush/compare/v7.0.0...HEAD)

## [v7.0.0](https://github.com/rpush/rpush/tree/HEAD)

[Full Changelog](https://github.com/rpush/rpush/compare/v6.0.1...v7.0.0)

**Merged pull requests:**

- Test with Ruby 3.1 [\#632](https://github.com/rpush/rpush/pull/632) ([aried3r](https://github.com/aried3r))
- Resolves Rails 7 Time.now.to\_s deprecation warning [\#630](https://github.com/rpush/rpush/pull/630) ([gregblake](https://github.com/gregblake))
- Adds Rails 7 Support [\#629](https://github.com/rpush/rpush/pull/629) ([gregblake](https://github.com/gregblake))
- Test with Rails 7.0.0.alpha2 [\#626](https://github.com/rpush/rpush/pull/626) ([aried3r](https://github.com/aried3r))

**Breaking:**

- Drop support for Ruby 2.3 [\#631](https://github.com/rpush/rpush/pull/631) ([aried3r](https://github.com/aried3r))

## [v6.0.1](https://github.com/rpush/rpush/tree/v6.0.1) (2021-10-08)

[Full Changelog](https://github.com/rpush/rpush/compare/v6.0.0...v6.0.1)

**Merged pull requests:**

- Don't limit webpush registration keys [\#624](https://github.com/rpush/rpush/pull/624) ([treyrich](https://github.com/treyrich))
- Add Prometheus Exporter plugin link to README [\#617](https://github.com/rpush/rpush/pull/617) ([maxsz](https://github.com/maxsz))
- Reference current interface in config template [\#569](https://github.com/rpush/rpush/pull/569) ([benlangfeld](https://github.com/benlangfeld))
- Default the Rails environment to RAILS\_ENV if set [\#562](https://github.com/rpush/rpush/pull/562) ([benlangfeld](https://github.com/benlangfeld))

## [v6.0.0](https://github.com/rpush/rpush/tree/v6.0.0) (2021-05-21)

[Full Changelog](https://github.com/rpush/rpush/compare/v5.4.0...v6.0.0)

This release contains **breaking changes**, such as removing support for Rails versions older than 5.2.
Please see the details in the PRs below.

**Merged pull requests:**

- Switch to GitHub Actions for CI [\#615](https://github.com/rpush/rpush/pull/615) ([aried3r](https://github.com/aried3r))
- Prepare 6.0.0 release [\#613](https://github.com/rpush/rpush/pull/613) ([aried3r](https://github.com/aried3r))
- Bump activesupport version to 5.2 or later [\#610](https://github.com/rpush/rpush/pull/610) ([biow0lf](https://github.com/biow0lf))
- Fixed infinite loop issue with Apnsp8 delivery [\#608](https://github.com/rpush/rpush/pull/608) ([diminish7](https://github.com/diminish7))
- Eliminate deprecation warning in Ruby 3.0 [\#602](https://github.com/rpush/rpush/pull/602) ([rofreg](https://github.com/rofreg))
- Make ActiveRecord validations work with Apns2 client [\#601](https://github.com/rpush/rpush/pull/601) ([favrik](https://github.com/favrik))
- Bump gemspec post\_install\_message [\#600](https://github.com/rpush/rpush/pull/600) ([fdoxyz](https://github.com/fdoxyz))
- Remove references and checks for unsupported versions of Rails [\#599](https://github.com/rpush/rpush/pull/599) ([ericsaupe](https://github.com/ericsaupe))
- Drop support for Rails 5.0 and 5.1 [\#597](https://github.com/rpush/rpush/pull/597) ([ericsaupe](https://github.com/ericsaupe))
- Fix silent APNS notifications for Apns2 and Apnsp8 [\#596](https://github.com/rpush/rpush/pull/596) ([shved270189](https://github.com/shved270189))
- Updates README to Apple's new EOL date for the APNs legacy binary protocol [\#595](https://github.com/rpush/rpush/pull/595) ([gregblake](https://github.com/gregblake))

## [v5.4.0](https://github.com/rpush/rpush/tree/v5.4.0) (2021-02-15)

[Full Changelog](https://github.com/rpush/rpush/compare/v5.3.0...v5.4.0)

**Merged pull requests:**

- fix typo in README.md [\#587](https://github.com/rpush/rpush/pull/587) ([yltsrc](https://github.com/yltsrc))
- Support Ruby 3.0 & Rails 6.1 [\#586](https://github.com/rpush/rpush/pull/586) ([andreaslillebo](https://github.com/andreaslillebo))

## [v5.3.0](https://github.com/rpush/rpush/tree/v5.3.0) (2021-01-07)

[Full Changelog](https://github.com/rpush/rpush/compare/v5.2.0...v5.3.0)

**Implemented enhancements:**

- support for Webpush with VAPID [\#574](https://github.com/rpush/rpush/pull/574) ([jkraemer](https://github.com/jkraemer))

**Merged pull requests:**

- Bug fix: APNS P8 Notifications Are Marked as Invalid When the Payload Exceeds 2kb \(2048 bytes\) [\#583](https://github.com/rpush/rpush/pull/583) ([gregblake](https://github.com/gregblake))
- Fix more Rails 6.1 deprecation warnings [\#582](https://github.com/rpush/rpush/pull/582) ([jas14](https://github.com/jas14))
- Feature/apns2 default headers [\#579](https://github.com/rpush/rpush/pull/579) ([jkraemer](https://github.com/jkraemer))
- Fix APNS2 documentation in README [\#578](https://github.com/rpush/rpush/pull/578) ([jamestjw](https://github.com/jamestjw))
- Fixed typo with misspell [\#575](https://github.com/rpush/rpush/pull/575) ([hsbt](https://github.com/hsbt))

## [v5.2.0](https://github.com/rpush/rpush/tree/v5.2.0) (2020-10-08)

[Full Changelog](https://github.com/rpush/rpush/compare/v5.1.0...v5.2.0)

**Merged pull requests:**

- Allow opting out of foreground stdout logging [\#571](https://github.com/rpush/rpush/pull/571) ([benlangfeld](https://github.com/benlangfeld))
- Do not retry notifications which already have been delivered/failed [\#567](https://github.com/rpush/rpush/pull/567) ([AlexTatarnikov](https://github.com/AlexTatarnikov))
- Improve APNs documentation. [\#553](https://github.com/rpush/rpush/pull/553) ([timdiggins](https://github.com/timdiggins))

## [v5.1.0](https://github.com/rpush/rpush/tree/v5.1.0) (2020-09-25)

[Full Changelog](https://github.com/rpush/rpush/compare/v5.0.0...v5.1.0)

**Merged pull requests:**

- Resume APNS2 delivery when async requests timeout [\#564](https://github.com/rpush/rpush/pull/564) ([benlangfeld](https://github.com/benlangfeld))
- Improve DB reconnection for big tables [\#563](https://github.com/rpush/rpush/pull/563) ([AlexTatarnikov](https://github.com/AlexTatarnikov))
- Default the Rails environment to RAILS_ENV if set [\#562](https://github.com/rpush/rpush/pull/562) ([benlangfeld](https://github.com/benlangfeld))
- Allow Apns2 payloads to be up to 4096 bytes [\#561](https://github.com/rpush/rpush/pull/561) ([benlangfeld](https://github.com/benlangfeld))
- Improve test coverage [\#528](https://github.com/rpush/rpush/pull/528) ([jhottenstein](https://github.com/jhottenstein))

## [v5.0.0](https://github.com/rpush/rpush/tree/v5.0.0) (2020-02-21)

[Full Changelog](https://github.com/rpush/rpush/compare/v4.2.0...v5.0.0)

**Merged pull requests:**

- Test with Ruby 2.7 [\#550](https://github.com/rpush/rpush/pull/550) ([aried3r](https://github.com/aried3r))
- Fix GCM priority when using Redis [\#549](https://github.com/rpush/rpush/pull/549) ([daniel-nelson](https://github.com/daniel-nelson))
- Drop support for Rails 4.2 [\#547](https://github.com/rpush/rpush/pull/547) ([aried3r](https://github.com/aried3r))

## 4.2.0 (2019-12-13)

[Full Changelog](https://github.com/rpush/rpush/compare/v4.1.1...v4.2.0)

**Merged pull requests:**

- Fix Rails 6.1 related deprecation warnings [\#541](https://github.com/rpush/rpush/pull/541) ([dsantosmerino](https://github.com/dsantosmerino))
- GCM notification incorrectly mixes data into notification hashes [\#535](https://github.com/rpush/rpush/pull/535) ([mkon](https://github.com/mkon))
- handle priority in WNS [\#533](https://github.com/rpush/rpush/pull/533) ([Fivell](https://github.com/Fivell))
- Update development apns urls to match documentation [\#524](https://github.com/rpush/rpush/pull/524) ([jhottenstein](https://github.com/jhottenstein))
- Update README to remove incorrect info [\#523](https://github.com/rpush/rpush/pull/523) ([sharang-d](https://github.com/sharang-d))
- Fix and improve Travis setup [\#520](https://github.com/rpush/rpush/pull/520) ([aried3r](https://github.com/aried3r))
- Explicitly use Rails 6.0.0 [\#519](https://github.com/rpush/rpush/pull/519) ([jsantos](https://github.com/jsantos))
- Stale bot config change [\#515](https://github.com/rpush/rpush/pull/515) ([aried3r](https://github.com/aried3r))
- Add stale bot configuration. [\#514](https://github.com/rpush/rpush/pull/514) ([drn](https://github.com/drn))
- Correctly use feedback_enabled. [\#511](https://github.com/rpush/rpush/pull/511) ([kirbycool](https://github.com/kirbycool))
- Update apns_http2.rb [\#510](https://github.com/rpush/rpush/pull/510) ([mldoscar](https://github.com/mldoscar))
- Add `mutable_content` support for GCM [\#506](https://github.com/rpush/rpush/pull/506) ([hon3st](https://github.com/hon3st))
- Add support for critical alerts [\#502](https://github.com/rpush/rpush/pull/502) ([servn](https://github.com/servn))

## 4.1.1 (2019-05-13)

### Added

- Allow disabling of APNS feedback for specific Rpush apps [#491](https://github.com/rpush/rpush/pull/491) (by [@drn](https://github.com/drn)).

### Changed

- Switch from ANSI to Rainbow. ([#496](https://github.com/rpush/rpush/pull/496) by [@drn](https://github.com/drn))

## 4.1.0 (2019-04-17)

### Added

- Functionality to use `dry_run` in FCM notifications. This is useful if you want to just validate notification sending works without actually sending a notification to the receivers, fixes #63. ([#492](https://github.com/rpush/rpush/pull/492) by [@aried3r](https://github.com/aried3r))

## 4.0.1 (2019-04-04)

### Fixed

- Fail gracefully when a Modis notification no longer exists [#486](https://github.com/rpush/rpush/pull/486) (by [@rofreg](https://github.com/rofreg)).

## 4.0.0 (2019-02-14)

### Changed

- Stop logging all APNSp8 requests as warnings. [#474](https://github.com/rpush/rpush/pull/474) (by [@jhottenstein](https://github.com/jhottenstein) and [@rofreg](https://github.com/rofreg))

### Removed

- Support for Ruby 2.2

### Fixed

- Fixed APNSp8 memory leak [#475](https://github.com/rpush/rpush/pull/475) (by [@jhottenstein](https://github.com/jhottenstein))
- Fixed APNS2 memory leak. [#476](https://github.com/rpush/rpush/pull/476) (by [@jhottenstein](https://github.com/jhottenstein))

## 3.3.1 (2018-11-14)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

### Fixed

- Remove validation of 64-characters length from `device_token`. [#463](https://github.com/rpush/rpush/pull/463) (by [@chrisokamoto](https://github.com/chrisokamoto)).

## 3.3.0 (2018-11-14)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

### Added

- Added support for Apple Push Notification service `thread-id` field [#460](https://github.com/rpush/rpush/pull/460) (by [@gerard-morera](https://github.com/gerard-morera)).

### Changes

- Remove unused class `ConfigurationWithoutDefaults` [#461](https://github.com/rpush/rpush/pull/461) (by [@adis-io](https://github.com/adis-io)).

## 3.2.4 (2018-10-25)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

### Changes

- Relaxed JWT dependency version [#447](https://github.com/rpush/rpush/pull/447) (by [@sposin](https://github.com/sposin)).

### Docs

- Better documentation for running tests when developing Rpush [#458](https://github.com/rpush/rpush/pull/458) (by [@jsantos](https://github.com/jsantos)).

### Fixed

- Change `apn_key` column type from string to text [#455](https://github.com/rpush/rpush/pull/455) (by [sonxurxo](https://github.com/sonxurxo)).
- Retry all GCM 5xx errors [#456](https://github.com/rpush/rpush/pull/456) (by [@rofreg](https://github.com/rofreg)).

## 3.2.3 (2018-07-12)

### Changes

- Update jwt dependency from 1.x to 2.x [#444](https://github.com/rpush/rpush/pull/444) (by [@jsantos](https://github.com/jsantos)).

## 3.2.2 (2018-07-10)

### Fixed

- Migrations now work with Rails 5.2 and ActiveRecord. Redis support for Rails 5.2 is not yet working if you're using Modis, see [this issue](https://github.com/ileitch/modis/issues/13).

## 3.2.1 (2018-07-10)

### Fixed

- A memory leak in the Rpush daemon which caused it to consume more and more memory was fixed. [#441](https://github.com/rpush/rpush/pull/441) (by [@armahmoudi](https://github.com/armahmoudi))

## 3.2.0 (2018-06-13)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

### Breaking Changes

- None

### Added

- Added support for P8 certificate Apple push notifications [#386](https://github.com/rpush/rpush/pull/386) (by [@mariannegru](https://github.com/mariannegru))

## 3.1.1 (2018-04-16)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

### Breaking Changes

- None

### Added

- None

### Fixed

- Database deadlock [#200](https://github.com/rpush/rpush/issues/200) (by [@loadhigh](https://github.com/loadhigh) in [#428](https://github.com/rpush/rpush/issues/428))

### Enhancements

- Change the index on `rpush_notifications` to minimize number of locked records and pre-sort the records ([#428](https://github.com/rpush/rpush/issues/428) by [@loadhigh](https://github.com/loadhigh))
- Minimize the locking duration by moving the row dump code outside of the transaction ([#428](https://github.com/rpush/rpush/issues/428) by [@loadhigh](https://github.com/loadhigh))

## 3.1.0 (2018-04-11)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

### Breaking Changes

- None

### Added

- Added sandbox URL to `ApnsHttp2` dispatcher ([#392](https://github.com/rpush/rpush/pull/392) by [@brianlittmann](https://github.com/brianlittmann))

### Features

- Added support for [Pushy](https://pushy.me/) ([#404](https://github.com/rpush/rpush/pull/404) by [@zabolotnov87](https://github.com/zabolotnov87))

### Fixed

- `@notification.app` triggers loading of association :app ([#410](https://github.com/rpush/rpush/issues/410) by [@loadhigh](https://github.com/loadhigh))
- APNS expiry should be number of seconds since epoch ([#416](https://github.com/rpush/rpush/issues/416) by [@loadhigh](https://github.com/loadhigh))

### Enhancements

- Test rpush with Ruby 2.5 on Travis CI ([#407](https://github.com/rpush/rpush/pull/407) by [@Atul9](https://github.com/Atul9))

## 3.0.2 (2018-01-08)

#### Fixes

- Fixes migrations added in 3.0.1 ([#396](https://github.com/rpush/rpush/pull/396) by [@grosser](https://github.com/grosser))
- Actually run these migrations in the test suite ([#399](https://github.com/rpush/rpush/pull/399) by [@aried3r](https://github.com/aried3r))

## 3.0.1 (2017-11-30)

#### Enhancements

- Reduce booleans to true/false, do not allow nil ([#384](https://github.com/rpush/rpush/pull/384)) by [@grosser](https://github.com/grosser)
- Better error message for error 8 in APNS ([#387](https://github.com/rpush/rpush/pull/387/files)) by [@grosser](https://github.com/grosser)

## 3.0.0 (2017-09-15)

Same as 3.0.0.rc1 including:

#### Features

- Added support for latest modis version ([#378](https://github.com/rpush/rpush/pull/378)) by [@milgner](https://github.com/milgner)

## 3.0.0.rc1 (2017-08-31)

When upgrading, don't forget to run `bundle exec rpush init` to get all the latest migrations.

#### Features

- Added support for APNS `mutable-content` ([#296](https://github.com/rpush/rpush/pull/296) by [@tdtran](https://github.com/tdtran))
- Added support for HTTP2 base APNS Api ([#315](https://github.com/rpush/rpush/pull/315) by [@soulfly](https://github.com/soulfly) and [@Nattfodd](https://github.com/Nattfodd))

#### Changes

- **Breaking:** Dropped support for old Rubies and Rails versions. rpush 3.0 only supports Ruby versions 2.2.2 or higher and
  Rails 4.2 or higher. ([#366](https://github.com/rpush/rpush/pull/366) by [@aried3r](https://github.com/aried3r))
- **Breaking:** Dropped MongoDB support because there was no one maintaining it. But we're open to adding it back in. ([#366](https://github.com/rpush/rpush/pull/366) by [@aried3r](https://github.com/aried3r))
- **Breaking:** Dropped JRuby support. ([#366](https://github.com/rpush/rpush/pull/366) by [@aried3r](https://github.com/aried3r))

- Make synchronizer aware of GCM and WNS apps ([#254](https://github.com/rpush/rpush/pull/254) by [@wouterh](https://github.com/wouterh))
- Precise after init commit msg ([#266](https://github.com/rpush/rpush/pull/266) by [@azranel](https://github.com/azranel))
- Use new GCM endpoint ([#303](https://github.com/rpush/rpush/pull/303) by [@aried3r](https://github.com/aried3r))
- Remove sound default value ([#320](https://github.com/rpush/rpush/pull/320) by [@amaierhofer](https://github.com/amaierhofer))

#### Bugfixes

- ~~~Lock `net-http-persistent` dependency to `< 3`. See also [#306](https://github.com/rpush/rpush/issues/306) for more details. (by [@amaierhofer](https://github.com/amaierhofer))~~~
- Fix `net-http-persistent` initializer to support version 2.x as well as 3.x. ([#309](https://github.com/rpush/rpush/pull/309) by [@amirmujkic](https://github.com/amirmujkic))
- Fixed Rpush::ApnsFeedback being run on every application type when using Redis. ([#318](https://github.com/rpush/rpush/pull/318) by [@robertasg](https://github.com/robertasg))

## 2.7.0 (February 9, 2016)

#### Features

- Added support for GCM priorities. ([#243](https://github.com/rpush/rpush/pull/243) by [@aried3r](https://github.com/aried3r))
- Added support for GCM notification payload ([#246](https://github.com/rpush/rpush/pull/246) by [@aried3r](https://github.com/aried3r))
- Added support for Windows Raw Notifications (in JSON form) ([#238](https://github.com/rpush/rpush/pull/238) by [@mseppae](https://github.com/mseppae))
- Added WNS badge notifications ([#247](https://github.com/rpush/rpush/pull/247) by [@wouterh](https://github.com/wouterh))
- Added the `launch` argument of WNS toast notifications ([#247](https://github.com/rpush/rpush/pull/247) by [@wouterh](https://github.com/wouterh))
- Added sound in WNS toast notifications ([#247](https://github.com/rpush/rpush/pull/247) by [@wouterh](https://github.com/wouterh))

#### Changes

- Change `alert` type from `string` to `text` in ActiveRecord to allow bigger alert dictionaries. ([#248](https://github.com/rpush/rpush/pull/248) by [@schmidt](https://github.com/schmidt))

#### Fixes

- Fixed issue where setting the `mdm` parameter broke `to_binary` for MDM APNs ([#234](https://github.com/rpush/rpush/pull/234) by [@troya2](https://github.com/troya2))
- Fixed `as_json` ([#231](https://github.com/rpush/rpush/issues/231) by [@aried3r](https://github.com/aried3r))

## 2.6.0 (January 25, 2016)

#### Features

- Added support for GCM for iOS' `content_available`. ([#221](https://github.com/rpush/rpush/pull/221))

#### Fixes

- Fix typo in Oracle support. ([#185](https://github.com/rpush/rpush/pull/185))
- Remove `param` tag from WNS message. ([#190](https://github.com/rpush/rpush/pull/190))
- Fixed WNS response headers parser. ([#192](https://github.com/rpush/rpush/pull/192))
- GCM: fixed raise of unhandled errors. ([#193](https://github.com/rpush/rpush/pull/193))
- Fix issue with custom PID file set in `Rpush.config`. ([#224](https://github.com/rpush/rpush/pull/224), [#225](https://github.com/rpush/rpush/pull/225))

## 2.5.0 (July 19, 2015)

Features:

- Add 'rpush status' to inspect running Rpush internal status.
- ActiveRecord logging is no longer redirected to rpush.log when embedded (#138).
- Support for WNS (Windows RT) (#137).
- Indexes added to some Mongoid fields (#151).
- Added support for Oracle.

Bug fixes:

- Fix for handling APNs error when using `rpush push` or `Rpush.push`.
- Fix backwards compatibility issue with ActiveRecord (#144).

## 2.4.0 (Feb 18, 2015)

Features:

- Support for MongoDB (using Mongoid).
- config.feedback_poll is now deprecated, use config.apns.feedback_receiver.frequency instead.
- Add config.apns.feedback_receiver.enabled to optionally enable the APNs feedback receiver (#129).
- Passing configuration options directly to Rpush.embed and Rpush.push is now deprecated.

Bug fixes:

- Fix setting the log level when using Rails 4+ or without Rails (#124).
- Fix the possibility for excessive error logging when using APNs (#128).
- Re-use timestamp when replacing a migration with the same name (#91).
- Ensure App/Notification type is updated during 2.0 upgrade migration (#102).

## 2.3.2 (Jan 30, 2015)

Bug fixes:

- Internal sleep mechanism would sometimes no wait for the full duration specified.
- Rpush.push nows delivers all pending notifications before returning.
- Require thor >= 0.18.1 (#121).

## 2.3.1 (Jan 24, 2015)

- Fix CPU thrashing while waiting for an APNs connection be established (#119).

## 2.3.0 (Jan 19, 2015)

- Add 'version' CLI command.
- Rpush::Wpns::Notification now supports setting the 'data' attribute.
- ActiveRecord is now directed to the configured Rpush logger (#104).
- Logs are reopened when the HUP signal is received (#95).
- Fix setting config.redis_options (#114).
- Increase frequency of TCP keepalive probes on Linux.
- APNs notifications are no longer marked as failed when a dropped connection is detected, as it's impossible to know exactly how many actually failed (if any).
- Notifications are now retried instead of being marked as failed if a TCP/HTTP connection cannot be established.

## 2.2.0 (Oct 7, 2014)

- Numerous command-line fixes, sorry folks!
- Add 'rpush push' command-line command for one-off use.

## 2.1.0 (Oct 4, 2014)

- Bump APNs max payload size to 2048 for iOS 8.
- Add 'category' for iOS 8.
- Add url_args for Safari Push Notification Support (#77).
- Improved command-line interface.
- Rails integration is now optional.
- Added log_level config option.
- log_dir is now deprecated and has no effect, use log_file instead.

## 2.0.1 (Sept 13, 2014)

- Add ssl_certificate_revoked reflection (#68).
- Fix for Postgis support in 2.0.0 migration (#70).

## 2.0.0 (Sept 6, 2014)

- Use APNs enhanced binary format version 2.
- Support running multiple Rpush processes when using ActiveRecord and Redis.
- APNs error detection is now performed asynchronously, 'check_for_errors' is therefore deprecated.
- Deprecated attributes_for_device accessors. Use data instead.
- Fix signal handling to work with Ruby 2.x. (#40).
- You no longer need to signal HUP after creating a new app, they will be loaded automatically for you.
- APNs notifications are now delivered in batches, greatly improving throughput.
- Signaling HUP now also causes Rpush to immediately check for new notifications.
- The 'wakeup' config option has been removed.
- The 'batch_storage_updates' config option has been deprecated, storage backends will now always batch updates where appropriate.
- The rpush process title updates with number of queued notifications and number of dispatchers.
- Rpush::Apns::Feedback#app has been renamed to app_id and is now an Integer.
- An app is restarted when the HUP signal is received if its certificate or environment attribute changed.

## 1.0.0 (Feb 9, 2014)

- Renamed to Rpush (from Rapns). Version number reset to 1.0.0.
- Reduce default batch size to 100.
- Fix sqlite3 support (#160).
- Drop support for Ruby 1.8.
- Improve APNs certificate validation errors (#192) @mattconnolly).
- Support for Windows Phone notifications (#191) (@matiaslina).
- Support for Amazon device messaging (#173) (@darrylyip).
- Add two new GCM reflections: gcm_delivered_to_recipient, gcm_failed_to_recipient (#184) (@jakeonfire).
- Fix migration issues (#181) (@jcoleman).
- Add GCM gcm_invalid_registration_id reflection (#171) (@marcrohloff).
- Feature: wakeup feeder via UDP socket (#164) (@mattconnolly).
- Fix reflections when using batches (#161).
- Only perform APNs certificate validation for APNs apps (#133).
- The deprecated on_apns_feedback has now been removed.
- The deprecated airbrake_notify config option has been removed.
- Removed the deprecated ability to set attributes_for_device using mass-assignment.
- Fixed issue where database connections may not be released from the connection pool.

## 3.4.1 (Aug 30, 2013)

- Silence unintended airbrake_notify deprecation warning (#158).
- Add :dependent => :destroy to app notifications (#156).

## 3.4.0 (Aug 28, 2013)

- Rails 4 support.
- Add apns_certificate_will_expire reflection.
- Perform storage update in batches where possible, to increase throughput.
- airbrake_notify is now deprecated, use the Reflection API instead.
- Fix calling the notification_delivered reflection twice (#149).

## 3.3.2 (June 30, 2013)

- Fix Rails 3.0.x compatibility (#138) (@yoppi).
- Ensure Rails does not set a default value for text columns (#137).
- Fix error in down action for add_gcm migration (#135) (@alexperto).

## 3.3.1 (June 2, 2013)

- Fix compatibility with postgres_ext (#104).
- Add ability to switch the logger (@maxsz).
- Do not validate presence of alert, badge or sound - not actually required by the APNs (#129) (@wilg).
- Catch IOError from an APNs connection. (@maxsz).
- Allow nested hashes in APNs notification attributes (@perezda).

## 3.3.0 (April 21, 2013)

- GCM: collapse_key is no longer required to set expiry (time_to_live).
- Add reflection for GCM canonical IDs.
- Add Rpush::Daemon.store to decouple storage backend.

## 3.2.0 (Apr 1, 2013)

- Rpush.apns_feedback for one time feedback retrieval. Rpush.push no longer checks for feedback (#117, #105).
- Lazily connect to the APNs only when a notification is to be delivered (#111).
- Ensure all notifications are sent when using Rpush.push (#107).
- Fix issue with running Rpush.push more than once in the same process (#106).

## 3.1.0 (Jan 26, 2013)

- Rpush.reflect API for fine-grained introspection.
- Rpush.embed API for embedding Rpush into an existing process.
- Rpush.push API for using Rpush in scheduled jobs.
- Fix issue with integration with ActiveScaffold (#98) (@jeffarena).
- Fix content-available setter for APNs (#95) (@dup2).
- GCM validation fixes (#96) (@DianthuDia).

## 3.0.1 (Dec 16, 2012)

- Fix compatibility with Rails 3.0.x. Fixes #89.

## 3.0.0 (Dec 15, 2012)

- Add support for Google Cloud Messaging.
- Fix Heroku logging issue.

## 2.0.5 (Nov 4, 2012)

- Support content-available (#68).
- Append to log files.
- Fire a callback when Feedback is received.

## 2.0.5.rc1 (Oct 5, 2012)

- Release db connections back into the pool after use (#72).
- Continue to start daemon if a connection cannot be made during startup (#62) (@mattconnolly).

## 2.0.4 (Aug 6, 2012)

- Don't exit when there aren't any Rpush::App instances, just warn (#55).

## 2.0.3 (July 26, 2012)

- JRuby support.
- Explicitly list all attributes instead of calling column_names (#53).

## 2.0.2 (July 25, 2012)

- Support MultiJson < 1.3.0.
- Make all model attributes accessible.

## 2.0.1 (July 7, 2012)

- Fix delivery when using Ruby 1.8.
- MultiJson support.

## 2.0.0 (June 19, 2012)

- Support for multiple apps.
- Hot Updates - add/remove apps without restart.
- MDM support.
- Removed rpush.yml in favour of command line options.
- Started the changelog!

\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
