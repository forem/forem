0.12.3 (2020-09-23)
==================

## Bugfixes
* Relax ruby version requirement to work with Ruby 3.0 (next version, current `ruby-head`). Thanks [@byroot](https://github.com/byroot).

0.12.2 (2020-02-27)
==================

## Bugfixes
* Refreshing the page while a source file is open works again. Thanks [@HansBug](https://github.com/HansBug) for the report [#94](https://github.com/simplecov-ruby/simplecov-html/issues/94) and [@Tietew](https://github.com/Tietew) for the fix!

0.12.1 (2020-02-23)
==================

Bugfix release to fix huge bugs that sadly test suit and maintainters didn't catch.

## Bugfixes
* Disable pagination and with it all files on 2nd page+ being broken/not able to open
* Fix display of non ASCII characters, for this you have to upgrade to simplecov 0.18.3 though (it's handled in there)

0.12.0 (2020-02-12)
==================

This release is basically a collection of long standing PRs finally merged.
Yes it looks different, no it's not a redesign - just a side effect of lots of dependency updates to improve CSP compatibility.

## Enhancements
* The HTML should now be servable with CSP settings of `default-src 'none'; script-src 'self'; img-src 'self'; style-src 'self';`
* File list is horizontally scrollable if the space doesn't suffice
* numbers are now right aligned and displayed with the same number of decimals for easier comparison and reading.

## Bugfixes
* Make sorting icons appear again
* close link tag which could cause problems when parsing as xhtml/xml
* make sure encoding errors won't crash the formatter
* When viewing a short source file while you have a big file list you will no longer be able to scroll on after the source file has ended

0.11.0 (2020-01-28)
=======

This release goes together with simplecov 0.18 to bring branch coverage support to you. Please also check the notes of the beta releases.

## Enhancements
* Display total branch coverage percentage in the overview (if branch coverage enabled)

0.11.0.beta2 (2020-01-19)
=======

## Enhancements
* changed display of branch coverage to be `branch_type: hit_count` which should be more expressive and more intuitive
* Cached lookup of whether we're doing branch coverage or not (should be faster)

## Bugfixes
* Fixed sorting of percent column (regression in previous release)

0.11.0.beta1 (2020-01-05)
========

Changes ruby support to 2.4+, adds branch coverage support. Meant to be used with simplecov 0.18

## Breaking Changes
* Drops support for EOL'ed ruby versions, new support is ~> 2.4

## Enhancements
* Support/display of branch coverage from simplecov 0.18.0.beta1, little badges saying `hit_count, positive_or_negative` will appear next to lines if branch coverage is activated. `0, +` means positive branch was never hit, `2, -` means negative branch was hit twice
* Encoding compatibility errors are now caught and printed out

0.10.2 (2017-08-14)
========

## Bugfixes

* Allow usage with frozen-string-literal-enabled. See [#56](https://github.com/simplecov-ruby/simplecov-html/pull/56) (thanks @pat)

0.10.1 (2017-05-17)
========

## Bugfixes

* circumvent a regression that happens in the new JRuby 9.1.9.0 release. See [#53](https://github.com/simplecov-ruby/simplecov-html/pull/53) thanks @koic
