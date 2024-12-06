## [Unreleased]

## [1.2.1] - 2022-10-25

### Fixed

- [#94](https://github.com/nhosoya/omniauth-apple/pull/94) rack-protection.rb is back in rack-protection v3.0.1
- [#96](https://github.com/nhosoya/omniauth-apple/pull/96) handle JWKS fetch failures

## [1.2.0] - 2022-09-27

### Fixed

- [#91](https://github.com/nhosoya/omniauth-apple/pull/91) explicitly specify auth_scheme for oauth2 v2+ support

## [1.1.0] - 2022-09-26

### Added

- [#67](https://github.com/nhosoya/omniauth-apple/pull/67) Add email_verified and is_private_email

### Fixed

- [#74](https://github.com/nhosoya/omniauth-apple/pull/74) rspec failure - callback_path null pointer
- [#81](https://github.com/nhosoya/omniauth-apple/pull/81) Allow for omniauth 2.0 series
- [#88](https://github.com/nhosoya/omniauth-apple/pull/88) update github actions config

## [1.0.2] - 2021-05-19

### Fixed

- [#59](https://github.com/nhosoya/omniauth-apple/pull/59) Provide User-Agent when fetching JWKs


## [1.0.1] - 2020-12-03

### Security

- Use only verified email address to prevent fake email address

## [1.0.0] - 2020-06-26

### Added

- [#26](https://github.com/nhosoya/omniauth-apple/pull/26) Support ID Token verification
- [#40](https://github.com/nhosoya/omniauth-apple/pull/40) Add rspec test cases
- [#42](https://github.com/nhosoya/omniauth-apple/pull/42) [#43](https://github.com/nhosoya/omniauth-apple/pull/43) Setup CI


### Fixed

- [#31](https://github.com/nhosoya/omniauth-apple/pull/31) Stop relying on ActiveSupport
- [#37](https://github.com/nhosoya/omniauth-apple/pull/37) Fix nonce validation
- [#41](https://github.com/nhosoya/omniauth-apple/pull/41) Fix where the RoR extension is used
- [#46](https://github.com/nhosoya/omniauth-apple/pull/46) Fix naming of Omniauth module to OmniAuth
- [#48](https://github.com/nhosoya/omniauth-apple/pull/48) Remove .rakeTasks


### Changed

- [#27](https://github.com/nhosoya/omniauth-apple/pull/27) Update development dependency
- [#28](https://github.com/nhosoya/omniauth-apple/pull/28) Update README.md
- [#38](https://github.com/nhosoya/omniauth-apple/pull/38) Refine AuthHash
- [#39](https://github.com/nhosoya/omniauth-apple/pull/39) Set the default scope to 'email name'

## [0.0.3] - 2020-05-15

## [0.0.2] - 2020-01-16

## [0.0.1] - 2019-06-07

[Unreleased]: https://github.com/nhosoya/omniauth-apple/compare/v1.2.0...master
[1.2.0]: https://github.com/nhosoya/omniauth-apple/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/nhosoya/omniauth-apple/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/nhosoya/omniauth-apple/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/nhosoya/omniauth-apple/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/nhosoya/omniauth-apple/compare/v0.0.3...v1.0.0
