Feature: Comparison matchers

  RSpec provides a number of matchers that are based on Ruby's built-in operators. These
  can be used for generalized comparison of values. E.g.

    ```ruby
    expect(9).to be > 6
    expect(3).to be <= 3
    expect(1).to be < 6
    expect('a').to be < 'b'
    ```

  Scenario: numeric operator matchers
    Given a file named "numeric_operator_matchers_spec.rb" with:
      """ruby
      RSpec.describe 18 do
        it { is_expected.to be < 20 }
        it { is_expected.to be > 15 }
        it { is_expected.to be <= 19 }
        it { is_expected.to be >= 17 }

        # deliberate failures
        it { is_expected.to be < 15 }
        it { is_expected.to be > 20 }
        it { is_expected.to be <= 17 }
        it { is_expected.to be >= 19 }
        it { is_expected.to be < 'a' }
      end

      RSpec.describe 'a' do
        it { is_expected.to be < 'b' }

        # deliberate failures
        it { is_expected.to be < 18 }
      end
      """
     When I run `rspec numeric_operator_matchers_spec.rb`
     Then the output should contain "11 examples, 6 failures"
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be < 15 }

             expected: < 15
                  got:   18
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be > 20 }

             expected: > 20
                  got:   18
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be <= 17 }

             expected: <= 17
                  got:    18
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be >= 19 }

             expected: >= 19
                  got:    18
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be < 'a' }

             expected: < "a"
                  got:   18
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be < 18 }

             expected: < 18
                  got:   "a"
      """


  Scenario: string operator matchers
    Given a file named "string_operator_matchers_spec.rb" with:
      """ruby
      RSpec.describe "Strawberry" do
        it { is_expected.to be < "Tomato" }
        it { is_expected.to be > "Apple" }
        it { is_expected.to be <= "Turnip" }
        it { is_expected.to be >= "Banana" }

        # deliberate failures
        it { is_expected.to be < "Cranberry" }
        it { is_expected.to be > "Zuchini" }
        it { is_expected.to be <= "Potato" }
        it { is_expected.to be >= "Tomato" }
      end
      """
     When I run `rspec string_operator_matchers_spec.rb`
     Then the output should contain "8 examples, 4 failures"
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be < "Cranberry" }

             expected: < "Cranberry"
                  got:   "Strawberry"
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be > "Zuchini" }

             expected: > "Zuchini"
                  got:   "Strawberry"
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be <= "Potato" }

             expected: <= "Potato"
                  got:    "Strawberry"
      """
      And the output should contain:
      """
           Failure/Error: it { is_expected.to be >= "Tomato" }

             expected: >= "Tomato"
                  got:    "Strawberry"
      """
