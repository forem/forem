# Changelog

## Edge (Unreleased)

## 2.20.0 (2024-01-03)

- Change to default `EnforcedStyle: link_or_button` for `Capybara/ClickLinkOrButtonStyle` cop. ([@ydah])
- Fix a false negative for `RSpec/HaveSelector` when first argument is dstr node. ([@ydah])
- Add new `Capybara/RedundantWithinFind` cop. ([@ydah])
- Fix an invalid attributes parse when name with multiple `[]` for `Capybara/SpecificFinders` and `Capybara/SpecificActions` and `Capybara/SpecificMatcher`. ([@ydah])
- Change to default `EnforcedStyle: have_no` for `Capybara/NegationMatcher` cop. ([@ydah])
- Fix a false positive for `Capybara/SpecificMatcher` when `text:` or `exact_text:` with regexp. ([@ydah])

## 2.19.0 (2023-09-20)

- Add new `Capybara/RSpec/PredicateMatcher` cop. ([@ydah])
- Add new `Capybara/RSpec/HaveSelector` cop. ([@ydah])
- Add new `Capybara/ClickLinkOrButtonStyle` cop. ([@ydah])
- Fix a false positive for `Capybara/SpecificFinders` when `find` with kind option. ([@ydah])
- Fix an incorrect autocorrect for `Capybara/CurrentPathExpectation`. ([@ydah])
- Drop Ruby 2.6 support. ([@ydah])

## 2.18.0 (2023-04-21)

- Fix an offense message for `Capybara/SpecificFinders`. ([@ydah])
- Expand `Capybara/NegationMatcher` to support `have_content`. ([@OskarsEzerins])
- Fix an incorrect autocorrect for `Capybara/CurrentPathExpectation` when matcher's argument is a method with a argument and no parentheses. ([@ydah])

## 2.17.1 (2023-02-13)

- Fix an incorrect autocorrect for `Capybara/CurrentPathExpectation`. ([@ydah])
- Fix a false negative for `Capybara/CurrentPathExpectation` when using `match`. ([@ydah])
- Fix a false positive and incorrect autocorrect for `Capybara/SpecificActions`, `Capybara/SpecificFinders` and `Capybara/SpecificMatcher`. ([@ydah])

## 2.17.0 (2022-12-29)

- Extracted from `rubocop-rspec` into a separate repository for easier use with Minitest/Cucumber. ([@pirj])

## Previously (see [rubocop-rspec's changelist](https://github.com/rubocop/rubocop-rspec/blob/9558719/CHANGELOG.md) for details)

- Fix a false positive for `Capybara/SpecificMatcher` when `have_css("a")` without attribute. ([@ydah])
- Add new `Capybara/NegationMatcher` cop. ([@ydah])
- Add new `Capybara/SpecificActions` cop. ([@ydah])
- Fix an error for `Capybara/SpecificFinders` with no parentheses. ([@ydah])
- Exclude `have_text` and `have_content` that raise `ArgumentError` with `Capybara/VisibilityMatcher` where `:visible` is an invalid option. ([@ydah])
- Fix a false negative for `Capybara/VisibilityMatcher` with negative matchers. ([@ydah])
- Fix a false positive for `Capybara/SpecificMatcher`. ([@ydah])
- Fix a false negative for `Capybara/SpecificMatcher` for `have_field`. ([@ydah])
- Fix a false positive for `Capybara/SpecificMatcher` when may not have a `href` by `have_link`. ([@ydah])
- Add new `Capybara/SpecificFinders` cop. ([@ydah])
- Fix a false positive for `Capybara/SpecificMatcher` when pseudo-classes. ([@ydah])
- Fix a false positive for `Capybara/SpecificMatcher`. ([@ydah])
- Add new `Capybara/SpecificMatcher` cop. ([@ydah])
- Fix `Capybara/CurrentPathExpectation` autocorrect incompatible with `Style/TrailingCommaInArguments` autocorrect. ([@ydah])
- Fix `FactoryBot/SyntaxMethods` and `Capybara/FeatureMethods` to inspect shared groups. ([@pirj])
- Change namespace of several cops (`Capybara/*` -> `RSpec/Capybara/*`, `FactoryBot/*` -> `RSpec/FactoryBot/*`, `Rails/*` -> `RSpec/Rails/*`). ([@pirj], [@bquorning])
- Expand `Capybara/VisibilityMatcher` to support more than just `have_selector`. ([@twalpole])
- Add new `Capybara/VisibilityMatcher` cop. ([@aried3r])
- Fix `Capybara/CurrentPathExpectation` auto-corrector, to include option `ignore_query: true`. ([@onumis])
- Add autocorrect support for `Capybara/CurrentPathExpectation` cop. ([@ypresto])
- Fix `Capybara/FeatureMethods` not working when there is require before the spec. ([@Darhazer])
- Fix false positives in `Capybara/FeatureMethods` when feature methods are used as property names in a factory. ([@Darhazer])
- Allow configuring enabled methods in `Capybara/FeatureMethods`. ([@Darhazer])
- Fix false positive in `Capybara/FeatureMethods`. ([@Darhazer])
- Add `Capybara/CurrentPathExpectation` cop for feature specs, disallowing setting expectations on `current_path`. ([@timrogers])
- Add `RSpec/Capybara` namespace including the first cop for feature specs: `Capybara/FeatureMethods`. ([@rspeicher])

<!-- Contributors (alphabetically) -->

[@aried3r]: https://github.com/aried3r
[@bquorning]: https://github.com/bquorning
[@darhazer]: https://github.com/Darhazer
[@onumis]: https://github.com/onumis
[@oskarsezerins]: https://github.com/OskarsEzerins
[@pirj]: https://github.com/pirj
[@rspeicher]: https://github.com/rspeicher
[@timrogers]: https://github.com/timrogers
[@twalpole]: https://github.com/twalpole
[@ydah]: https://github.com/ydah
[@ypresto]: https://github.com/ypresto
