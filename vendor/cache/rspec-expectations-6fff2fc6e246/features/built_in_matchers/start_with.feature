Feature: `start_with` matcher

  Use the `start_with` matcher to specify that a string or array starts with the expected
  characters or elements.

    ```ruby
    expect("this string").to start_with("this")
    expect("this string").not_to start_with("that")
    expect([0,1,2]).to start_with(0, 1)
    ```

  Scenario: with a string
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "this string" do
        it { is_expected.to start_with "this" }
        it { is_expected.not_to start_with "that" }

        # deliberate failures
        it { is_expected.not_to start_with "this" }
        it { is_expected.to start_with "that" }
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain all of these:
      | 4 examples, 2 failures                          |
      | expected "this string" not to start with "this" |
      | expected "this string" to start with "that"     |

  Scenario: with an array
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe [0, 1, 2, 3, 4] do
        it { is_expected.to start_with 0 }
        it { is_expected.to start_with(0, 1)}
        it { is_expected.not_to start_with(2) }
        it { is_expected.not_to start_with(0, 1, 2, 3, 4, 5) }

        # deliberate failures
        it { is_expected.not_to start_with 0 }
        it { is_expected.to start_with 3 }
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain all of these:
      | 6 examples, 2 failures                       |
      | expected [0, 1, 2, 3, 4] not to start with 0 |
      | expected [0, 1, 2, 3, 4] to start with 3     |
