Feature: `--failure-exit-code` option (exit status)

  The `rspec` command exits with an exit status of 0 if all examples pass, and 1
  if any examples fail. The failure exit code can be overridden using the
  `--failure-exit-code` option.

  Scenario: A passing spec with the default exit code
    Given a file named "ok_spec.rb" with:
      """ruby
      RSpec.describe "ok" do
        it "passes" do
        end
      end
      """
    When I run `rspec ok_spec.rb`
    Then the exit status should be 0
    And the examples should all pass

  Scenario: A failing spec with the default exit code
    Given a file named "ko_spec.rb" with:
      """ruby
      RSpec.describe "KO" do
        it "fails" do
          raise "KO"
        end
      end
      """
    When I run `rspec ko_spec.rb`
    Then the exit status should be 1
    And the output should contain "1 example, 1 failure"

  Scenario: A nested failing spec with the default exit code
    Given a file named "nested_ko_spec.rb" with:
      """ruby
      RSpec.describe "KO" do
        describe "nested" do
          it "fails" do
            raise "KO"
          end
        end
      end
      """
    When I run `rspec nested_ko_spec.rb`
    Then the exit status should be 1
    And the output should contain "1 example, 1 failure"

  Scenario: Exit with 0 when no examples are run
    Given a file named "a_no_examples_spec.rb" with:
      """ruby
      """
    When I run `rspec a_no_examples_spec.rb`
    Then the exit status should be 0
    And the output should contain "0 examples"

  Scenario: A failing spec and `--failure-exit-code` is 42
    Given a file named "ko_spec.rb" with:
      """ruby
      RSpec.describe "KO" do
        it "fails" do
          raise "KO"
        end
      end
      """
    When I run `rspec --failure-exit-code 42 ko_spec.rb`
    Then the exit status should be 42
    And the output should contain "1 example, 1 failure"
