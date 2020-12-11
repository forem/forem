Feature: `pending` examples

  RSpec offers a number of different ways to indicate that an example is
  disabled pending some action.

  Scenario: `pending` any arbitrary reason with a failing example
    Given a file named "pending_without_block_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        it "is implemented but waiting" do
          pending("something else getting finished")
          fail
        end
      end
      """
    When I run `rspec pending_without_block_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) an example is implemented but waiting
           # something else getting finished
      """

  Scenario: `pending` any arbitrary reason with a passing example
    Given a file named "pending_with_passing_example_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        it "is implemented but waiting" do
          pending("something else getting finished")
          expect(1).to be(1)
        end
      end
      """
    When I run `rspec pending_with_passing_example_spec.rb`
    Then the exit status should not be 0
    And the output should contain "1 example, 1 failure"
    And the output should contain "FIXED"
    And the output should contain "Expected pending 'something else getting finished' to fail. No error was raised."
    And the output should contain "pending_with_passing_example_spec.rb:2"

  Scenario: `pending` for an example that is currently passing
    Given a file named "pending_with_passing_block_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        pending("something else getting finished") do
          expect(1).to eq(1)
        end
      end
      """
    When I run `rspec pending_with_passing_block_spec.rb`
    Then the exit status should not be 0
    And the output should contain "1 example, 1 failure"
    And the output should contain "FIXED"
    And the output should contain "Expected pending 'No reason given' to fail. No error was raised."
    And the output should contain "pending_with_passing_block_spec.rb:2"

  Scenario: `pending` for an example that is currently passing with a reason
    Given a file named "pending_with_passing_block_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        example("something else getting finished", :pending => 'unimplemented') do
          expect(1).to eq(1)
        end
      end
      """
    When I run `rspec pending_with_passing_block_spec.rb`
    Then the exit status should not be 0
    And the output should contain "1 example, 1 failure"
    And the output should contain "FIXED"
    And the output should contain "Expected pending 'unimplemented' to fail. No error was raised."
    And the output should contain "pending_with_passing_block_spec.rb:2"
