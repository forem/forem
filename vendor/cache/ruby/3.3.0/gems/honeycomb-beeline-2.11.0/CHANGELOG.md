# beeline-ruby changelog

## 2.11.0 2022-06-01

### Improvements

- Let Rake spans be disabled programmatically (#200) | [ajvondrak](https://github.com/ajvondrak)

## 2.10.0 2022-04-08

### Improvements

- Add HTTP referer to rack integration (#197) | [@bgitt](https://github.com/bgitt)

### Fixed

- Fix regression with mid vs leaf meta.span_type detection (#194) | [@ajvondrak](https://github.com/ajvondrak)

## 2.9.0 2022-03-23

### Enhancements

- Add Environment and Services support (#196) | [@MikeGoldsmith](https://github.com/MikeGoldsmith)

## 2.8.2 2022-02-02

### Maintenance

- Remove the upperbound on libhoney version (#191) | [@MikeGoldsmith](https://github.com/MikeGoldsmith)

## 2.8.1 2022-01-12

### Fixed

- fix Beeline user-agent addition when creating a Libhoney client (#189) | [@robbkidd](https://github.com/robbkidd)

### Maintenance

- gh: add re-triage workflow (#185) | [@vreynolds](https://github.com/vreynolds)
- set minimum version of rspec_junit_formatter (#188) | [@robbkidd](https://github.com/robbkidd)

## 2.8.0 2021-12-22

### Improvements

- feat: accept both w3c and honeycomb propagation headers by default (#183) | [@robbkidd](https://github.com/robbkidd)

### Maintenance

- Update dependabot to monthly (#181) | [@vreynolds](https://github.com/vreynolds)
- empower apply-labels action to apply labels (#179) | [@robbkidd](https://github.com/robbkidd)

## 2.7.1 2021-10-22

### Maintenance

- Change maintenance badge to maintained (#174) | [@JamieDanielson](https://github.com/JamieDanielson)
- Adds Stalebot (#175) | [@JamieDanielson](https://github.com/JamieDanielson)
- gather up the matrix'd code coverage and save a report (#173) | [@robbkidd](https://github.com/robbkidd)
- add Ruby 3.0 to CI matrix (#171) | [@robbkidd](https://github.com/robbkidd)
- remove CodeCov from test suite (#172) | [@robbkidd](https://github.com/robbkidd)
- Add NOTICE (#169) | [@cartermp](https://github.com/cartermp)

## 2.7.0 2021-09-03

### Improvements

- add `error` and `error_detail` fields to spans from `ActiveSupport::Notification` events that contain an exception (#166) | [@leviwilson](https://github.com/leviwilson)

### Maintenance

- Add issue and PR templates (#165) | [@vreynolds](https://github.com/vreynolds)
- Add OSS lifecycle badge (#164) | [@vreynolds](https://github.com/vreynolds)
- Add community health files (#163) | [@vreynolds](https://github.com/vreynolds)

## 2.6.0 2021-07-23

### Added

- Allow setting different notification handling logic for specific events (#152) | [@lirossarvet](https://github.com/lirossarvet)

## 2.5.0 2021-07-16

### Added

- Allow backtrace to be sent with errors (#160) | [@lirossarvet](https://github.com/lirossarvet)

### Maintenance

- Updates Github Action Workflows (#159) | [@bdarfler](https://github.com/bdarfler)
- Adds dependabot label (#158) | [@bdarfler](https://github.com/bdarfler)
- Switches CODEOWNERS to telemetry-team (#157) | [@bdarfler](https://github.com/bdarfler)

## 2.4.2 2021-06-25

### Fixes

- Update Rails middleware to get status code even on raised error. (#153) [@lirossarvet](https://github.com/lirossarvet)
- Make Rails spec consistent with Honeycomb Railtie Initialization. (#154) [@robbkidd](https://github.com/robbkidd)
- CI Improvements (#155) [@robbkidd](https://github.com/robbkidd)
- Improve performance of Redis command serialization. (#146) [@ajvondrak](https://github.com/ajvondrak)

## 2.4.1 2021-06-01

### Fixes

- Updates Redis event-field filter to handle string keys in options in
  addition to symbol keys. (#147) [@cupakromer](https://github.com/cupakromer)

### Maintenance

- Expanded on the Rails 5.2 example. (#141) [@robbkidd](https://github.com/robbkidd)
- Added a test case for current behavior of event emitted for an
  exception raised in Rails. (@132) [@vreynolds](https://github.com/vreynolds)

## 2.4.0 2021-01-07
### Added
- Add support for HTTP Accept-Encoding header (#125) [@irvingreid](https://github.com/irvingreid)
- Add with_field, with_trace_field wrapper methods (#51) [@ajvondrak](https://github.com/ajvondrak)

## 2.3.0 2020-11-06
### Improvements
- Custom trace header hooks (#117)
- Add rspec filter :focus for assisting with debugging tests (#120)
- Be more lenient in expected output from AWS gem (#119)

## 2.2.0 2020-09-02
### New things
- refactor parsers/propagators, add w3c and aws parsers and propagators (#104) [@katiebayes](https://github.com/katiebayes)

### Tiny fix
- Adjusted a threshold that should resolve the occasional build failures (#107) [@katiebayes](https://github.com/katiebayes)

## 2.1.2 2020-08-26
### Improvements
- reference current span in start_span (#105) [@rintaun](https://github.com/rintaun)
- switch trace and span ids over to w3c-supported formats (#100) [@katiebayes](https://github.com/katiebayes)

## 2.1.1 2020-07-28
### Fixes
- Remove children after sending | #98 | [@martin308](https://github.com/martin308)

## 2.1.0 2020-06-10
### Features
- Adding X-Forwarded-For to instrumented fields | #91 | [@paulosman](https://github.com/paulosman)
- Add request.header.accept_language field | #94 | [@timcraft](https://github.com/timcraft)
- Support custom notifications based on a regular expression | #92 | [@mrchucho](https://github.com/mrchucho)

### Fixes
- Properly pass options for Ruby 2.7 | #85 | [@terracatta](https://github.com/terracatta)
- Fix regex substitution for warden and empty? errors for Rack | #88 | [@irvingreid](https://github.com/irvingreid)

## 2.0.0 2020-03-10
See [release notes](https://github.com/honeycombio/beeline-ruby/releases/tag/v2.0.0)

## 1.3.0 2019-11-20
### Features
- redis integration | #42 | [@ajvondrak](https://github.com/ajvondrak)

## 1.2.0 2019-11-04
### Features
- aws-sdk v2 & v3 integration | #40 | [@ajvondrak](https://github.com/ajvondrak)

## 1.1.1 2019-10-10
### Fixes
- Skip params when unavailable | #39 | [@martin308](https://github.com/martin308)

## 1.1.0 2019-10-07
### Features
- Split rails and railtie integrations | #35 | [@martin308](https://github.com/martin308)

## 1.0.1 2019-09-03
### Fixes
- Set sample_hook and presend_hook on child spans | #26 | [@orangejulius](https://github.com/orangejulius)
- No-op if no client found in Faraday integration | #27 | [@Sergio-Mira](https://github.com/Sergio-Mira)

## 1.0.0 2019-07-23
Version 1 is a milestone release. A complete re-write and modernization of Honeycomb's Ruby support.
See UPGRADING.md for migrating from v0.8.0 and see https://docs.honeycomb.io for full documentation.

## 0.8.0 2019-05-06
### Enhancements
- Expose event to #span block | #17 | [@eternal44](https://github.com/eternal44)

## 0.7.0 2019-03-13
### Enhancements
- Remove default inclusion of Sequel instrumentation | #12 | [@martin308](https://github.com/martin308)

## 0.6.0 2018-11-29
### Enhancements
- Tracing API and cross-process tracing | #4 | [@samstokes](https://github.com/samstokes)

## 0.5.0 2018-11-29
### Enhancements
- Improved rails support | #3 | [@samstokes](https://github.com/samstokes)
