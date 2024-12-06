# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/).


## [Unreleased]

### Added

- Nothing

### Changed

- Nothing

### Fixed

- Nothing


## [3.9.2] - 2022-03-31

### Fixed

- [JS] Fix pluralization fallback in i18n.js  
  (PR: https://github.com/fnando/i18n-js/pull/645)


## [3.9.1] - 2022-02-08

### Changed

- [Ruby] Allow rails 7
  (PR: https://github.com/fnando/i18n-js/pull/638)


## [3.9.0] - 2021-07-30

### Added

- [Ruby] Allow to set custom locales instead of using only `I18n.available_locales`.
  (PR: https://github.com/fnando/i18n-js/pull/617)


## [3.8.4] - 2021-07-27

### Fixed

- [Ruby] Fix proc exported to JS/JSON file(s) causing issues like git merge conflicts  
  (PR: https://github.com/fnando/i18n-js/pull/591)


## [3.8.3] - 2021-05-21

### Changed

- [Ruby] Generate translations in JS as `JSON.parse` instead of object literal for performance  
  (PR: https://github.com/fnando/i18n-js/pull/605)  
  (PR: https://github.com/fnando/i18n-js/pull/606)  
  (PR: https://github.com/fnando/i18n-js/pull/607)  


## [3.8.2] - 2021-03-18

### Fixed

- [Ruby] Stop using deprecated method  
  (PR: https://github.com/fnando/i18n-js/pull/598)
- [Ruby] Fix typo in error class reference  
  (Commit: https://github.com/fnando/i18n-js/commit/cc075ad0a36e940205d0a14390379d69013d188e)


## [3.8.1] - 2021-02-25

### Fixed

- [Ruby] Fix performance issue reading config  
  (PR: https://github.com/fnando/i18n-js/pull/593)


## [3.8.0] - 2020-10-15

### Added

- [JS] Add option `scope` for `toHumanSize()`  
  (PR: https://github.com/fnando/i18n-js/pull/583)


## [3.7.1] - 2020-06-30

### Fixed

- [JS] For translation missing behaviour `guess`, replace all underscores to spaces properly  
  (PR: https://github.com/fnando/i18n-js/pull/574)


## [3.7.0] - 2020-05-29

### Added

- [JS] Allow options to be passed in when calling `I18n.localize`/`I18n.l`  
  (PR: https://github.com/fnando/i18n-js/pull/570)


## [3.6.0] - 2020-02-14

### Added

- [Ruby] Allow `suffix` to be added to generated translations files  
  (PR: https://github.com/fnando/i18n-js/pull/561)


## [3.5.1] - 2019-12-21

### Changed

- [JS] Bound shortcut functions  
  (PR: https://github.com/fnando/i18n-js/pull/560)


## [3.5.0] - 2019-11-12

### Added

- [JS] Support for `%k` strftime format to match Ruby strftime  
  (PR: https://github.com/fnando/i18n-js/pull/554)


## [3.4.2] - 2019-11-11

### Fixed

- [Ruby] Fix regression introduced in PR #551  
  (PR: https://github.com/fnando/i18n-js/pull/555)


## [3.4.1] - 2019-11-01

### Fixed

- [Ruby] Fix merging of plural keys to work with fallbacks that aren't overridden  
  (PR: https://github.com/fnando/i18n-js/pull/551)


## [3.4.0] - 2019-10-15

### Added

- [Ruby] Allow `prefix` to be added to generated translations files  
  (PR: https://github.com/fnando/i18n-js/pull/549)


## [3.3.0] - 2019-06-06

### Added

- [JS] Support for `%P`, `%Z`, and `%l` strftime formats to match Ruby strftime  
  (PR: https://github.com/fnando/i18n-js/pull/537)


## [3.2.3] - 2019-05-24

### Changed

- [Ruby] Allow rails 6 to be used with this gem  
  (PR: https://github.com/fnando/i18n-js/pull/536)


## [3.2.2] - 2019-05-09

### Fixed

- [JS] Return invalid date/time input values (null & undefined) as-is
  (Commit: https://github.com/fnando/i18n-js/commit/869d1689ed788ff50121de492db354652971c23d)


## [3.2.1] - 2019-01-22

### Changed

- [Ruby] `json_only` option should allow multiple locales.  
  (PR: https://github.com/fnando/i18n-js/pull/531)
- [Ruby] Simplified and cleaned code related to JS/JSON formatting.  
  (PR: https://github.com/fnando/i18n-js/pull/531)
- [JS] Use strict value comparison

### Fixed

- [Ruby] Relax `i18n` version requirement back to  `>= 0.6.6`  
  (PR: https://github.com/fnando/i18n-js/pull/530)
- [Ruby] Fix merging of plural keys across locales.  
  (PR: https://github.com/fnando/i18n-js/pull/472)


## [3.2.0] - 2018-11-16

### Added

- [Ruby] Add option `json_only` to generate translations in JSON  
  (PR: https://github.com/fnando/i18n-js/pull/524)

### Changed

- [Ruby] Requires `i18n` to be `>= 0.8.0` for CVE-2014-10077


## [3.1.0] - 2018-11-01

### Added

- [Ruby] Add option to allow setting a different I18n backend  
  (PR: https://github.com/fnando/i18n-js/pull/519)

### Fixed

- [JS] Fix missing translation when pluralizing with default scopes  
  (PR: https://github.com/fnando/i18n-js/pull/516)


## [3.0.11] - 2018-07-06

### Fixed

- [JS] Fix interpolation for array with non string/null elements  
  (PR: https://github.com/fnando/i18n-js/pull/505)


## [3.0.10] - 2018-06-21

### Fixed

- [JS] Fix extend method changing keys with `null` to empty objects  
  (PR: https://github.com/fnando/i18n-js/pull/503)
- [JS] Fix variable name in an internal method  
  (PR: https://github.com/fnando/i18n-js/pull/501)


## [3.0.9] - 2018-06-21

### Fixed

- [JS] Fix translation array interpolation for array with null


## [3.0.8] - 2018-06-06

### Changed

- [JS] Interpolate translation array too  
  (PR: https://github.com/fnando/i18n-js/pull/498)


## [3.0.7] - 2018-05-30

### Fixed

- [Ruby] Fix new bug occuring when config file is absent


## [3.0.6] - 2018-05-30

### Fixed

- [Ruby] Make JS `i18n/filtered` depends on i18n-js config too  
  (PR: https://github.com/fnando/i18n-js/pull/497)


## [3.0.5] - 2018-02-26

### Changed

- [Ruby] Support `I18n` `1.0.x`  
  (PR: https://github.com/fnando/i18n-js/pull/492)


## [3.0.4] - 2018-01-26

### Fixed

- [Ruby] Fix `JS::Dependencies.using_asset_pipeline?` returning true when sprockets installed but disabled  
  (PR: https://github.com/fnando/i18n-js/pull/488)


## [3.0.3] - 2018-01-02

### Fixed

- [Ruby] Fix extend method when translations has array values  
  (PR: https://github.com/fnando/i18n-js/pull/487)


## [3.0.2] - 2017-10-26

### Changed

- [Ruby] Avoid writing new file if a file with same content already exists  
  (PR: https://github.com/fnando/i18n-js/pull/473)
- [JS] Fix fallback when "3-part" locale like `zh-Hant-TW` is used  
  It was falling back to `zh` first instead of `zh-Hant` (see new test case added)  
  (PR: https://github.com/fnando/i18n-js/pull/475)


## [3.0.1] - 2017-08-02

### Changed

- [Ruby] Relax Rails detection code to work with alternative installation methods  
  (PR: https://github.com/fnando/i18n-js/pull/467)
- [JS] Fix fallback when "3-part" locale like `zh-Hant-TW` is used  
  It fallbacks to `zh` only before, now it fallbacks to `zh-Hant`  
  (PR: https://github.com/fnando/i18n-js/pull/465)


## [3.0.0] - 2017-04-01

This is a fake official release, the *real* one will be `3.0.0.rc17`  
And today is not April Fools' Day  

### Fixed

- Ends the longest Release Candidate period among all ruby gems  
  (v3.0.0.rc1 released at 2012-05-10)  


## [3.0.0.rc16] - 2017-03-13

### Changed

- [Ruby] Drop support for Ruby < `2.1.0`

### Fixed

- [JS] Make defaultValue works on plural translation
- [JS] Fix UMD pattern so the global/root won’t be undefined


## [3.0.0.rc15] - 2016-12-07

### Added

- Nothing

### Changed

- [JS] Allow `defaultValue` to work in pluralization  
  (PR: https://github.com/fnando/i18n-js/pull/433)  
- [Ruby] Stop validating the fallback locales against `I18n.available_locales`  
  This allows some locales to be used as fallback locales, but not to be generated in JS.  
  (PR: https://github.com/fnando/i18n-js/pull/425)  
- [Ruby] Remove dependency on gem `activesupport`  

### Fixed

- [JS] Stop converting numeric & boolean values into objects  
  when merging objects with `I18n.extend`  
  (PR: https://github.com/fnando/i18n-js/pull/420)  
- [JS] Fix I18n pluralization fallback when tree is empty  
  (PR: https://github.com/fnando/i18n-js/pull/435)  
- [Ruby] Use old syntax to define lambda for compatibility with older Rubies  
  (Issue: https://github.com/fnando/i18n-js/issues/419)  
- [Ruby] Fix error raised in middleware cache cleaning in parallel test   
  (Issue: https://github.com/fnando/i18n-js/issues/436)  


## [3.0.0.rc14] - 2016-08-29

### Changed

- [JS] Method `I18n.extend()` behave as deep merging instead of shallow merging. (https://github.com/fnando/i18n-js/pull/416)
- [Ruby] Use object/class instead of block when registering Sprockets preprocessor (https://github.com/fnando/i18n-js/pull/418)  
  To ensure that your cache will expire properly based on locale file content after upgrading,  
  you should run `rake assets:clobber` and/or other rake tasks that clear the asset cache once gem updated
- [Ruby] Detect & support rails 5 (https://github.com/fnando/i18n-js/pull/413)


## [3.0.0.rc13] - 2016-06-29

### Added

- [Ruby] Added option `js_extend` to not generate JS code for translations with usage of `I18n.extend` ([#397](https://github.com/fnando/i18n-js/pull/397))

### Changed

- Nothing

### Fixed

- [JS] Initialize option `missingBehaviour` & `missingTranslationPrefix` with default values ([#398](https://github.com/fnando/i18n-js/pull/398))
- [JS] Throw an error when `I18n.strftime()` takes an invalid date ([#383](https://github.com/fnando/i18n-js/pull/383))
- [JS] Fix default error message when translation missing to consider locale passed in options
- [Ruby] Reset middleware cache on rails startup
([#402](https://github.com/fnando/i18n-js/pull/402))


## [3.0.0.rc12] - 2015-12-30

### Added

- [JS] Allow extending of translation files ([#354](https://github.com/fnando/i18n-js/pull/354))
- [JS] Allow missingPlaceholder to receive extra data for debugging ([#380](https://github.com/fnando/i18n-js/pull/380))

### Changed

- Nothing

### Fixed

- [Ruby] Fix of missing initializer at sprockets. ([#371](https://github.com/fnando/i18n-js/pull/371))
- [Ruby] Use proper method to register preprocessor documented by sprockets-rails. ([#376](https://github.com/fnando/i18n-js/pull/376))
- [JS] Correctly round unprecise floating point numbers.
- [JS] Ensure objects are recognized when passed in from an iframe. ([#375](https://github.com/fnando/i18n-js/pull/375))


## 3.0.0.rc11

### breaking changes

### enhancements

### bug fixes

- [Ruby] Handle fallback locale without any translation properly ([#338](https://github.com/fnando/i18n-js/pull/338))
- [Ruby] Prevent translation entry with null value to override value in fallback locale(s), if enabled ([#334](https://github.com/fnando/i18n-js/pull/334))


## 3.0.0.rc10

### breaking changes

- [Ruby] In `config/i18n-js.yml`, if you are using `%{locale}` in your filename and are referencing specific translations keys, please add `*.` to the beginning of those keys. ([#320](https://github.com/fnando/i18n-js/pull/320))
- [Ruby] The `:except` option to exclude certain phrases now (only) accepts the same patterns the `:only` option accepts

### enhancements

- [Ruby] Make handling of per-locale and not-per-locale exporting to be more consistent ([#320](https://github.com/fnando/i18n-js/pull/320))
- [Ruby] Add option `sort_translation_keys` to sort translation keys alphabetically ([#318](https://github.com/fnando/i18n-js/pull/318))

### bug fixes

- [Ruby] Fix fallback logic to work with not-per-locale files ([#320](https://github.com/fnando/i18n-js/pull/320))


## 3.0.0.rc9

### enhancements

- [JS] Force currency number sign to be at first place using `sign_first` option, default to `true`
- [Ruby] Add option `namespace` & `pretty_print` ([#300](https://github.com/fnando/i18n-js/pull/300))
- [Ruby] Add option `export_i18n_js` ([#301](https://github.com/fnando/i18n-js/pull/301))
- [Ruby] Now the gem also detects pre-release versions of `rails`
- [Ruby] Add `:except` option to exclude certain phrases or groups of phrases from the
  outputted translations ([#312](https://github.com/fnando/i18n-js/pull/312))
- [JS] You can now set `I18n.missingBehavior='guess'` to have the scope string output as text instead of of the
  "[missing `scope`]" message when no translation is available.
  Combined that with `I18n.missingTranslationPrefix='SOMETHING'` and you can
  still identify those missing strings.
  ([#304](https://github.com/fnando/i18n-js/pull/304))

### bug fixes

- [JS] Fix missing translation message when scope is passed in options
- [Ruby] Fix save cache directory verification when path is a symbolic link ([#329](https://github.com/fnando/i18n-js/pull/329))


## 3.0.0.rc8

### enhancements

- Add support for loading via AMD and CommonJS module loaders ([#266](https://github.com/fnando/i18n-js/pull/266))
- Add `I18n.nullPlaceholder`
  Defaults to I18n.missingPlaceholder (`[missing {{name}} value]`)
  Set to `function() {return "";}` to match Ruby `I18n.t("name: %{name}", name: nil)`
- For date formatting, you can now also add placeholders to the date format, see README for detail
- Add fallbacks option to `i18n-js.yml`, defaults to `true`

### bug fixes

- Fix factory initialization so that the Node/CommonJS branch only gets executed if the environment is Node/CommonJS
  (it currently will execute if module is defined in the global scope, which occurs with QUnit, for example)
- Fix pluralization rules selection for negative `count` (e.g. `-1` was lead to use `one` for pluralization) ([#268](https://github.com/fnando/i18n-js/pull/268))
- Remove check for `Rails.configuration.assets.compile` before telling Sprockets the dependency of translations JS file
  This might be the reason of many "cache not expired" issues
  Discovered/reported in #277

## 3.0.0.rc7

### enhancements

- The Rails Engine initializer is now named as `i18n-js.register_preprocessor` (https://github.com/fnando/i18n-js/pull/261)
- Rename `I18n::JS.config_file` to `I18n::JS.config_file_path` and make it configurable
  Expected a `String`, default is still `config/i18n-js.yml`
- When running `rake i18n:js:export`, the `i18n.js` will also be exported to `I18n::JS.export_i18n_js_dir_path` by default
- Add `I18n::JS.export_i18n_js_dir_path`
  Expected a `String`, default is `public/javascripts`
  Set to `nil` will disable exporting `i18n.js`

### bug fixes

- Prevent toString() call on `undefined` when there is a missing interpolation value
- Added support for Rails instances without Sprockets object (https://github.com/fnando/i18n-js/pull/241)
- Fix `DEFAULT_OPTIONS` in `i18n.js` which contained an excessive comma
- Fix `nil` values are exported into JS files which causes strange translation error
- Fix pattern to replace all escaped $ in I18n.translate
- Fix JS `I18n.lookup` modifies existing locales accidentally

## 3.0.0.rc6

### enhancements

- You can now assign `I18n.locale` & `I18n.default_locale` before loading `i18n.js` in `application.html.*`
  (merged to `i18n-js-pika` already)
- You can include ERB in `config/i18n-js.yml`(https://github.com/fnando/i18n-js/pull/224)
- Add support for +00:00 style time zone designator (https://github.com/fnando/i18n-js/pull/167)
- Add back rake task for export (`rake i18n:js:export`)
- Not overriding translation when manually run `I18n::JS.export` (https://github.com/fnando/i18n-js/pull/171)
- Move missing placeholder text generation into its own function (for easier debugging) (https://github.com/fnando/i18n-js/pull/169)
- Add support for milliseconds (`lll` in `yyyy-mm-ddThh:mm:ss.lllZ`) (https://github.com/fnando/i18n-js/pull/192)
- Add back i18n-js.yml config file generator : `rails generate i18n:js:config` (https://github.com/fnando/i18n-js/pull/225)

### bug fixes

- `I18n::JS.export` no longer exports locales other than those in `I18n.available_locales`, if `I18n.available_locales` is set
- I18.t supports the base scope through the options argument
- I18.t accepts an array as the scope
- Fix regression: asset not being reloaded in development when translation changed
- Requires `i18n` to be `~> 0.6`, `0.5` does not work at all
- Fix using multi-star scope with top-level translation key (https://github.com/fnando/i18n-js/pull/221)


## Before 3.0.0.rc5

- Things happened.



[Unreleased]: https://github.com/fnando/i18n-js/compare/v3.9.2...HEAD
[3.9.2]:      https://github.com/fnando/i18n-js/compare/v3.9.1...v3.9.2
[3.9.1]:      https://github.com/fnando/i18n-js/compare/v3.9.0...v3.9.1
[3.9.0]:      https://github.com/fnando/i18n-js/compare/v3.8.4...v3.9.0
[3.8.4]:      https://github.com/fnando/i18n-js/compare/v3.8.3...v3.8.4
[3.8.3]:      https://github.com/fnando/i18n-js/compare/v3.8.2...v3.8.3
[3.8.2]:      https://github.com/fnando/i18n-js/compare/v3.8.1...v3.8.2
[3.8.1]:      https://github.com/fnando/i18n-js/compare/v3.8.0...v3.8.1
[3.8.0]:      https://github.com/fnando/i18n-js/compare/v3.7.1...v3.8.0
[3.7.1]:      https://github.com/fnando/i18n-js/compare/v3.7.0...v3.7.1
[3.7.0]:      https://github.com/fnando/i18n-js/compare/v3.6.0...v3.7.0
[3.6.0]:      https://github.com/fnando/i18n-js/compare/v3.5.1...v3.6.0
[3.5.1]:      https://github.com/fnando/i18n-js/compare/v3.5.0...v3.5.1
[3.5.0]:      https://github.com/fnando/i18n-js/compare/v3.4.2...v3.5.0
[3.4.2]:      https://github.com/fnando/i18n-js/compare/v3.4.1...v3.4.2
[3.4.1]:      https://github.com/fnando/i18n-js/compare/v3.4.0...v3.4.1
[3.4.0]:      https://github.com/fnando/i18n-js/compare/v3.3.0...v3.4.0
[3.3.0]:      https://github.com/fnando/i18n-js/compare/v3.2.3...v3.3.0
[3.2.3]:      https://github.com/fnando/i18n-js/compare/v3.2.2...v3.2.3
[3.2.2]:      https://github.com/fnando/i18n-js/compare/v3.2.1...v3.2.2
[3.2.1]:      https://github.com/fnando/i18n-js/compare/v3.2.0...v3.2.1
[3.2.0]:      https://github.com/fnando/i18n-js/compare/v3.1.0...v3.2.0
[3.1.0]:      https://github.com/fnando/i18n-js/compare/v3.0.11...v3.1.0
[3.0.11]:     https://github.com/fnando/i18n-js/compare/v3.0.10...v3.0.11
[3.0.10]:     https://github.com/fnando/i18n-js/compare/v3.0.9...v3.0.10
[3.0.9]:      https://github.com/fnando/i18n-js/compare/v3.0.8...v3.0.9
[3.0.8]:      https://github.com/fnando/i18n-js/compare/v3.0.7...v3.0.8
[3.0.7]:      https://github.com/fnando/i18n-js/compare/v3.0.6...v3.0.7
[3.0.6]:      https://github.com/fnando/i18n-js/compare/v3.0.5...v3.0.6
[3.0.5]:      https://github.com/fnando/i18n-js/compare/v3.0.4...v3.0.5
[3.0.4]:      https://github.com/fnando/i18n-js/compare/v3.0.3...v3.0.4
[3.0.3]:      https://github.com/fnando/i18n-js/compare/v3.0.2...v3.0.3
[3.0.2]:      https://github.com/fnando/i18n-js/compare/v3.0.1...v3.0.2
[3.0.1]:      https://github.com/fnando/i18n-js/compare/v3.0.0...v3.0.1
[3.0.0]:      https://github.com/fnando/i18n-js/compare/v3.0.0.rc16...v3.0.0
[3.0.0.rc16]: https://github.com/fnando/i18n-js/compare/v3.0.0.rc15...v3.0.0.rc16
[3.0.0.rc15]: https://github.com/fnando/i18n-js/compare/v3.0.0.rc14...v3.0.0.rc15
[3.0.0.rc14]: https://github.com/fnando/i18n-js/compare/v3.0.0.rc13...v3.0.0.rc14
[3.0.0.rc13]: https://github.com/fnando/i18n-js/compare/v3.0.0.rc12...v3.0.0.rc13
[3.0.0.rc12]: https://github.com/fnando/i18n-js/compare/v3.0.0.rc11...v3.0.0.rc12
