Feature: filter_run_when_matching

  You can configure a _conditional_ filter that only applies if there are any matching
  examples using `config.filter_run_when_matching`. This is commonly used for focus
  filtering:

  ```ruby
  RSpec.configure do |c|
    c.filter_run_when_matching :focus
  end
  ```

  This configuration allows you to filter to specific examples or groups by tagging
  them with `:focus` metadata. When no example or groups are focused (which should be
  the norm since it's intended to be a temporary change), the filter will be ignored.

  RSpec also provides aliases--`fit`, `fdescribe` and `fcontext`--as a shorthand for
  `it`, `describe` and `context` with `:focus` metadata, making it easy to temporarily
  focus an example or group by prefixing an `f`.

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |c|
        c.filter_run_when_matching :focus
      end
      """
    And a file named ".rspec" with:
      """
      --require spec_helper
      """
    And a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "A group" do
        it "has a passing example" do
        end

        context "a nested group" do
          it "also has a passing example" do
          end
        end
      end
      """

  Scenario: The filter is ignored when nothing is focused
    When I run `rspec --format doc`
    Then it should pass with "2 examples, 0 failures"
    And the output should contain:
      """
      A group
        has a passing example
        a nested group
          also has a passing example
      """

  Scenario: Examples can be focused with `fit`
    Given I have changed `it "has a passing example"` to `fit "has a passing example"` in "spec/example_spec.rb"
    When I run `rspec --format doc`
    Then it should pass with "1 example, 0 failures"
    And the output should contain:
      """
      A group
        has a passing example
      """

  Scenario: Groups can be focused with `fdescribe` or `fcontext`
    Given I have changed `context` to `fcontext` in "spec/example_spec.rb"
    When I run `rspec --format doc`
    Then it should pass with "1 example, 0 failures"
    And the output should contain:
      """
      A group
        a nested group
          also has a passing example
      """
