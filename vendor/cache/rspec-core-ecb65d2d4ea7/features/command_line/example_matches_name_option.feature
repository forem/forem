Feature: `--example-matches` option

  Use the `--example-matches` (or `-E`) option to filter examples by name using REGEX.

  The argument is matched against the full description of the example, which is
  the concatenation of descriptions of the group (including any nested groups)
  and the example.

  This allows you to run a single uniquely named example, all examples with
  similar names, all the examples in a uniquely named group, etc, etc.

  You can also use the option more than once to specify multiple example
  matches.

  Note: description-less examples that have generated descriptions (typical when using the [one-liner syntax](../subject/one-liner-syntax)) cannot be directly filtered with this option, because it is necessary to execute the example to generate the description, so RSpec is unable to use the not-yet-generated description to decide whether or not to execute an example. You can, of course, pass part of a group's description to select all examples defined in the group (including those that have no description).

  Background:
    Given a file named "first_spec.rb" with:
      """ruby
      RSpec.describe "first group" do
        it "first" do; end
        it "first example in first group" do; end
        it "second example in first group" do; end
      end
      """
    And a file named "second_spec.rb" with:
      """ruby
      RSpec.describe "second group" do
        it "first example in second group" do; end
        it "second example in second group" do; end
      end
      """
    And a file named "third_spec.rb" with:
      """ruby
      RSpec.describe "third group" do
        it "first example in third group" do; end
        context "group of nest" do
          it "first example in nested group" do; end
          it "second example in nested group" do; end
          it "third example in nested_group with underscore" do; end
        end
      end
      """
    And a file named "fourth_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "#length" do
          it "is the number of items" do
            expect(Array.new([1,2,3]).length).to eq 3
          end
        end
      end
      """

  Scenario: No matches
    When I run `rspec . --example-matches nothing_like_this`
    Then the process should succeed even though no examples were run

  Scenario: Match on one word
    When I run `rspec . --example-matches example`
    Then the examples should all pass

  Scenario: One match in each context
    When I run `rspec . --example-matches 'first example'`
    Then the examples should all pass

  Scenario: One match in one file using just the example name
    When I run `rspec . --example-matches 'first example in first group'`
    Then the examples should all pass

  Scenario: One match in one file using the example name and the group name
    When I run `rspec . --example-matches 'first group first example in first group'`
    Then the examples should all pass

  Scenario: All examples in one group
    When I run `rspec . --example-matches 'first group'`
    Then the examples should all pass

  Scenario: One match in one file with group name
    When I run `rspec . --example-matches 'second group first example'`
    Then the examples should all pass

  Scenario: All examples in one group including examples in nested groups
    When I run `rspec . --example-matches 'third group'`
    Then the examples should all pass

  Scenario: Match using `ClassName#method_name` form
    When I run `rspec . --example-matches 'Array#length'`
    Then the examples should all pass

  Scenario: Match only matching regex
    When I run `rspec . --example-matches "first$" --format d`
    Then the examples should all pass
    And the output should contain all of these:
      | first |
    And the output should not contain any of these:
      | first example in first group                |
      | second example in first group               |
      | first example in second group               |
      | second example in second group              |
      | first example in third group                |
      | nested group first example in nested group  |
      | nested group second example in nested group |

  # https://regex101.com/r/RABd8Q/2
  Scenario: Match only matching regex with word boundarries
    When I run `rspec . --example-matches "nested[^_]" --format d`
    Then the examples should all pass
    And the output should contain all of these:
      | first example in nested group  |
      | second example in nested group |
    And the output should not contain any of these:
      | first example in first group   |
      | second example in first group  |
      | first example in second group  |
      | second example in second group |
      | first example in third group   |
      | third example in nested_group  |

  Scenario: Multiple applications of example name option
    When I run `rspec . --example-matches 'first group' --example-matches 'second group' --format d`
    Then the examples should all pass
    And the output should contain all of these:
      | first example in first group   |
      | second example in first group  |
      | first example in second group  |
      | second example in second group |
    And the output should not contain any of these:
      | first example in third group                |
      | nested group first example in nested group  |
      | nested group second example in nested group |
