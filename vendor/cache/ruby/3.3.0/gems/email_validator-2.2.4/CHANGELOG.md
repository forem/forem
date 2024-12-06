# CHANGELOG

This file is used to list changes made in `email_validator`.

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 2.2.4 (2022-11-09)

* [karlwilbur] - Remove Ruby 2.4 from tested versions; add Ruby 3.0 and 3.1 to tested versions
* [karlwilbur] - Fix issue where `domain: ''` wasn't requiring empty domain
* [karlwilbur] - Remove checks for double hyphens (fixes [#87](https://github.com/K-and-R/email_validator/issues/87))
* [dependabot] - Security updates
    - [#89](https://github.com/K-and-R/email_validator/pull/89)
        + Bump `minimist` from `1.2.5` to `1.2.7`
    - [#86](https://github.com/K-and-R/email_validator/pull/86)
        + Bump `node-fetch` from `2.6.1` to `2.6.7`
        + Add `whatwg-url` at `5.0.0`
        + Add `tr46` at `0.0.3`
        + Add `webidl-conversions` at `3.0.0`
    - [#80](https://github.com/K-and-R/email_validator/pull/80)
        + Bump `tar` from `6.0.5` to `6.1.11`
        + Bump `minipass` from `3.1.3` to `3.1.5`
    - [#79](https://github.com/K-and-R/email_validator/pull/79)
        + Bump `path-parse` from `1.0.6` to `1.0.7`
    - [#76](https://github.com/K-and-R/email_validator/pull/76)
        + Bump `lodash` from `4.17.20` to `4.17.21`
    - [#75](https://github.com/K-and-R/email_validator/pull/75)
        + Bump `hosted-git-info` from `2.8.8` to `2.8.9`
* [msands] - Fix URL in `README.md` [#81](https://github.com/K-and-R/email_validator/pull/81)
* [kerolloz] - Fix typo in `README.md` [#73](https://github.com/K-and-R/email_validator/pull/73)

## 2.2.3 (2021-04-05)

* [karlwilbur] - Fix regexp for numeric domains (fixes [#72](https://github.com/K-and-R/email_validator/issues/72))
    - [delphaber] - Add checks for numeric-only domains in tests (should be considered valid)
    - [karlwilbur] - Fix specs for numeric-only domains labels (should be considered valid)
    - [karlwilbur] - Add checks for numeric-only TLDs in tests (should be considered invalid)
    - [karlwilbur] - Add tests to ensure that `regexp` returns expected value
* [karlwilbur] - Add checks for double dash in domain (should be considered invalid)
* [karlwilbur] - Add `EmailValidator::Error` class, raise `EmailValidator::Error` when invalid `mode`

## 2.2.2 (2020-12-10)

* [karlwilbur] - Fix includes for `:rfc` and `:strict` modes from `Gemfile`

## 2.2.1 (2020-12-10)

* [karlwilbur] - Modify regexp to:
    - allow numeric-only hosts [#68]
    - allow mailbox-only addresses  in `:rfc` mode
    - enforce the 255-char domain limit (not in `:loose` mode unless using `:domain`)

## 2.2.0 (2020-12-09)

* [karlwilbur] - Rename `:strict` -> `:rfc`; `:moderate` -> `:strict`

## 2.1.0 (2020-12-09)

* [karlwilbur] - Add linters and commit hooks to validate code prior to commits
* [karlwilbur] - Add `:mode` config option; values `:loose`, `:moderate`, `:strict`; default to `:loose`
* [karlwilbur] - Merge in changes from <https://github.com/karlwilbur/email_validator> fork

## 1.9.0.pre (2020-10-14)

* [karlwilbur] - Add `require_fqdn` option, require FQDN by default
* [karlwilbur] - Add support for IPv4 and IPv6 address hosts
* [karlwilbur] - Add Rubocop, `.editorconfig`; code cleanup/linting

## 1.8.0 (2019-06-14)

* [karlwilbur] - Refactor class methods for readability
* [karlwilbur] - `gemspec` meta updates
* [karlwilbur] - Use POSIX classes for better performance
* [karlwilbur] - Refactored tests to check specical characters one at a time
* [karlwilbur] - Refactored validation regex to be more techincally correct
* [karlwilbur] - Add this `CHANGELOG`

## 1.7.0 (2019-04-20)

* [karlwilbur] - Added test coverage badge to README
* [karlwilbur] - Added I18n directive to remove warning message in testing
* [karlwilbur] - Added RFC-2822 reference
* [karlwilbur] - Ignore local rspec config file
* [karlwilbur] - Check for invalid double dots in strict mode
* [karlwilbur] - Updated spec_helper to remove Code Climate Test Reporter; it is to be run separately now
* [karlwilbur] - Allow leading/trailing whitespace in normal, not strict
* [karlwilbur] - Added `invalid?` as inverse of `valid?`
* [karlwilbur] - Add the ability to limit to a domain
* [karlwilbur] - Removed CodeShip badge
* [karlwilbur] - Make the dot in the domain part non-conditional
* [karlwilbur] - Fix domain label pattern to allow numbers per rfc5321

## 1.6.0 (2015-06-14)

* [karlwilbur] - Fixed validation to be closer to RFC-5321
* [karlwilbur] - Updated specs to use Rspec 3 syntax
* [karlwilbur] - Added unicode suport to validation regexp
* [karlwilbur] - Added class access to regexp, and `valid?` calss method
* [karlwilbur] - Simplified code using new methods
* [karlwilbur] - Added CodeClimate and SimpleCov
* [karlwilbur] - Updated version and contact info

*** Forked from <https://github.com/balexand/email_validator>

## 2.0.1 (2019-03-09)

* Add email value to error details [f1sherman #50]
* CI doesn't test Ruby versions that no longer receive updates [f1sherman #51]

## 2.0.0 (2019-03-02)

* Looser validation [#49]

## 1.6.0 (2015-05-12)

* Unicode characters support [i7an #24]

## 1.5.0 (2014-12-08)

* Add a class method for simpler validation [TiteiKo and cluesque #19]
* RSpec 3.0 syntax [strivedi183 #17]
* Create Changes.md

---

Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax)
for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/)
describes the differences between markdown on github and standard markdown.
