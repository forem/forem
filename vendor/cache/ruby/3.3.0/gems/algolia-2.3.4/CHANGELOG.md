# ChangeLog

## [Unreleased](https://github.com/algolia/algoliasearch-client-ruby/compare/2.3.2..master)

## [2.3.4](https://github.com/algolia/algoliasearch-client-ruby/compare/2.3.3...2.3.4) (2023-11-27)
### Fixed
- Fixes issue with index name encoding for certain characters.

## [2.3.3](https://github.com/algolia/algoliasearch-client-ruby/compare/2.3.2...2.3.3) (2023-11-14)
### Fixed
- Fixed issue with connection caching for faulty hosts that accept similar requests ([`#496`](https://github.com/algolia/algoliasearch-client-ruby/pull/496))

## [2.3.2](https://github.com/algolia/algoliasearch-client-ruby/compare/2.3.1...2.3.2) (2023-06-07)
### Fixed
- Fixed issue with Request not taking timeouts into account ([`#493`](https://github.com/algolia/algoliasearch-client-ruby/pull/493))

## [2.3.1](https://github.com/algolia/algoliasearch-client-ruby/compare/2.3.0...2.3.1) (2022-09-26)
### Fixed
- Fixed issue when project uses Faraday <1 ([`#485`](https://github.com/algolia/algoliasearch-client-ruby/pull/485))

## [2.3.0](https://github.com/algolia/algoliasearch-client-ruby/compare/2.2.5...2.3.0) (2022-09-26)
### Changed
- Dropped support for Ruby < 2.4 ([`#483`](https://github.com/algolia/algoliasearch-client-ruby/pull/483))
- Updated Faraday dependency range ([`#471`](https://github.com/algolia/algoliasearch-client-ruby/pull/471))
- Fixed bug with `createIfNotExists` ([`#458`](https://github.com/algolia/algoliasearch-client-ruby/pull/458))
- Use user-configured logger to temp client ([`#480`](https://github.com/algolia/algoliasearch-client-ruby/pull/480))

## [2.2.5](https://github.com/algolia/algoliasearch-client-ruby/compare/2.2.4...2.2.5) (2022-05-24)
### Fixed
- multiple_queries: allow params to be `nil` ([`#478`](https://github.com/algolia/algoliasearch-client-ruby/pull/478))

## [2.2.4](https://github.com/algolia/algoliasearch-client-ruby/compare/2.2.3...2.2.4) (2022-05-24)
### Fixed
- API endpoint URL mishandling in get_settings method ([`#473`](https://github.com/algolia/algoliasearch-client-ruby/pull/473))
- Confusing empty debug.log generation in gem users root ([`#474`](https://github.com/algolia/algoliasearch-client-ruby/pull/474))

## [2.2.3](https://github.com/algolia/algoliasearch-client-ruby/compare/2.2.2...2.2.3) (2022-04-21)
### Fixed
- API polling flood issue due to msec sleep time mishandling ([`#472`](https://github.com/algolia/algoliasearch-client-ruby/pull/472))
- mailto link in SECURITY.md ([`#463`](https://github.com/algolia/algoliasearch-client-ruby/pull/463))

### Added
- allow hash in multiple queries ([`#468`](https://github.com/algolia/algoliasearch-client-ruby/pull/468))

## [2.2.2](https://github.com/algolia/algoliasearch-client-ruby/compare/2.2.1...2.2.2) (2021-12-08)
### Fixed
- Added a `status` field to the `MockRequester` ([`#467`](https://github.com/algolia/algoliasearch-client-ruby/pull/467))

## [2.2.1](https://github.com/algolia/algoliasearch-client-ruby/compare/2.2.0...2.2.1) (2021-11-12)
### Chore
- Deprecated `RecommendationClient` in favor of `PersonalizationClient` ([`#461`](https://github.com/algolia/algoliasearch-client-ruby/pull/461))

## [2.2.0](https://github.com/algolia/algoliasearch-client-ruby/compare/2.1.1...2.2.0) (2021-11-08)
### Added
- Added RecommendClient ([`#466`](https://github.com/algolia/algoliasearch-client-ruby/pull/466))
- Added `search` alias for `multiple_queries` ([`#457`](https://github.com/algolia/algoliasearch-client-ruby/pull/457))

## [2.1.1](https://github.com/algolia/algoliasearch-client-ruby/compare/2.1.0...2.1.1) (2021-05-27)

### Fix
- Bug with read/write nodes caching ([`#455`](https://github.com/algolia/algoliasearch-client-ruby/pull/455))

## [2.1.0](https://github.com/algolia/algoliasearch-client-ruby/compare/2.0.4...2.1.0) (2021-03-30)

### Feat
- Custom dictionaries methods

### Fix
- The parameter `forwardToReplicas` should be handled independently in the `set_settings` method

## [2.0.4](https://github.com/algolia/algoliasearch-client-ruby/compare/2.0.3...2.0.4) (2021-01-05)

### Fix
- `app_api_key`: send opts with waitable method

## [2.0.3](https://github.com/algolia/algoliasearch-client-ruby/compare/2.0.2...2.0.3) (2020-11-24)

### Chore
- Containerize the repo

## [2.0.2](https://github.com/algolia/algoliasearch-client-ruby/compare/2.0.1...2.0.2) (2020-11-09)

### Fix
- Don't mutate index name on stripping

## [2.0.1](https://github.com/algolia/algoliasearch-client-ruby/compare/2.0.0...2.0.1) (2020-11-02)

### Fix
- Simplify merge of headers in `Transport` class
- `deserialize_settings` function to take into account `symbolize_keys` parameter

## [2.0.0](https://github.com/algolia/algoliasearch-client-ruby/releases/tag/2.0.0) (2020-10-27)

* Initial release of v2
