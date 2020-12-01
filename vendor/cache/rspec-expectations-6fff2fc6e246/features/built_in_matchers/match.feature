Feature: `match` matcher

  The `match` matcher calls `#match` on the object, passing if `#match` returns a truthy (not
  `false` or `nil`) value. `Regexp` and `String` both provide a `#match` method.

    ```ruby
    expect("a string").to match(/str/) # passes
    expect("a string").to match(/foo/) # fails
    expect(/foo/).to match("food")     # passes
    expect(/foo/).to match("drinks")   # fails
    ```

  You can also use this matcher to match nested data structures when composing matchers.

  Scenario: string usage
    Given a file named "string_match_spec.rb" with:
      """ruby
      RSpec.describe "a string" do
        it { is_expected.to match(/str/) }
        it { is_expected.not_to match(/foo/) }

        # deliberate failures
        it { is_expected.not_to match(/str/) }
        it { is_expected.to match(/foo/) }
      end
      """
    When I run `rspec string_match_spec.rb`
    Then the output should contain all of these:
      | 4 examples, 2 failures                 |
      | expected "a string" not to match /str/ |
      | expected "a string" to match /foo/     |

  Scenario: regular expression usage
    Given a file named "regexp_match_spec.rb" with:
      """ruby
      RSpec.describe /foo/ do
        it { is_expected.to match("food") }
        it { is_expected.not_to match("drinks") }

        # deliberate failures
        it { is_expected.not_to match("food") }
        it { is_expected.to match("drinks") }
      end
      """
    When I run `rspec regexp_match_spec.rb`
    Then the output should contain all of these:
      | 4 examples, 2 failures             |
      | expected /foo/ not to match "food" |
      | expected /foo/ to match "drinks"   |
