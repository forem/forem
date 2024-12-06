# Changelog

## Master (Unreleased)

## 2.28.3 (2024-04-11)

- Fix an error for Ambiguous cop name `RSpec/Rails/HttpStatus`. ([@ydah])

## 2.28.2 (2024-03-31)

- Fix a `NameError` by Cross-Referencing. ([@ydah])
- Fix an error for `RSpecRails/HttpStatus` when no rack gem is loaded with rubocop-rspec. ([@ydah])
- Fix an error for unrecognized cop or department `RSpecRails/HttpStatus` when also using rubocop-rails. ([@ydah])

## 2.28.1 (2024-03-29)

- Implicit dependency on RuboCop RSpec. Note that if you use rubocop-rspec_rails, you must also explicitly add rubocop-rspec to the Gemfile, because you are changing to an implicit dependency on RuboCop RSpec. ([@ydah])

## 2.28.0 (2024-03-28)

- Extracted from `rubocop-rspec` into a separate repository. ([@ydah])

## Previously (see [rubocop-rspec's changelist](https://github.com/rubocop/rubocop-rspec/blob/v2.27.1/CHANGELOG.md) for details)

- Add support for `assert_true`, `assert_false`, `assert_not_equal`, `assert_not_nil`, `*_empty`, `*_predicate`, `*_kind_of`, `*_in_delta`, `*_match`, `*_instance_of` and `*_includes` assertions in `RSpec/Rails/MinitestAssertions`. ([@ydah], [@G-Rath])
- Add configuration option `ResponseMethods` to `RSpec/Rails/HaveHttpStatus`. ([@ydah])
- Add support single quoted string and percent string and heredoc for `RSpec/Rails/HttpStatus`. ([@ydah])
- Add support `RSpec/Rails/HttpStatus` when `have_http_status` with string argument. ([@ydah])
- Mark to `Safe: false` for `RSpec/Rails/NegationBeValid` cop. ([@ydah])
- Add new `RSpec/Rails/NegationBeValid` cop. ([@ydah])
- Fix a false negative for `RSpec/ExcessiveDocstringSpacing` when finds description with em space. ([@ydah])
- Fix a false positive for `RSpec/EmptyExampleGroup` when example group with examples defined in `if` branch inside iterator. ([@ydah])
- Update the message output of `RSpec/ExpectActual` to include the word 'value'. ([@corydiamand])
- Fix a false negative for `RSpec/Pending` when `it` without body. ([@ydah])
- Add new `RSpec/ReceiveMessages` cop. ([@ydah])
- Change default.yml path to use `**/spec/*` instead of `spec/*`. ([@ydah])
- Add `AllowedIdentifiers` and `AllowedPatterns` configuration option to `RSpec/IndexedLet`. ([@ydah])
- Fix `RSpec/NamedSubject` when block has no body. ([@splattael])
- Fix `RSpec/LetBeforeExamples` autocorrect incompatible with `RSpec/ScatteredLet` autocorrect. ([@ydah])
- Update `RSpec/Focus` to support `shared_context` and `shared_examples`. ([@tmaier])
- Fix an error for `RSpec/Rails/HaveHttpStatus` with comparison with strings containing non-numeric characters. ([@ydah])
- Add support `be_status` style for `RSpec/Rails/HttpStatus`. ([@ydah])
- Fix order of expected and actual in correction for `RSpec/Rails/MinitestAssertions`. ([@mvz])
- Add `RSpec/Rails/TravelAround` cop. ([@r7kamura])
- Add new `RSpec/Rails/MinitestAssertions` cop. ([@ydah])
- Improved processing speed for `RSpec/Be`, `RSpec/ExpectActual`, `RSpec/ImplicitExpect`, `RSpec/MessageSpies`, `RSpec/PredicateMatcher` and `RSpec/Rails/HaveHttpStatus`. ([@ydah])
- Fix an error for `RSpec/Rails/InferredSpecType` with redundant type before other Hash metadata. ([@ydah])
- Add `RSpec/Rails/InferredSpecType` cop. ([@r7kamura])
- Add new `RSpec/Rails/HaveHttpStatus` cop. ([@akiomik])
- Exclude unrelated Rails directories from `RSpec/DescribeClass`. ([@MothOnMars])
- Add `RSpec/Rails/AvoidSetupHook` cop. ([@paydaylight])
- Change namespace of several cops (`Capybara/*` -> `RSpec/Capybara/*`, `FactoryBot/*` -> `RSpec/FactoryBot/*`, `Rails/*` -> `RSpec/Rails/*`). ([@pirj], [@bquorning])
- The `Rails/HttpStatus` cop is unavailable if the `rack` gem cannot be loaded. ([@bquorning])
- Fix `Rails/HttpStatus` not working with custom HTTP status codes. ([@bquorning])
- Add `RSpec/Rails/HttpStatus` cop to enforce consistent usage of the status format (numeric or symbolic). ([@anthony-robin], [@jojos003])

<!-- Contributors (alphabetically) -->

[@akiomik]: https://github.com/akiomik
[@anthony-robin]: https://github.com/anthony-robin
[@bquorning]: https://github.com/bquorning
[@corydiamand]: https://github.com/corydiamand
[@g-rath]: https://github.com/G-Rath
[@jojos003]: https://github.com/jojos003
[@mothonmars]: https://github.com/MothOnMars
[@mvz]: https://github.com/mvz
[@paydaylight]: https://github.com/paydaylight
[@pirj]: https://github.com/pirj
[@r7kamura]: https://github.com/r7kamura
[@splattael]: https://github.com/splattael
[@tmaier]: https://github.com/tmaier
[@ydah]: https://github.com/ydah
