Feature: `skip` examples

  RSpec offers a number of ways to indicate that an example should be skipped
  and not executed.

  Scenario: No implementation provided
    Given a file named "example_without_block_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        it "is a skipped example"
      end
      """
    When I run `rspec example_without_block_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain "Not yet implemented"
    And the output should contain "example_without_block_spec.rb:2"

  Scenario: Skipping using `skip`
    Given a file named "skipped_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        skip "is skipped" do
        end
      end
      """
    When I run `rspec skipped_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) an example is skipped
           # No reason given
           # ./skipped_spec.rb:2
      """

  Scenario: Skipping using `skip` inside an example
    Given a file named "skipped_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        it "is skipped" do
          skip
        end
      end
      """
    When I run `rspec skipped_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) an example is skipped
           # No reason given
           # ./skipped_spec.rb:2
      """

  Scenario: Temporarily skipping by prefixing `it`, `specify`, or `example` with an x
    Given a file named "temporarily_skipped_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        xit "is skipped using xit" do
        end

        xspecify "is skipped using xspecify" do
        end

        xexample "is skipped using xexample" do
        end
      end
      """
    When I run `rspec temporarily_skipped_spec.rb`
    Then the exit status should be 0
    And the output should contain "3 examples, 0 failures, 3 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) an example is skipped using xit
           # Temporarily skipped with xit
           # ./temporarily_skipped_spec.rb:2

        2) an example is skipped using xspecify
           # Temporarily skipped with xspecify
           # ./temporarily_skipped_spec.rb:5

        3) an example is skipped using xexample
           # Temporarily skipped with xexample
           # ./temporarily_skipped_spec.rb:8
      """

  Scenario: Skipping using metadata
    Given a file named "skipped_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        example "is skipped", :skip => true do
        end
      end
      """
    When I run `rspec skipped_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) an example is skipped
           # No reason given
           # ./skipped_spec.rb:2
      """

  Scenario: Skipping using metadata with a reason
    Given a file named "skipped_with_reason_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        example "is skipped", :skip => "waiting for planets to align" do
          raise "this line is never executed"
        end
      end
      """
    When I run `rspec skipped_with_reason_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) an example is skipped
           # waiting for planets to align
           # ./skipped_with_reason_spec.rb:2
      """
