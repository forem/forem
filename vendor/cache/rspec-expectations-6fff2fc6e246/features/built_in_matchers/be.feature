Feature: `be` matchers

  There are several related "be" matchers:

    ```ruby
    expect(obj).to be_truthy  # passes if obj is truthy (not nil or false)
    expect(obj).to be_falsey  # passes if obj is falsy (nil or false)
    expect(obj).to be_nil     # passes if obj is nil
    expect(obj).to be         # passes if obj is truthy (not nil or false)
    ```

  Scenario: be_truthy matcher
    Given a file named "be_truthy_spec.rb" with:
      """ruby
      RSpec.describe "be_truthy matcher" do
        specify { expect(true).to be_truthy }
        specify { expect(7).to be_truthy }
        specify { expect("foo").to be_truthy }
        specify { expect(nil).not_to be_truthy }
        specify { expect(false).not_to be_truthy }

        # deliberate failures
        specify { expect(true).not_to be_truthy }
        specify { expect(7).not_to be_truthy }
        specify { expect("foo").not_to be_truthy }
        specify { expect(nil).to be_truthy }
        specify { expect(false).to be_truthy }
      end
      """
    When I run `rspec be_truthy_spec.rb`
    Then the output should contain "10 examples, 5 failures"
    And the output should contain:
      """
             expected: falsey value
                  got: true
      """
    And the output should contain:
      """
             expected: falsey value
                  got: 7
      """
    And the output should contain:
      """
             expected: falsey value
                  got: "foo"
      """
    And the output should contain:
      """
             expected: truthy value
                  got: nil
      """
    And the output should contain:
      """
             expected: truthy value
                  got: false
      """

  Scenario: be_falsey matcher
    Given a file named "be_falsey_spec.rb" with:
      """ruby
      RSpec.describe "be_falsey matcher" do
        specify { expect(nil).to be_falsey }
        specify { expect(false).to be_falsey }
        specify { expect(true).not_to be_falsey }
        specify { expect(7).not_to be_falsey }
        specify { expect("foo").not_to be_falsey }

        # deliberate failures
        specify { expect(nil).not_to be_falsey }
        specify { expect(false).not_to be_falsey }
        specify { expect(true).to be_falsey }
        specify { expect(7).to be_falsey }
        specify { expect("foo").to be_falsey }
      end
      """
    When I run `rspec be_falsey_spec.rb`
    Then the output should contain "10 examples, 5 failures"
    And the output should contain:
      """
             expected: truthy value
                  got: nil
      """
    And the output should contain:
      """
             expected: truthy value
                  got: false
      """
    And the output should contain:
      """
             expected: falsey value
                  got: true
      """
    And the output should contain:
      """
             expected: falsey value
                  got: 7
      """
    And the output should contain:
      """
             expected: falsey value
                  got: "foo"
      """

  Scenario: be_nil matcher
    Given a file named "be_nil_spec.rb" with:
      """ruby
      RSpec.describe "be_nil matcher" do
        specify { expect(nil).to be_nil }
        specify { expect(false).not_to be_nil }
        specify { expect(true).not_to be_nil }
        specify { expect(7).not_to be_nil }
        specify { expect("foo").not_to be_nil }

        # deliberate failures
        specify { expect(nil).not_to be_nil }
        specify { expect(false).to be_nil }
        specify { expect(true).to be_nil }
        specify { expect(7).to be_nil }
        specify { expect("foo").to be_nil }
      end
      """
    When I run `rspec be_nil_spec.rb`
    Then the output should contain "10 examples, 5 failures"
    And the output should contain:
      """
             expected: not nil
                  got: nil
      """
    And the output should contain:
      """
             expected: nil
                  got: false
      """
    And the output should contain:
      """
             expected: nil
                  got: true
      """
    And the output should contain:
      """
             expected: nil
                  got: 7
      """
    And the output should contain:
      """
             expected: nil
                  got: "foo"
      """

  Scenario: be matcher
    Given a file named "be_spec.rb" with:
      """ruby
      RSpec.describe "be_matcher" do
        specify { expect(true).to be }
        specify { expect(7).to be }
        specify { expect("foo").to be }
        specify { expect(nil).not_to be }
        specify { expect(false).not_to be }

        # deliberate failures
        specify { expect(true).not_to be }
        specify { expect(7).not_to be }
        specify { expect("foo").not_to be }
        specify { expect(nil).to be }
        specify { expect(false).to be }
      end
      """
    When I run `rspec be_spec.rb`
    Then the output should contain all of these:
      | 10 examples, 5 failures             |
      | expected true to evaluate to false  |
      | expected 7 to evaluate to false     |
      | expected "foo" to evaluate to false |
      | expected nil to evaluate to true    |
      | expected false to evaluate to true  |
