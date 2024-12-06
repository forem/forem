# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]
### Added
- A new option: `view_box` adds a `viewBox` attribute to the SVG. [#142](https://github.com/jamesmartin/inline_svg/pull/142). Thanks [@sunny](https://github.com/sunny)

### Fixed
- Allow Propshaft assets to use fallbacks. [#140](https://github.com/jamesmartin/inline_svg/pull/140). Thanks, [@ohrite](https://github.com/ohrite)
- Handling missing file when using static assets. [#141](https://github.com/jamesmartin/inline_svg/pull/141). Thanks, [@leighhalliday](https://github.com/leighhalliday)
- Handle missing file when using Webpacker assets.

## [1.8.0] - 2022-01-09
### Added
- Remove deprecation warning for `inline_svg`, as we intend to keep it in 2.0. [#131](https://github.com/jamesmartin/inline_svg/pull/131). Thanks [@DanielJackson-Oslo](https://github.com/DanielJackson-Oslo)
- Add support for Webpacker 6 beta. [#129](https://github.com/jamesmartin/inline_svg/pull/129). Thanks [@Intrepidd](https://github.com/Intrepidd) and [@tessi](https://github.com/tessi)
- Add support for Propshaft assets in Rails 7. [#134](https://github.com/jamesmartin/inline_svg/pull/134). Thanks, [@martinzamuner](https://github.com/martinzamuner)

## [1.7.2] - 2020-12-07
### Fixed
- Improve performance of `CachedAssetFile`. [#118](https://github.com/jamesmartin/inline_svg/pull/118). Thanks [@stevendaniels](https://github.com/stevendaniels)
- Avoid XSS by preventing malicious input of filenames. [#117](https://github.com/jamesmartin/inline_svg/pull/117). Thanks [@pbyrne](https://github.com/pbyrne).

## [1.7.1] - 2020-03-17
### Fixed
- Static Asset Finder uses pathname for compatibility with Sprockets 4+. [#106](https://github.com/jamesmartin/inline_svg/pull/106). Thanks [@subdigital](https://github.com/subdigital)

## [1.7.0] - 2020-02-13
### Added
- WebpackAssetFinder serves files from dev server if one is running. [#111](https://github.com/jamesmartin/inline_svg/pull/111). Thanks, [@connorshea](https://github.com/connorshea)

### Fixed
- Using Webpacker and Asset Pipeline in a single App could result in SVGs not being found because the wrong `AssetFinder` was used. [#114](https://github.com/jamesmartin/inline_svg/pull/114). Thanks, [@kylefox](https://github.com/kylefox)
- Prevent "EOFError error" when using webpack dev server over HTTPS [#113](https://github.com/jamesmartin/inline_svg/pull/113). Thanks, [@kylefox](https://github.com/kylefox)

## [1.6.0] - 2019-11-13
### Added
- Support Webpack via the new `inline_svg_pack_tag` helper and deprecate `inline_svg` helper in preparation for v2.0.
[#103](https://github.com/jamesmartin/inline_svg/pull/103)
Thanks, [@kylefox](https://github.com/kylefox)

## [1.5.2] - 2019-06-20
### Fixed
- Revert automatic Webpack asset finder behavior. Make Webpack "opt-in".
  [#98](https://github.com/jamesmartin/inline_svg/issues/98)

## [1.5.1] - 2019-06-18
### Fixed
- Prevent nil asset finder when neither Sprockets or Webpacker are available
  [#97](https://github.com/jamesmartin/inline_svg/issues/97)

## [1.5.0] - 2019-06-17
### Added
- Support for finding assets bundled by Webpacker
  [#96](https://github.com/jamesmartin/inline_svg/pull/96)

## [1.4.0] - 2019-04-19
### Fixed
- Prevent invalid XML names being generated via IdGenerator
  [#87](https://github.com/jamesmartin/inline_svg/issues/87)
  Thanks, [@endorfin](https://github.com/endorfin)

### Added
- Raise error on file not found (if configured)
  [#93](https://github.com/jamesmartin/inline_svg/issues/93)

## [1.3.1] - 2017-12-14
### Fixed
- Allow Ruby < 2.1 to work with `CachedAssetFile`
  [#80](https://github.com/jamesmartin/inline_svg/pull/80)

## [1.3.0] - 2017-10-30
### Added
- Aria hidden attribute
  [#78](https://github.com/jamesmartin/inline_svg/pull/78)
  and [#79](https://github.com/jamesmartin/inline_svg/pull/79)
- In-line CSS style attribute
  [#71](https://github.com/jamesmartin/inline_svg/pull/71)

### Fixed
- Make aria ID attributes unique
  [#77](https://github.com/jamesmartin/inline_svg/pull/77)

## [1.2.3] - 2017-08-17
### Fixed
- Handle UTF-8 characters in SVG documents
  [#60](https://github.com/jamesmartin/inline_svg/pull/69)

## [1.2.2] - 2017-07-06
### Fixed
- Handle malformed documents that don't contain a root SVG element
  [#60](https://github.com/jamesmartin/inline_svg/pull/65)
### Added
- Add configurable CSS class to empty SVG document
  [#67](https://github.com/jamesmartin/inline_svg/pull/67)

## [1.2.1] - 2017-05-02
### Fixed
- Select most exactly matching cached asset file when multiple files match
  given asset name [#64](https://github.com/jamesmartin/inline_svg/pull/64)

## [1.2.0] - 2017-04-20
### Added
- Cached asset file (load assets into memory at boot time)
  [#62](https://github.com/jamesmartin/inline_svg/pull/62)

## [1.1.0] - 2017-04-12
### Added
- Allow configurable asset file implementations
  [#61](https://github.com/jamesmartin/inline_svg/pull/61)

## [1.0.1] - 2017-04-10
### Fixed
- Don't override custom asset finders in Railtie

## [1.0.0] - 2017-04-7
### Added
- Remove dependency on `Loofah` while maintaining basic `nocomment` transform

## [0.12.1] - 2017-03-24
### Added
- Relax dependency on `Nokogiri` to allow users to upgrade to v1.7x, preventing
  exposure to
  [CVE-2016-4658](https://github.com/sparklemotion/nokogiri/issues/1615):
  [#59](https://github.com/jamesmartin/inline_svg/issues/59)

## [0.12.0] - 2017-03-16
### Added
- Relax dependency on `ActiveSupport` to allow Rails 3 applications to use the
  gem: [#54](https://github.com/jamesmartin/inline_svg/issues/54)

## [0.11.1] - 2016-11-22
### Fixed
- Dasherize data attribute names:
  [#51](https://github.com/jamesmartin/inline_svg/issues/51)
- Prevent ID collisions between `desc` and `title` attrs:
  [#52](https://github.com/jamesmartin/inline_svg/pull/52)

## [0.11.0] - 2016-07-24
### Added
- Priority ordering for transformations

### Fixed
- Prevent duplicate desc elements being created
  [#46](https://github.com/jamesmartin/inline_svg/issues/46)
- Prevent class attributes being replaced
  [#44](https://github.com/jamesmartin/inline_svg/issues/44)

## [0.10.0] - 2016-07-24
### Added
- Rails 5 support [#43](https://github.com/jamesmartin/inline_svg/pull/43)
- Support for `Sprockets::Asset`
  [#45](https://github.com/jamesmartin/inline_svg/pull/45)

## [0.9.1] - 2016-07-18
### Fixed
- Provide a hint when the .svg extension is omitted from the filename
  [#41](https://github.com/jamesmartin/inline_svg/issues/41)

## [0.9.0] - 2016-06-30
### Fixed
- Hashed IDs for desc and title elements in aria-labeled-by attribute
  [#38](https://github.com/jamesmartin/inline_svg/issues/38)

## [0.8.0] - 2016-05-23
### Added
- Default values for custom transformations
  [#36](https://github.com/jamesmartin/inline_svg/issues/36). Thanks,
  [@andrewaguiar](https://github.com/andrewaguiar)

## [0.7.0] - 2016-05-03
### Added
- Aria attributes transform (aria-labelledby / role etc.) Addresses issue
  [#28](https://github.com/jamesmartin/inline_svg/issues/28)

## [0.6.4] - 2016-04-23
### Fixed
- Don't duplicate the `title` element. Addresses issue
  [#31](https://github.com/jamesmartin/inline_svg/issues/31)
- Make the `title` element the first child node of the SVG document

## [0.6.3] - 2016-04-19
### Added
- Accept `IO` objects as arguments to `inline_svg`. Thanks,
  [@ASnow](https://github.com/ASnow).

## [0.6.2] - 2016-01-24
### Fixed
- Support Sprockets >= 3.0 and config.assets.precompile = false

## [0.6.1] - 2015-08-06
### Fixed
- Support Rails versions back to 4.0.4. Thanks, @walidvb.

## [0.6.0] - 2015-07-07
### Added
- Apply user-supplied [custom
transformations](https://github.com/jamesmartin/inline_svg/blob/master/README.md#custom-transformations) to a document.

## [0.5.3] - 2015-06-22
### Added
- `preserveAspectRatio` transformation on SVG root node. Thanks, @paulozoom.

## [0.5.2] - 2015-04-03
### Fixed
- Support Sprockets v2 and v3 (Sprockets::Asset no longer to_s to a filename)

## [0.5.1] - 2015-03-30
### Warning
** This version is NOT comaptible with Sprockets >= 3. **

### Fixed
- Support for ActiveSupport (and hence, Rails) 4.2.x. Thanks, @jmarceli.

## [0.5.0] - 2015-03-29
### Added
- A new option: `id` adds an id attribute to the SVG.
- A new option: `data` adds data attributes to the SVG.

### Changed
- New options: `height` and `width` override `size` and can be set independently.

## [0.4.0] - 2015-03-22
### Added
- A new option: `size` adds width and height attributes to an SVG. Thanks, @2metres.

### Changed
- Dramatically simplified the TransformPipeline and Transformations code.
- Added tests for the pipeline and new size transformations.

### Fixed
- Transformations can no longer be created with a nil value.

## [0.3.0] - 2015-03-20
### Added
- Use Sprockets to find canonical asset paths (fingerprinted, post asset-pipeline).

## [0.2.0] - 2014-12-31
### Added
- Optionally remove comments from SVG files. Thanks, @jmarceli.

## [0.1.0] - 2014-12-15
### Added
- Optionally add a title and description to a document. Thanks, ludwig.schubert@qlearning.de.
- Add integration tests for main view helper. Thanks, ludwig.schubert@qlearning.de.

## 0.0.1 - 2014-11-24
### Added
- Basic Railtie and view helper to inline SVG documents to Rails views.

[unreleased]: https://github.com/jamesmartin/inline_svg/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/jamesmartin/inline_svg/compare/v1.7.2...v1.8.0
[1.7.2]: https://github.com/jamesmartin/inline_svg/compare/v1.7.1...v1.7.2
[1.7.1]: https://github.com/jamesmartin/inline_svg/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/jamesmartin/inline_svg/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/jamesmartin/inline_svg/compare/v1.5.2...v1.6.0
[1.5.2]: https://github.com/jamesmartin/inline_svg/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/jamesmartin/inline_svg/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/jamesmartin/inline_svg/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/jamesmartin/inline_svg/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/jamesmartin/inline_svg/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/jamesmartin/inline_svg/compare/v1.2.3...v1.3.0
[1.2.3]: https://github.com/jamesmartin/inline_svg/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/jamesmartin/inline_svg/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/jamesmartin/inline_svg/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/jamesmartin/inline_svg/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/jamesmartin/inline_svg/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/jamesmartin/inline_svg/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/jamesmartin/inline_svg/compare/v0.12.1...v1.0.0
[0.12.1]: https://github.com/jamesmartin/inline_svg/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/jamesmartin/inline_svg/compare/v0.11.1...v0.12.0
[0.11.1]: https://github.com/jamesmartin/inline_svg/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/jamesmartin/inline_svg/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/jamesmartin/inline_svg/compare/v0.9.1...v0.10.0
[0.9.1]: https://github.com/jamesmartin/inline_svg/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/jamesmartin/inline_svg/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/jamesmartin/inline_svg/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/jamesmartin/inline_svg/compare/v0.6.4...v0.7.0
[0.6.4]: https://github.com/jamesmartin/inline_svg/compare/v0.6.3...v0.6.4
[0.6.3]: https://github.com/jamesmartin/inline_svg/compare/v0.6.2...v0.6.3
[0.6.2]: https://github.com/jamesmartin/inline_svg/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/jamesmartin/inline_svg/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/jamesmartin/inline_svg/compare/v0.5.3...v0.6.0
[0.5.3]: https://github.com/jamesmartin/inline_svg/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/jamesmartin/inline_svg/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/jamesmartin/inline_svg/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/jamesmartin/inline_svg/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/jamesmartin/inline_svg/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/jamesmartin/inline_svg/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/jamesmartin/inline_svg/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jamesmartin/inline_svg/compare/v0.0.1...v0.1.0
