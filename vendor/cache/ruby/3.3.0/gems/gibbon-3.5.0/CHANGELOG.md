## [3.5.0, unreleased] - 2022-06-05
- Remove support for retired Export API

## [3.4.4] - 2022-02-24
- Remove non-alpha characters when parsing datacenter from API keys to prevent potential attackers from injecting a domain via the API key. This would only be possible if one were using user-provided API keys (e.g. from a form, etc.).

## [3.4.3] - 2022-01-19
- Support for Faraday 2.0, which requires new syntax for basic auth

## [3.4.2] - 2021-09-21
- Fixing the deprecation warning in version 3.4.2 requires moving to a minimum version of Faraday 1.0.0 (more than 2 years old).

## [3.4.1] - 2021-09-12
- Fix deprecation warning for upcoming versions of Faraday (2.x.x)

## [3.4.0] - 2021-03-12
- Support for Faraday 1.x.x and higer

## [3.3.4] - 2020-04-01
- Added support for setting API key via environment variable for Export API
- Updated webmock

## [3.3.3] - 2020-02-07
- Removes bit of extra conditional logic that was part of supporting older versions of Faraday

## [3.3.2] - 2020-01-19
- Bumped minimum version of Faraday 0.16.0 due to compatibility issues with legacy versions

## [3.3.1] - 2019-11-08
- Fix statically setting `faraday_adapter` did not set adapter on new requests

## [3.3.0] - 2019-10-02
- Fixed compatibility with Faraday 0.16.2+
- Set minimum Ruby to 2.3.8

## [3.2.1] - 2017-11-08
- Set minimum Ruby to 2.1

## [3.2.0] - 2017-11-08
- Force TLS version 1.2

## [3.1.1] - 2017-09-25
- Fix MailChimpError initialization

## [3.1.0] - 2017-07-27
- Add back support for Export API until MailChimp stops supporting it
- Implement `responds_to_missing`

## [3.0.2] - 2017-05-08
- Fix subtle bug in `symbolize_keys` when parsing error

## [3.0.1] - 2017-01-13
- Gibbon::Request (API 3.0) now returns a `Gibbon::Response` object that exposes `headers` and the parsed response `body`
- Remove Export API support (this is deprected after all)
- Adds `symbolize_keys`, `debug`, and `faraday_adapter` as class vars
- Bump version to 3.0.1 (not sticking to semver here so folks who downloaded 3.0.0 have a way to easily move forward)

## [3.0.0] - 2017-01-13
- Gibbon::Request (API 3.0) now returns a `Gibbon::Response` object that exposes `headers` and the parsed response `body`
- Adds Export API support
- Adds `symbolize_keys`, `debug`, and `faraday_adapter` as class vars
- Bump version to 3.0.0 due to breaking API change

## [2.2.5] - 2016-12-23
- Adds open_timeout
- Adds `symbolize_keys`
- Change default timeout from 30 to 60 seconds

## [2.2.4] - 2016-05-21
- Add debug logging

## [2.2.3] - 2016-03-16
- Capture status code and raw body when response is not json.

## [2.2.2] - 2016-03-15
- Update dependencies

## [2.2.1] - 2016-01-01
- Improve MailChimpError logging

## [2.2.0] - 2015-12-01
- Adds support for proxies
- Adds support for faraday_adapters

## [2.1.3] - 2015-11-26
- Fixes issue #159, which prevented sending campaigns from working. Thanks to @q3-tech for the bug report.

## [2.1.2] - 2015-11-11
- Allow Faraday default\_connection\_options to be set

## [2.1.1] - 2015-11-05
- Fix surfacing unparseable Faraday request exception.

## [2.1.0] - 2015-10-12
- Upsert support

## [2.0.0] - 2015-7-28
- Support for API 3.0. Usage syntax has changed. Please check out the readme.
- Update MultiJSON dependency to 1.11.0
- Switch to Faraday
- Fix: Handle empty response payloads on delete

## [1.2.0] - 2015-07-16
- Same as 1.1.6 but rereleased because it's a breaking change
- Support for Ruby 2 streaming with Export API. Now returns an Array of Array of Strings instead of an Array of Strings.
- Fix a bug that caused calling methods statically on Gibbon::Export to fail

## [1.1.6] - 2015-06-04 (Yanked)
- Support for Ruby 2 streaming with Export API

## [1.1.5] - 2015-02-19
- Update MultiJSON dependency to 1.9.0
- Handle single empty space in Export API response

## [1.1.4] - 2012-11-04
- Fix JSON::ParserError on export calls that return blank results

[unreleased]: https://github.com/amro/gibbon/compare/v3.1.0...HEAD
[3.1.0]: https://github.com/amro/gibbon/compare/v3.0.2...v3.1.0
[3.0.2]: https://github.com/amro/gibbon/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/amro/gibbon/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/amro/gibbon/compare/v2.2.5...v3.0.0
[2.2.5]: https://github.com/amro/gibbon/compare/v2.2.4...v2.2.5
[2.2.4]: https://github.com/amro/gibbon/compare/v2.2.2...v2.2.4
[2.2.3]: https://github.com/amro/gibbon/compare/v2.2.2...v2.2.3
[2.2.2]: https://github.com/amro/gibbon/compare/v2.2.1...v2.2.2
[2.2.1]: https://github.com/amro/gibbon/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/amro/gibbon/compare/v2.1.3...v2.2.0
[2.1.3]: https://github.com/amro/gibbon/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/amro/gibbon/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/amro/gibbon/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/amro/gibbon/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/amro/gibbon/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/amro/gibbon/compare/v1.1.5...v1.2.0
[1.1.6]: https://github.com/amro/gibbon/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/amro/gibbon/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/amro/gibbon/compare/v1.1.3...v1.1.4
