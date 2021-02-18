Feature: `be_within` matcher

  Normal equality expectations do not work well for floating point values.
  Consider this irb session:

      > radius = 3
        => 3
      > area_of_circle = radius * radius * Math::PI
        => 28.2743338823081
      > area_of_circle == 28.2743338823081
        => false

  Instead, you should use the `be_within` matcher to check that the value is within a delta of
  your expected value:

    ```ruby
    expect(area_of_circle).to be_within(0.1).of(28.3)
    ```

  Note that the difference between the actual and expected values must be smaller than your
  delta; if it is equal, the matcher will fail.

  Scenario: basic usage
    Given a file named "be_within_matcher_spec.rb" with:
      """ruby
      RSpec.describe 27.5 do
        it { is_expected.to be_within(0.5).of(27.9) }
        it { is_expected.to be_within(0.5).of(28.0) }
        it { is_expected.to be_within(0.5).of(27.1) }
        it { is_expected.to be_within(0.5).of(27.0) }

        it { is_expected.not_to be_within(0.5).of(28.1) }
        it { is_expected.not_to be_within(0.5).of(26.9) }

        # deliberate failures
        it { is_expected.not_to be_within(0.5).of(28) }
        it { is_expected.not_to be_within(0.5).of(27) }
        it { is_expected.to be_within(0.5).of(28.1) }
        it { is_expected.to be_within(0.5).of(26.9) }
      end
      """
    When I run `rspec be_within_matcher_spec.rb`
    Then the output should contain all of these:
      | 10 examples, 4 failures                     |
      | expected 27.5 not to be within 0.5 of 28   |
      | expected 27.5 not to be within 0.5 of 27   |
      | expected 27.5 to be within 0.5 of 28.1     |
      | expected 27.5 to be within 0.5 of 26.9     |
