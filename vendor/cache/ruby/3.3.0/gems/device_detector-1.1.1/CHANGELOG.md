# Change Log

## [1.1.1]
- Updated detection rules from upstream on 2023-07-01
- Fix issue when user agent is nil ([#104](https://github.com/podigee/device_detector/issues/104))
- Fix issue when user agent is not UTF-8 encoded ([#105](https://github.com/podigee/device_detector/issues/105), [#106](https://github.com/podigee/device_detector/issues/106))
- Improve device brand name detection

## [1.1.0]
- Updated detection rules from upstream on 2022-12-09
- Add support for client hints in header
- Changed the minimum required Ruby version (>= 2.7.5)

## [1.0.7]
- Updated detection rules from upstream on 2022-02-17
- Fixes Ruby warnings when compiling RegExes ([#89](https://github.com/podigee/device_detector/issues/89), [#91](https://github.com/podigee/device_detector/issues/91))

## [1.0.6]
- Updated detection rules from upstream on 2021-10-28

## [1.0.5]
- Updated detection rules from upstream on 2020-10-06

## [1.0.4]
- Updated detection rules from upstream on 2020-06-23
- [Issue #69](https://github.com/podigee/device_detector/issues/69): Performance: RegExp definitions are only loaded once.
- [Issue #74](https://github.com/podigee/device_detector/issues/74): Development: Added Rubocop

## [1.0.3]
- Updated detection rules from upstream on 2019-12-09

## [1.0.2]
- Updated detection rules from upstream on 2019-08-05

## [1.0.1]
- Updated detection rules from upstream on 2018-04-27

## [1.0.0]
- Boom! The 1.0.0 has landed :)

## [0.9.0]
- Preparing for the 1.0.0 release. This version (with minor bumps) will be promoted to 1.0.0 once the release has been proven stable
- Updated regex files from upstream
- Updated test fixtures from upstream

## [0.8.2]
- Added device brand support. Thanks to [dnswus](https://github.com/dnswus)

## [0.8.1]
- Added Instacast detection rules
- Updated test fixtures

## [0.8.0]
- Added a better and more robust device detection. Thanks to [skaes](https://github.com/skaes)
- Added test fixture from the piwik project

## [0.7.0]
- [Issue #8](https://github.com/podigee/device_detector/issues/8) Fixed Mac OS X full version format. Thanks to [aaronchi](https://github.com/aaronchi) for reporting

## [0.6.0]

- [Issue #7](https://github.com/podigee/device_detector/issues/7) Fixed missing name extraction from regexp. Thanks to [janxious](https://github.com/janxious) for reporting
- Optimized performance of name and version extraction, by using the built-in memory cache
- Move specs from RSpec to the more lightweight Minitest

## [0.5.1]

- Added the minimum required Ruby version (>= 1.9.3)

## [0.5.0]

- Added rake task for automatic generation of supported and detectable clients and devices
- Updated detection rules
- Fixed device type detection, when type is specified on top level of a nested regex
