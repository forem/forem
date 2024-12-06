## [2.2.0] - 2022-04-14

### Added

- Add Environment and Services support (#123) | [@MikeGoldsmith](https://github.com/MikeGoldsmith)

## [2.1.0] - 2022-02-02

### Improvements

- Retry an event batch send once if the connection appears to have been closed by the server due to idleness (#120) | [MikeGoldsmith](https://github.com/MikeGoldsmith)

### Maintenance

- gh: add re-triage workflow (#117) | [vreynolds](https://github.com/vreynolds)
- Update dependabot to monthly (#116) | [vreynolds](https://github.com/vreynolds)
- empower apply-labels action to apply labels (#115) | [robbkidd](https://github.com/robbkidd)

## [2.0.0] - 2021-10-07

### 💥 Breaking Changes

- support dropped for Ruby 2.2 (#104) | [robbkidd](https://github.com/robbkidd)
- support dropped for Ruby 2.3 (#106) | [robbkidd](https://github.com/robbkidd)
- remove deprecated support for accepting an Array for client proxy_config (#112) | [robbkidd](https://github.com/robbkidd)

### 🛠 Maintenance

- Change maintenance badge to maintained (#109) | [JamieDanielson](https://github.com/JamieDanielson)
- Adds Stalebot (#110) | [JamieDanielson](https://github.com/JamieDanielson)

## [1.21.0] - 2021-09-23

### Added

- Include Ruby runtime info in user agent (#105) | [robbkidd](https://github.com/robbkidd)

### Maintenance

- Update http requirement from >= 2.0, < 5.0 to >= 2.0, < 6.0 (#100)
- Update spy requirement to accept any 1.x release (#102)
- Update rake requirement from ~> 12.3 to ~> 13.0 (#101)
- Add issue and PR templates (#99)
- Add OSS lifecycle badge (#98)
- Add community health files (#97)

## 1.20.0

### Fixes

- Handle Timeout::Error in TransmissionClient (#95) | [Adam Pohorecki](https://github.com/psyho)

## 1.19.0

### Improvements

- add a test_helper, Minitest reporters, & store test results in CI (#88)
- add experimental transmission with new sized-and-timed queue (#87)

### Fixes

- Process single-error responses from the Batch API (#89)

## 1.18.0

### Improvements

- replace HTTP client library to reduce external dependencies (#81)

### Deprecations

- `Libhoney::Client.new(proxy_config: _)`: the `proxy_config` parameter for client
  creation will no longer accept an Array in the next major version. The recommended
  way to configure the client for operation behind forwarding web proxies is to set
  http/https/no_proxy environment variables appropriately.

## 1.17.0

### Fixes:

- Allow Ruby 3.0.0 (removes overly-pessimistic exception) (#79)

## 1.16.1

### Fixes:

- Fix closing down the client when no threads have been started. (#74 & #76)

## 1.16.0

### Fixes:

- Don't moneypatch Class (#70)

### Maintenance:

- Add lockfile to gitignore (#71)

## 1.15.0

### Improvements:

- Do not attempt to send invalid events (#67)

### Maintenance:

- Modernize circle, include github publishing (#64)
- Update .editorconfig to add new lines to end of files (#68)

### Misc

-   Added CHANGELOG.md
-   Updates to CI configuration and documentation
-   Updated version management.
