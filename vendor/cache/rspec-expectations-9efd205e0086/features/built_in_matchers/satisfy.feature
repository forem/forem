Feature: `satisfy` matcher

  The `satisfy` matcher is extremely flexible and can handle almost anything you want to
  specify. It passes if the block you provide returns true:

    ```ruby
    expect(10).to satisfy { |v| v % 5 == 0 }
    expect(7).not_to satisfy { |v| v % 5 == 0 }
    ```

  The default failure message ("expected [actual] to satisfy block") is not very descriptive or helpful.
  To add clarification, you can provide your own description as an argument:

    ```ruby
    expect(10).to satisfy("be a multiple of 5") do |v|
      v % 5 == 0
    end
    ```

  @skip-when-ripper-unsupported
  Scenario: basic usage
    Given a file named "satisfy_matcher_spec.rb" with:
      """ruby
      RSpec.describe 10 do
        it { is_expected.to satisfy { |v| v > 5 } }
        it { is_expected.not_to satisfy { |v| v > 15 } }

        # deliberate failures
        it { is_expected.not_to satisfy { |v| v > 5 } }
        it { is_expected.to satisfy { |v| v > 15 } }
        it { is_expected.to_not satisfy("be greater than 5") { |v| v > 5 } }
        it { is_expected.to satisfy("be greater than 15") { |v| v > 15 } }
      end
      """
    When I run `rspec satisfy_matcher_spec.rb`
    Then the output should contain all of these:
      | 6 examples, 4 failures                        |
      | expected 10 not to satisfy expression `v > 5` |
      | expected 10 to satisfy expression `v > 15`    |
      | expected 10 not to be greater than 5          |
      | expected 10 to be greater than 15             |
