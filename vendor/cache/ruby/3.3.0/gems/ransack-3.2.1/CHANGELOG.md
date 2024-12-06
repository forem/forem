# Change Log

## Unreleased

## 3.2.1 - 2022-05-24

* Add search functionality to documentation site.
  PR [1329](https://github.com/activerecord-hackery/ransack/pull/1329)

* Fix contributing URLs and syntax highlight in `README.md`.
  PR [1326](https://github.com/activerecord-hackery/ransack/pull/1326)

* Cast PostgreSQL's `timestamptz` columns to time.
  PR [1325](https://github.com/activerecord-hackery/ransack/pull/1325)

* Add Ruby and ERB syntax highlighting support to documentation site.
  PR [1324](https://github.com/activerecord-hackery/ransack/pull/1324)

* Fix a wrong link in `CHANGELOG.md`.
  PR [1323](https://github.com/activerecord-hackery/ransack/pull/1323)

* Fix links to bug report templates in `CONTRIBUTING.md`.
  PR [1321](https://github.com/activerecord-hackery/ransack/pull/1321)

## 3.2.0 - 2022-05-08

* Drop Rails 6.0 support.
  PR [1318](https://github.com/activerecord-hackery/ransack/pull/1318)

* Exclude "host" from params sent to url generator.
  PR [1317](https://github.com/activerecord-hackery/ransack/pull/1317)

## 3.1.0 - 2022-04-21

* Fix predicate name in "Using Predicates" documentation page.
  PR [1313](https://github.com/activerecord-hackery/ransack/pull/1313)

* Drop Ruby 2.6 support.
  PR [1311](https://github.com/activerecord-hackery/ransack/pull/1311)

* Allow Ransack to be used with Rails 7.1.0.alpha.
  PR [1309](https://github.com/activerecord-hackery/ransack/pull/1309)

* Put contributor list last in documentation site.
  PR [1308](https://github.com/activerecord-hackery/ransack/pull/1308)

* Add `acts-as-taggable-on` and polymorphic searches to documentation.
  PR [1306](https://github.com/activerecord-hackery/ransack/pull/1306)
  PR [1312](https://github.com/activerecord-hackery/ransack/pull/1312)

* Add full link to issue about merging searches to documentation.
  PR [1305](https://github.com/activerecord-hackery/ransack/pull/1305)

## 3.0.1 - 2022-04-08

* Fix `:data` option to `sort_link` being incorrectly appended to the generated
  link query parameters.
  PR [1301](https://github.com/activerecord-hackery/ransack/pull/1301)

* Fix "Edit this page" links in documentation site
  PR [1303](https://github.com/activerecord-hackery/ransack/pull/1303)

* Auto deploy documentation site after merging PRs
  PR [1302](https://github.com/activerecord-hackery/ransack/pull/1302)

* Add list of former wiki contributors to documentation site
  PR [1300](https://github.com/activerecord-hackery/ransack/pull/1300)

* Reduce gem package size
  PR [1297](https://github.com/activerecord-hackery/ransack/pull/1297)

## 3.0.0 - 2022-03-30

* Move documentation into Docusaurus.
  PR [1291](https://github.com/activerecord-hackery/ransack/pull/1291)

* [BREAKING CHANGE] Remove deprecated `#search` method.
  PR [1147](https://github.com/activerecord-hackery/ransack/pull/1147)

* Allow scopes that define string SQL joins.
  PR [1225](https://github.com/activerecord-hackery/ransack/pull/1225)

* Improve `sort_link` documentation.
  PR [1290](https://github.com/activerecord-hackery/ransack/pull/1290)

* Deprecate passing two trailing hashes to `sort_link`, for example:

  ```ruby
  sort_link(@q, :bussiness_name, "bussines_name", {}, class: "foo")
  ```

  Pass a single hash with all options instead.
  PR [1289](https://github.com/activerecord-hackery/ransack/pull/1289)

* Fix `:class` option to `sort_link` not being passed to the generated link
  correctly when no additional options are passed. For example:

  ```ruby
  sort_link(@q, :bussiness_name, class: "foo")
  ```

  PR [1288](https://github.com/activerecord-hackery/ransack/pull/1288)

* Evaluate `ransackable_scopes` before attributes when building the query.
  PR [759](https://github.com/activerecord-hackery/ransack/pull/759)

## 2.6.0 - 2022-03-08

* Fix regression when joining a table with itself.
  PR [1275](https://github.com/activerecord-hackery/ransack/pull/1276)

* Drop support for ActiveRecord older than 6.0.4.
  PR [1276](https://github.com/activerecord-hackery/ransack/pull/1276)

## 2.5.0 - 2021-12-26

* Document release process by @scarroll32 in https://github.com/activerecord-hackery/ransack/pull/1199, https://github.com/activerecord-hackery/ransack/pull/1200.
* Support Rails 7 by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1205, https://github.com/activerecord-hackery/ransack/pull/1209, https://github.com/activerecord-hackery/ransack/pull/1234, https://github.com/activerecord-hackery/ransack/pull/1230, https://github.com/activerecord-hackery/ransack/pull/1266
* Fix for `ActiveRecord::UnknownAttributeReference` in ransack by @TechnologyHypofriend in https://github.com/activerecord-hackery/ransack/pull/1207
* Make gem compatible with old polyamorous require by @rtweeks in https://github.com/activerecord-hackery/ransack/pull/1145
* Adding swedish translations by @johanandre in https://github.com/activerecord-hackery/ransack/pull/1208
* Document how to do case insensitive searches by @scarroll32 in https://github.com/activerecord-hackery/ransack/pull/1213
* Add the ability to disable whitespace stripping for string searches by @DCrow in https://github.com/activerecord-hackery/ransack/pull/1214
* Fix `:default` option in `Translate.attribute` method by @coreyaus in https://github.com/activerecord-hackery/ransack/pull/1218
* Fix typo in README.md by @d-m-u in https://github.com/activerecord-hackery/ransack/pull/1220
* Fix another typo in README.md by @plan-do-break-fix in https://github.com/activerecord-hackery/ransack/pull/1221
* Fix several documentation typos @wonda-tea-coffee in https://github.com/activerecord-hackery/ransack/pull/1233
* Allow ransack to treat nulls as always first or last by @mollerhoj in https://github.com/activerecord-hackery/ransack/pull/1226
* Consider ransack aliases when sorting by @faragorn and @waldyr in https://github.com/activerecord-hackery/ransack/pull/1223
* Fix non-casted array predicates by @danielpclark in https://github.com/activerecord-hackery/ransack/pull/1246
* Remove Squeel references from README by @Schwad in https://github.com/activerecord-hackery/ransack/pull/1249
* Remove part of the README that might lead to incorrect results by @RadekMolenda in https://github.com/activerecord-hackery/ransack/pull/1258
* ActiveRecord 7.0 support

## 2.4.2 - 2021-01-23

* Enable RuboCop and configure GitHub Actions to run RuboCop by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1185
* Add Ruby 3.0.0 support by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1190
* Drop Ruby 2.5 or older versions of Ruby by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1189
* Move bug report templates into ransack repository and run templates at CI by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1191
* Allow Ransack to be tested with Rails main branch by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1192

## 2.4.1 - 2020-12-21

* Links to Tidelift subscription by @deivid-rodriguez in https://github.com/activerecord-hackery/ransack/pull/1178
* Enable GitHub Actions by @yahonda in https://github.com/activerecord-hackery/ransack/pull/1180
* Move security contact information to SECURITY.md by @deivid-rodriguez in https://github.com/activerecord-hackery/ransack/pull/1179
* Add `ActiveRecord::Base.ransack!` which raises error if passed unknown condition by @alipman88 in https://github.com/activerecord-hackery/ransack/pull/1132
* Add ability to config PostgreSQL ORDER BY ... NULLS FIRST or NULLS LAST by @itsalongstory in https://github.com/activerecord-hackery/ransack/pull/1184

## 2.4.0 - 2020-11-27

* Specify actual version of polyamorous, so we can release that separately by @gregmolnar in https://github.com/activerecord-hackery/ransack/pull/1101
* Only include necessary files in gem package by @tvdeyen in https://github.com/activerecord-hackery/ransack/pull/1104
* Test/Fix for subquery in Rails 5.2.4  by @stevenjonescgm in https://github.com/activerecord-hackery/ransack/pull/1112
* Polyamorous module by @varyonic in https://github.com/activerecord-hackery/ransack/pull/1113
* Remove duplicated rows by @sasharevzin in https://github.com/activerecord-hackery/ransack/pull/1116
* Fix Ruby 2.7 deprecation warnings by @terracatta in https://github.com/activerecord-hackery/ransack/pull/1121
* Fixes polymorphic joins. by @PhilCoggins in https://github.com/activerecord-hackery/ransack/pull/1122
* Drop support for activerecord older than 5.2.4 by @deivid-rodriguez in https://github.com/activerecord-hackery/ransack/pull/1166
* Adapt to quoting change in Rails by @deivid-rodriguez in https://github.com/activerecord-hackery/ransack/pull/1165
* Typo in docs by @brett-anderson in https://github.com/activerecord-hackery/ransack/pull/1155
* Add Rails 6.1 support by @deivid-rodriguez in https://github.com/activerecord-hackery/ransack/pull/1172
* Strip Leading & Trailing Whitespace Before Searching by @itsalongstory in https://github.com/activerecord-hackery/ransack/pull/1126
* Use unfrozen version of symbol to string by @fauno in https://github.com/activerecord-hackery/ransack/pull/1149

## 2.3.2 - 2020-01-11

* Breakfix to bump Polyamorous

## 2.3.1 - 2020-01-11

* Drop support for Active Record 5.0, 5.1, and 5.2.0.
  PR [#1073](https://github.com/activerecord-hackery/ransack/pull/1073)

* Drop support for rubies under 2.3.
  PR [#1070](https://github.com/activerecord-hackery/ransack/pull/1070)

  ... and others

## 2.3.0 - 2019-08-18

* Arabic translations PR [979](https://github.com/activerecord-hackery/ransack/pull/979)

* Rails 6 PR [1027](https://github.com/activerecord-hackery/ransack/pull/1027)
 *vrodokanakis*

* Make polyamorous a separate gem PR [1002](https://github.com/activerecord-hackery/ransack/pull/1002)

* Catalan translations PR[1007](https://github.com/activerecord-hackery/ransack/pull/1007)
 *roslavych*

* Don't escape period characters with wildcard searches in mysql2 PR [1013](https://github.com/activerecord-hackery/ransack/pull/1013)
 *daflip*

* Farsi translations PR [1030](https://github.com/activerecord-hackery/ransack/pull/1030)

* Finnish translations PR [1049](https://github.com/activerecord-hackery/ransack/pull/1049)

* Fix wrong table alias when using nested join. for ActiveRecord >= 5.2
  PR [374](https://github.com/activerecord-hackery/ransack/pull/374)

  *hiichan*

## Version 2.1.1 - 2018-12-05

* Add `arabic` translation
  https://github.com/activerecord-hackery/ransack/pull/979

* Deprecate #search
  PR [975](https://github.com/activerecord-hackery/ransack/pull/975)

## Version 2.1.0 - 2018-10-26

* Add support for sorting by scopes
  PR [973](https://github.com/activerecord-hackery/ransack/pull/973)

  *Diego Borges*

* Added a new logo for Ransack
  PR [972](https://github.com/activerecord-hackery/ransack/pull/972)

  *Anıl Kılıç*, *Greg Molnar*

* Greek translations
  PR [971](https://github.com/activerecord-hackery/ransack/pull/971)
  PR [960](https://github.com/activerecord-hackery/ransack/pull/960)

  *Sean Carroll*, *Greg Molnar*

* README improvements
  PR [963](https://github.com/activerecord-hackery/ransack/pull/963)

  *tommaso1*

* Bulgarian translations
  PR [961](https://github.com/activerecord-hackery/ransack/pull/961)

  *Sean Carroll*

* README improvements
  PR [956](https://github.com/activerecord-hackery/ransack/pull/956)

  *Alex Konoval*

* Remove lib/ransack/adapters/active_record/compat.rb
  PR [954](https://github.com/activerecord-hackery/ransack/pull/954)

  *Ryuta Kamizono*

* Remove unused aliases
  PR [953](https://github.com/activerecord-hackery/ransack/pull/953)

  *Ryuta Kamizono*

## Version 2.0.1 - 2018-08-18

* Don't return association if table is nil
  PR [952](https://github.com/activerecord-hackery/ransack/pull/952)

  *Christian Gregg*

## Version 2.0.0 - 2018-08-09

* Add support for Active Record 5.2.1
  PR [#938](https://github.com/activerecord-hackery/ransack/pull/938)

* Fix sort with joins on existing association
  PR [#937](https://github.com/activerecord-hackery/ransack/pull/937)

* Add the ability to skip arg sanitization on a per scope basis. Using
  `ransackable_scopes_skip_sanitize_args`, users can define a list of
  scopes which will bypass parameter sanitization. This allows passing 0,
  1, t, f, etc. to a scope as an actual parameter.
  PR [#933](https://github.com/activerecord-hackery/ransack/pull/933)

* Drop support for Active Record < 5.0.
  PR [#929](https://github.com/activerecord-hackery/ransack/pull/929)

* Extract mongoid support to a separate gem.
  PR [#928](https://github.com/activerecord-hackery/ransack/pull/928)

* Absorb polyamorous
  PR [#927](https://github.com/activerecord-hackery/ransack/pull/927)

* Fix broken monkey patch of #form_with
  PR [#922](https://github.com/activerecord-hackery/ransack/pull/922)

## Version 1.8.8 - 2018-03-16
* Fix multiple database support
  PR [#893](https://github.com/activerecord-hackery/ransack/pull/893)

* Updated Dutch translations
  PR [#887](https://github.com/activerecord-hackery/ransack/pull/887)

* Fixed no method error 'asc' for Rails 4.2
  PR [#885](https://github.com/activerecord-hackery/ransack/pull/885)


## Version 1.8.7 - 2018-02-05

* Rails 5.2 support
  PR [#868](https://github.com/activerecord-hackery/ransack/pull/868)

* Lock pg gem to 0.21 to support older releases

* Warnings cleanup
  PR [#867](https://github.com/activerecord-hackery/ransack/pull/867)

* Wildcard escaping
  PR [#866]

## Version 1.8.6 - 2018-01-23

### Added

* Improve memory usage
  PR [#820](https://github.com/activerecord-hackery/ransack/pull/820)

* Bump Polyamorous version to 1.3.2
  PR [#858](https://github.com/activerecord-hackery/ransack/pull/858)

## Version 1.8.5

### Added

* Added Turkish Translations
  PR [#835](https://github.com/activerecord-hackery/ransack/issues/835).

## Version 1.8.4 - 2017-10-09

### Added

*   Added italian translations.
    PR [#833](https://github.com/activerecord-hackery/ransack/pull/833).

*   Add an optional default arrow for unsorted fields.
    PR [#816](https://github.com/activerecord-hackery/ransack/pull/816/files).

### Fixed

*   Cast Postgres money type to float.
    PR [#823](https://github.com/activerecord-hackery/ransack/pull/823).

*   Fix the bug in sort_link, which causes the multiple fields option to be
    ignored when block parameter is specified.
    PR [#818](https://github.com/activerecord-hackery/ransack/pull/818).

*   No need pass some arguments to JoinAssociation#join_constraints in Rails 5.1.
    PR [#814](https://github.com/activerecord-hackery/ransack/pull/814).
    Fixes [#807](https://github.com/activerecord-hackery/ransack/issues/807).
    Reference [rails/rails#28267](https://github.com/rails/rails/pull/28267)
    and [rails/rails#27851](https://github.com/rails/rails/pull/27851).

## Version 1.8.3 - 2017-06-15

### Added

*   Add a config option to customize the up and down arrows used for direction
    indicators in Ransack sort links.
    PR [#726](https://github.com/activerecord-hackery/ransack/pull/726).

    *Garett Arrowood*

*   Add ability to turn off sanitization of custom scope arguments.
    PR [#742](https://github.com/activerecord-hackery/ransack/pull/742).

    *Garett Arrowood*

### Fixed

*   Use class attributes properly so that inheritance is respected.
    PR [#717](https://github.com/activerecord-hackery/ransack/pull/717).
    This fixes two bugs:

    1. In the Mongoid adapter, subclasses were not properly inheriting their
       parents' Ransack aliases because each class defined its own set of
       aliases.

    2. In the Active Record adapter, Ransack aliases were defined in such a way
       that the parent's (and grandparent's, etc.) aliases were overwritten by
       the child, meaning that all aliases were ultimately kept on
       `ActiveRecord::Base`. This had the unfortunate effect of enforcing
       uniqueness of Ransack alias names across all models rather than per
       model. Depending on the load order of models, earlier definitions of an
       alias in other models were clobbered.

    *Steve Richert (laserlemon)*

*   Use `ActiveSupport.on_load` hooks to include Ransack in Active Record,
    avoiding autoloading the constant too soon. PR
    [#719](https://github.com/activerecord-hackery/ransack/pull/719). Reference:
    [This comment in rails#23589]
    (https://github.com/rails/rails/issues/23589#issuecomment-229247727).

    *Yuji Yaginuma (y-yagi)*

## Version 1.8.2 - 2016-08-08
### Fixed

*   Fix empty attribute_fields regression in advanced search mode introduced by
    [235eae3](https://github.com/activerecord-hackery/ransack/commit/235eae3).
    Closes
    [#701](https://github.com/activerecord-hackery/ransack/issues/701). Commit
    [2839acf](https://github.com/activerecord-hackery/ransack/commit/2839acf).

    *Jon Atack, Jay Dorsey, Stefan Haslinger, Igor Kasyanchuk*

### Added

*   Add `sort_url` view helper that returns only the url of a `sort_link`. PR
    [#706](https://github.com/activerecord-hackery/ransack/pull/706).

    *amatotsuji*

## Version 1.8.1 - 2016-07-27
### Fixed

*   Fix `rake console` to run a command-line console with ransack + seed data.
    Commits
    [2cc781e](https://github.com/activerecord-hackery/ransack/commit/2cc781e),
    [f2e85ad](https://github.com/activerecord-hackery/ransack/commit/f2e85ad),
    [6a059ba](https://github.com/activerecord-hackery/ransack/commit/6a059ba).

    *Jon Atack*

*   Fix returned value of `Ransack::Nodes::Condition#format_predicate`. PR
    [#692](https://github.com/activerecord-hackery/ransack/pull/692).

    *Masahiro Saito*

*   Better test coverage on passing arrays to ransackers. Commit
    [98df2c5](https://github.com/activerecord-hackery/ransack/commit/98df2c5).

    *Jon Atack*

*   Fix missing Ransack::Constants::ASC constant. Commit
    [aece23c](https://github.com/activerecord-hackery/ransack/commit/aece23c).

    *Jon Atack*

### Changed

*   Replace arrow constants with frozen strings in public methods. Commits
    [c0dff33](https://github.com/activerecord-hackery/ransack/commit/c0dff33),
    [e489ca7](https://github.com/activerecord-hackery/ransack/commit/e489ca7).

    *Jon Atack*

## Version 1.8.0 - 2016-07-14
### Added

*   Support Mongoid 5. PR [#636](https://github.com/activerecord-hackery/ransack/pull/636), commit
    [9e5faf4](https://github.com/activerecord-hackery/ransack/commit/9e5faf4).

    *Josef Šimánek*

*   Add optional block argument for the `sort_link` method. PR
    [#604](https://github.com/activerecord-hackery/ransack/pull/604).

    *Andrea Dal Ponte*

*   Add `ransack_alias` to allow users to customize the names for long
    ransack field names. PR
    [#623](https://github.com/activerecord-hackery/ransack/pull/623).

    *Ray Zane*

*   Add support for searching on attributes that have been added to
    Active Record models with `alias_attribute` (Rails >= 4 only). PR
    [#592](https://github.com/activerecord-hackery/ransack/pull/592), commit
    [549342a](https://github.com/activerecord-hackery/ransack/commit/549342a).

    *Marten Schilstra*

*   Add ability to globally hide sort link order indicator arrows with
    `Ransack.configure#hide_sort_order_indicators = true`. PR
    [#577](https://github.com/activerecord-hackery/ransack/pull/577), commit
    [95d4591](https://github.com/activerecord-hackery/ransack/commit/95d4591).

    *Josh Hunter*, *Jon Atack*

*   Add test for `ActionController:Parameter` object params in `sort_link` to
    ensure Ransack is handling the Rails 5 changes correctly. Commit
    [b1cfed8](https://github.com/activerecord-hackery/ransack/commit/b1cfed8).

    *Ryan Wood*

*   Add failing tests to facilitate work on issue
    [#566](https://github.com/activerecord-hackery/ransack/issues/566)
    of passing boolean values to search scopes. PR
    [#575](https://github.com/activerecord-hackery/ransack/pull/575).

    *Marcel Eeken*

*   Add i18n locale files:
  *   Taiwanese Hokkien/Mandarin (`zh-TW.yml`). PR
    [#674](https://github.com/activerecord-hackery/ransack/pull/674). *Sibevin Wang*
  *   Danish (`da.yml`). PR
    [#663](https://github.com/activerecord-hackery/ransack/pull/663). *Kasper Johansen*
  *   Brazilian Portuguese (`pt-BR.yml`). PR
    [#581](https://github.com/activerecord-hackery/ransack/pull/581). *Diego Henrique Domingues*
  *   Indonesian (Bahasa) (`id.yml`). PR
    [#612](https://github.com/activerecord-hackery/ransack/pull/612). *Adam Pahlevi Baihaqi*
  *   Japanese (`ja.yml`). PR
    [#622](https://github.com/activerecord-hackery/ransack/pull/622). *Masanobu Mizutani*

### Fixed

*   In `FormHelper::SortLink#parameters_hash`, convert `params#to_unsafe_h`
    only if Rails 5, and add tests. Commit
    [14e66ca](https://github.com/activerecord-hackery/ransack/commit/14e66ca).

    *Jon Atack*

*   Respect negative conditions for collection associations and fix Mongoid
    compat. PR [#645](https://github.com/activerecord-hackery/ransack/pull/645).

    *Andrew Vit*

*   Ensure conditions differing only by ransacker_args aren't filtered out.
    PR [#665](https://github.com/activerecord-hackery/ransack/pull/665).

    *Andrew Porterfield*

*   Fix using aliased attributes in association searches, and add a failing
    spec. PR [#602](https://github.com/activerecord-hackery/ransack/pull/602).

    *Marten Schilstra*

*   Replace Active Record `table_exists?` API that was deprecated
    [here](https://github.com/rails/rails/commit/152b85f) in Rails 5. Commit
    [c9d2297](https://github.com/activerecord-hackery/ransack/commit/c9d2297).

    *Jon Atack*

*   Adapt to changes in Rails 5 where AC::Parameters composes a HWIA instead of
    inheriting from Hash starting from Rails commit rails/rails@14a3bd5. Commit
    [ceafc05](https://github.com/activerecord-hackery/ransack/commit/ceafc05).

    *Jon Atack*

*   Fix test `#sort_link with hide order indicator set to true` to fail properly
    ([4f65b09](https://github.com/activerecord-hackery/ransack/commit/4f65b09)).
    This spec, added in
    [#473](https://github.com/activerecord-hackery/ransack/pull/473), tested
    the presence of the attribute name instead of the absence of the order
    indicators and did not fail when it should.

    *Josh Hunter*, *Jon Atack*

*   Fix rspec-mocks `stub` deprecation warnings when running the tests. Commit
    [600892e](https://github.com/activerecord-hackery/ransack/commit/600892e).

    *Jon Atack*

*   Revert
    [f858dd6](https://github.com/activerecord-hackery/ransack/commit/f858dd6).
    Fixes [#553](https://github.com/activerecord-hackery/ransack/issues/553)
    performance regression with the SQL Server adapter.

    *sschwing3*

*   Fix invalid Chinese I18n locale file name by replacing "zh" with "zh-CN".
    PR [#590](https://github.com/activerecord-hackery/ransack/pull/590).

    *Ethan Yang*

### Changed

*   Memory/speed perf improvement: Freeze strings in array global constants and
    partially move from using global string constants to frozen strings
    ([381a83c](https://github.com/activerecord-hackery/ransack/commit/381a83c)
    and
    [ce114ec](https://github.com/activerecord-hackery/ransack/commit/ce114ec)).

    *Jon Atack*

*   Escape underscore `_` wildcard characters with PostgreSQL and MySQL. PR
    [#584](https://github.com/activerecord-hackery/ransack/issues/584).

    *Igor Dobryn*

*   Refactor `Ransack::Adapters` from conditionals to classes
    ([94a404c](https://github.com/activerecord-hackery/ransack/commit/94a404c)).

    *Jon Atack*

## Version 1.7.0 - 2015-08-20
### Added

*   Add Mongoid support for referenced/embedded relations. PR
    [#498](https://github.com/activerecord-hackery/ransack/pull/498).
    TODO: Missing spec coverage! Add documentation!

    *Penn Su*

*   Add German i18n locale file (`de.yml`). PR
    [#537](https://github.com/activerecord-hackery/ransack/pull/537).

    *Philipp Weissensteiner*

### Fixed

*   Fix
    [#499](https://github.com/activerecord-hackery/ransack/issues/499) and
    [#549](https://github.com/activerecord-hackery/ransack/issues/549).
    Ransack now loads only Active Record if both Active Record and Mongoid are
    running to avoid the two adapters overriding each other. This clarifies
    that Ransack currently knows how to work with only one database adapter
    active at a time. PR
    [#541](https://github.com/activerecord-hackery/ransack/pull/541).

    *ASnow (Большов Андрей)*

*   Fix [#299](https://github.com/activerecord-hackery/ransack/issues/299)
    `attribute_method?` parsing for attribute names containing `_and_`
    and `_or_`. Attributes named like `foo_and_bar` or `foo_or_bar` are
    recognized now instead of running failing checks for `foo` and `bar`.
    PR [#562](https://github.com/activerecord-hackery/ransack/pull/562).

    *Ryohei Hoshi*

*   Fix a time-dependent test failure. When the database has
    `default_timezone = :local` (system time) and the `Time.zone` is set to
    elsewhere, then `Date.current` does not match what the query produces for
    the stored timestamps. Resolved by setting everything to UTC. PR
    [#561](https://github.com/activerecord-hackery/ransack/pull/561).

    *Andrew Vit*

*   Avoid overwriting association conditions with default scope in Rails 3.
    When a model with default scope was associated with conditions
    (`has_many :x, conditions: ...`), the default scope would overwrite the
    association conditions. This patch ensures that both sources of conditions
    are applied. Avoid selecting records from joins that would normally be
    filtered out if they were selected from the base table. Only applies to
    Rails 3, as this issue was fixed since Rails 4. PR
    [#560](https://github.com/activerecord-hackery/ransack/pull/560).

    *Andrew Vit*

*   Fix RSpec `its` method deprecation warning: "Use of rspec-core's its
    method is deprecated. Use the rspec-its gem instead"
    ([c09aa17](https://github.com/activerecord-hackery/ransack/commit/c09aa17)).

*   Fix deprecated RSpec syntax in `grouping_spec.rb`
    ([ba92a0b](https://github.com/activerecord-hackery/ransack/commit/ba92a0b)).

    *Jon Atack*

### Changed

*   Upgrade gemspec dependencies: MySQL2 from '0.3.14' to '0.3.18', and RSpec
    from '~> 2.14.0' to '~> 2' which loads 2.99
    ([000cd22](https://github.com/activerecord-hackery/ransack/commit/000cd22)).

*   Upgrade spec suite to RSpec 3 `expect` syntax backward compatible with
    RSpec 2.9
    ([87cd36d](https://github.com/activerecord-hackery/ransack/commit/87cd36d)
    and
    [d296caa](https://github.com/activerecord-hackery/ransack/commit/d296caa)).

*   Various FormHelper refactorings
    ([17dd97a](https://github.com/activerecord-hackery/ransack/commit/17dd97a)
    and
    [29a73b9](https://github.com/activerecord-hackery/ransack/commit/29a73b9)).

*   Various documentation updates.

    *Jon Atack*


## Version 1.6.6 - 2015-04-05
### Added

*   Add the Ruby version to the the header message that shows the database,
    Active Record and Arel versions when running tests.

*   Add Code Climate analysis.

    *Jon Atack*

### Fixed

*   An improved fix for the "undefined method `model_name` for Ransack::Search"
    issue [#518](https://github.com/activerecord-hackery/ransack/issues/518)
    affecting Rails 4.2.1 and 5.0.0. This fix allows us to remove the
    ActionView patch in Ransack version 1.6.4.

    *Gleb Mazovetskiy*

*   Fix an erroneous reference in `ActiveRecord::Associations::JoinDependency`
    to a version-dependent Active Record reference, and replace it with a
    better, more reliable one defined in Polyamorous. As this class lives
    inside an `ActiveRecord` module, the reference needs to be absolute in
    order to properly point to the AR class.

    *Nahuel Cuesta Luengo*

*   Fix RubyGems YARD rendering of the README docs.

    *Jon Atack*

### Changed

*   Upgrade Polyamorous dependency to version 1.2.0, which uses `Module#prepend`
    instead of `alias_method` for hooking into Active Record (with Ruby 2.x).

    *Jon Atack*


## Version 1.6.5 - 2015-03-28 - Rails 5.0.0 update
### Added

*   [WIP/experimental] Add compatibility with Rails 5/master and Arel 7.

*   Update the [Contributing Guide](CONTRIBUTING.md) with detailed steps for
    contributing to Ransack.

*   Broaden the test suite database options in `schema.rb` and add
    code documentation.

*   Improve the header message when running tests.

    *Jon Atack*

*   Allow `:wants_array` to be set to `false` in the predicate options
    ([#32](https://github.com/activerecord-hackery/ransack/issues/32)).

    *Michael Pavling*

*   Add a failing spec for issue
    [#374](https://github.com/activerecord-hackery/ransack/issues/374).

    *Jamie Davidson*, *Jon Atack*

### Fixed

*   Stop relying on `Active Record::relation#where_values` which are deprecated
    in Rails 5.

*   Make the test for passing search arguments to a ransacker
    (`ransacker_args`) work correctly with Sqlite3.

    *Jon Atack*

### Changed

*   Stop CI testing for Rails 3.0 to reduce the size of the Travis test matrix.

    *Jon Atack*


## Version 1.6.4 - 2015-03-20 - Rails 4.2.1 update

*   ActionView patch to maintain compatibility with Rails 4.2.1 released today.

    *Jon Atack*

*   Enable scoping I18n by 'ransack.models'
    ([#514](https://github.com/activerecord-hackery/ransack/pull/514)).

    *nagyt234*

*   Add ransacker arguments
    ([#513](https://github.com/activerecord-hackery/ransack/pull/513)).

    *Denis Tataurov*, *Jon Atack*


## Version 1.6.3 - 2015-01-21

*   Fix a regression
    ([#496](https://github.com/activerecord-hackery/ransack/issues/496)) caused
    by [ee571fe](https://github.com/activerecord-hackery/ransack/commit/ee571fe)
    where passing a multi-parameter attribute (like `date_select`) raised
    `RuntimeError: can't add a new key into hash during iteration`, and add a
    regression spec for the issue.

    *Nate Berkopec*, *Jon Atack*

*   Update travis-ci to no longer test Rails 3.1 with Ruby 2.2 and speed up the test matrix.

*   Refactor Nodes::Condition.

    *Jon Atack*


## Version 1.6.2 - 2015-01-14

*   Fix a regression
    ([#494](https://github.com/activerecord-hackery/ransack/issues/494))
    where passing an array of routes to `search_form_for` no longer worked,
    and add a failing/passing test that would have caught the issue.

    *Daniel Rikowski*, *Jon Atack*


## Version 1.6.1 - 2015-01-14

*   Fix a regression with using `in` predicates caused by PR [#488](https://github.com/activerecord-hackery/ransack/pull/488)) and add a test.

*   README improvements to clarify `sort_link` syntax with associations and
    Ransack#search vs #ransack.

*   Default the Gemfile to Rails 4-2-stable.

    *Jon Atack*


## Version 1.6.0 - 2015-01-12
### Added

*   Add support for using Ransack with `Mongoid 4.0` without associations
    ([PR #407](https://github.com/activerecord-hackery/ransack/pull/407)).

    *Zhomart Mukhamejanov*

*   Add support and tests for passing stringy booleans for ransackable scopes
    ([PR #460](https://github.com/activerecord-hackery/ransack/pull/460)).

    *Josh Kovach*

*   Add an sort_link option to not display sort order indicator arrows
    ([PR #473](https://github.com/activerecord-hackery/ransack/pull/473)).

    *Fred Bergman*

*   Numerous documentation improvements to the README, Contributing Guide and
    wiki.

    *Jon Atack*

### Fixed

*   Fix passing arrays to ransackers with Rails 4.2 / Arel 6.0 (pull requests
    [#486](https://github.com/activerecord-hackery/ransack/pull/486) and
    [#488](https://github.com/activerecord-hackery/ransack/pull/488)).

    *Idean Labib*

*   Make `search_form_for`'s default `:as` option respect the custom search key
    if it has been set
    ([PR #470](https://github.com/activerecord-hackery/ransack/pull/470)).
    Prior to this change, if you set a custom `search_key` option in the
    Ransack initializer file, you'd have to also pass an `as: :whatever` option
    to all of the search forms. Fixes
    [#92](https://github.com/activerecord-hackery/ransack/issues/92).

    *Robert Speicher*

*   Fix sorting on polymorphic associations (missing downcase)
    ([PR #467](https://github.com/activerecord-hackery/ransack/pull/467)).

    *Eugen Neagoe*

*   Fix Rails 5 / Arel 5 compatibility after the Arel and Active Record API
    changed.

*   Fix and add tests for sort_link `default_order` parsing if the option is set
    as a string instead of symbol.

*   Fix and add a test to handle `nil` in options passed to sort_link.

*   Fix #search method name conflicts in the README.

    *Jon Atack*

### Changed

*   Refactor and DRY up FormHelper#SortLink. Encapsulate parsing into a
    Plain Old Ruby Object with few public methods and small, private functional
    methods. Limit mutations to explicit methods and mutate no ivars.

*   Numerous speed improvements by using more specific Ruby methods like:
      - `Hash#each_key` instead of `Hash#keys.each`
      - `#none?` instead of `select#empty?`
      - `#any?` instead of `#select` followed by `#any?`
      - `#flat_map` instead of `#flatten` followed by `#map`
      - `!include?` instead of `#none?`

*   Replace `string#freeze` instances with top level constants to reduce string
    allocations in Ruby < 2.1.

*   Remove unneeded `Ransack::` namespacing on most of the constants.

*   In enumerable methods, pass a symbol as an argument instead of a block.

*   Update Travis-ci for Rails 5.0.0 and 4-2-stable.

*   Update the Travis-ci tests and the Gemfile for Ruby 2.2.

*   Replace `#search` with `#ransack` class methods in the README and wiki
    code examples. Enabling the `#search` alias by default may possibly be
    deprecated in the next major release (Ransack v.2.0.0) to address
    [#369](https://github.com/activerecord-hackery/ransack/issues/369).

    *Jon Atack*


## Version 1.5.1 - 2014-10-30
### Added

*   Add base specs for search on fields with `_start` and `_end`.

*   Add a failing spec for detecting attribute fields containing `_and_` that
    needs to be fixed. Attribute names containing `_and_` and `_or_` are still
    not parsed/detected correctly.

    *Jon Atack*

### Fixed

*   Fix a regression caused by incorrect string constants in `context.rb`.

    *Kazuhiro Nishiyama*

### Changed

*   Remove duplicate code in `spec/support/schema.rb`.

    *Jon Atack*


## Version 1.5.0 - 2014-10-26
### Added

*   Add support for multiple sort fields and default orders in Ransack
    `sort_link` helpers
    ([PR #438](https://github.com/activerecord-hackery/ransack/pull/438)).

    *Caleb Land*, *James u007*

*   Add tests for `lteq`, `lt`, `gteq` and `gt` predicates. They are also
    tested in Arel, but testing them in Ransack has proven useful to detect
    issues.

    *Jon Atack*

*   Add tests for unknown attribute names.

    *Joe Yates*

*   Add tests for attribute names containing `_or_` and `_and_`.

    *Joe Yates*, *Jon Atack*

*   Add tests for attribute names ending with `_start` and `_end``.

    *Jon Atack*, *Timo Schilling*

*   Add tests for `start`, `not_start`, `end` and `not_end` predicates, with
    emphasis on cases when attribute names end with `_start` and `_end`.

    *Jon Atack*

### Fixed

*   Fix a regression where form labels for attributes through a `belongs_to`
    association without a translation for the attribute in the locales file
    would cause a "no implicit conversion of nil into Hash" crash instead of
    falling back on the attribute name. Added test coverage.

    *John Dell*, *Jon Atack*, *jasdeepgosal*

*   Fix the `form_helper date_select` spec that was failing with Rails 4.2 and
    master.

    *Jon Atack*

*   Improve `attribute_method?` parsing for attribute names containing `_and_`
    and `_or_`. Attributes named like `foo_and_bar` or `foo_or_bar` are
    recognized now instead of running failing checks for `foo` and `bar`.
    CORRECTION October 28, 2014: this feature is still not working!

    *Joe Yates*

*   Improve `attribute_method?` parsing for attribute names ending with a
    predicate like `_start` and `_end`. For instance, a `foo_start` attribute
    is now recognized instead of raising a NoMethodError.

    *Timo Schilling*, *Jon Atack*

### Changed

*   Reduce object allocations and memory footprint (with a slight speed gain as
    well) by extracting commonly used strings into top level constants and
    replacing calls to `#try` methods with simple nil checking.

    *Jon Atack*


## Version 1.4.1 - 2014-09-23

*   Fix README markdown so RubyGems documentation picks up the formatting correctly.

    *Jon Atack*


## Version 1.4.0 - 2014-09-23
### Added

*   Add support for Rails 4.2.0! Let us know if you encounter any issues.

    *Xiang Li*

*   Add `not_true` and `not_false` predicates and update the "Basic Searching"
    wiki. Fixes #123, #353.

    *Pedro Chambino*

*   Add Romanian i18n locale file (`ro.yml`).

    *Andreas Philippi*

*   Add new documentation in the README explaining how to group queries by `OR`
    instead of the default `AND` using the `m: 'or'` combinator.

*   Add new documentation in the README and in the source code comments
    explaining in detail how to handle whitelisting/authorization of
    attributes, associations, sorts and scopes.

*   Add new documentation in the README explaining in more detail how to use
    scopes for searching with Ransack.

*   Begin a CHANGELOG.

    *Jon Atack*

### Fixed

*   Fix singular/plural Active Record attribute translations.

    *Andreas Philippi*

*   Fix the params hash being modified by `Search.new` and the Ransack scope.

    *Daniel Rikowski*

*   Apply default scope conditions for association joins (fix for Rails 3).

    Avoid selecting records from joins that would normally be filtered out
    if they were selected from the base table. Only applies to Rails 3, as
    this issue was fixed in Rails 4.

    *Andrew Vit*

*   Fix incoherent code examples in the README Associations section that
    sometimes used `@q` and other times `@search`.

    *Jon Atack*

### Changed

*   Refactor Ransack::Translate.

*   Rewrite much of the Ransack README documentation, including the
    Associations section code examples and the Authorizations section detailing
    how to whitelist attributes, associations, sorts and scopes.

    *Jon Atack*


## Version 1.3.0 - 2014-08-23
### Added

*   Add search scopes by popular demand. Using `ransackable_scopes`, users can
    define whitelists for allowed model scopes on a parent table. Not yet
    implemented for associated models' scopes; scopes must be defined on the
    parent table.

    *Gleb Mazovetskiy*, *Andrew Vit*, *Sven Schwyn*

*   Add `JOINS` merging.

*   Add `OR` grouping on base search.

*   Allow authorizing/whitelisting attributes, associations, sorts and scopes.

*   Improve boolean predicates’ handling of `false` values.

*   Allow configuring Ransack to raise on instead of ignore unknown search
    conditions.

*   Allow passing blank values to search without crashing.

*   Add wildcard escaping compatibility for SQL Server databases.

*   Add various I18n translations.
