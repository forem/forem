Feature: line number appended to file path

  To run one or more examples or groups, you can append the line number to the
  path, e.g.

  ```bash
  $ rspec path/to/example_spec.rb:37
  ```

  Background:
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "outer group" do

        it "first example in outer group" do

        end

        it "second example in outer group" do

        end

        describe "nested group" do

          it "example in nested group" do

          end

        end

      end
      """
    And a file named "example2_spec.rb" with:
      """ruby
      RSpec.describe "yet another group" do
        it "first example in second file" do
        end
        it "second example in second file" do
        end
      end
      """
    And a file named "one_liner_spec.rb" with:
      """ruby
      RSpec.describe 9 do

        it { is_expected.to be > 8 }

        it { is_expected.to be < 10 }

      end
      """

  Scenario: Nested groups - outer group on declaration line
    When I run `rspec example_spec.rb:1 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    And the output should contain "first example in outer group"
    And the output should contain "example in nested group"

  Scenario: Nested groups - outer group inside block before example
    When I run `rspec example_spec.rb:2 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    And the output should contain "first example in outer group"
    And the output should contain "example in nested group"

  Scenario: Nested groups - inner group on declaration line
    When I run `rspec example_spec.rb:11 --format doc`
    Then the examples should all pass
    And the output should contain "example in nested group"
    And the output should not contain "second example in outer group"
    And the output should not contain "first example in outer group"

  Scenario: Nested groups - inner group inside block before example
    When I run `rspec example_spec.rb:12 --format doc`
    Then the examples should all pass
    And the output should contain "example in nested group"
    And the output should not contain "second example in outer group"
    And the output should not contain "first example in outer group"

  Scenario: Two examples - first example on declaration line
    When I run `rspec example_spec.rb:3 --format doc`
    Then the examples should all pass
    And the output should contain "first example in outer group"
    But the output should not contain "second example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Two examples - first example inside block
    When I run `rspec example_spec.rb:4 --format doc`
    Then the examples should all pass
    And the output should contain "first example in outer group"
    But the output should not contain "second example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Two examples - first example on end
    When I run `rspec example_spec.rb:5 --format doc`
    Then the examples should all pass
    And the output should contain "first example in outer group"
    But the output should not contain "second example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Two examples - first example after end but before next example
    When I run `rspec example_spec.rb:6 --format doc`
    Then the examples should all pass
    And the output should contain "first example in outer group"
    But the output should not contain "second example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Two examples - second example on declaration line
    When I run `rspec example_spec.rb:7 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    But the output should not contain "first example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Two examples - second example inside block
    When I run `rspec example_spec.rb:7 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    But the output should not contain "first example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Two examples - second example on end
    When I run `rspec example_spec.rb:7 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    But the output should not contain "first example in outer group"
    And the output should not contain "example in nested group"

  Scenario: Specified multiple times for different files
    When I run `rspec example_spec.rb:7 example2_spec.rb:4 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    And the output should contain "second example in second file"
    But the output should not contain "first example in outer group"
    And the output should not contain "nested group"
    And the output should not contain "first example in second file"

  Scenario: Specified multiple times for the same file with multiple arguments
    When I run `rspec example_spec.rb:7 example_spec.rb:11 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    And the output should contain "nested group"
    But the output should not contain "first example in outer group"
    And the output should not contain "second file"

  Scenario: Specified multiple times for the same file with a single argument
    When I run `rspec example_spec.rb:7:11 --format doc`
    Then the examples should all pass
    And the output should contain "second example in outer group"
    And the output should contain "nested group"
    But the output should not contain "first example in outer group"
    And the output should not contain "second file"

  Scenario: Matching one-liners
    When I run `rspec one_liner_spec.rb:3 --format doc`
    Then the examples should all pass
    Then the output should contain "is expected to be > 8"
    But the output should not contain "is expected to be < 10"
