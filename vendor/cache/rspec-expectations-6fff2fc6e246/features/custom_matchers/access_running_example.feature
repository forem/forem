Feature: access running example

  In the context of a custom matcher, you can call helper methods that are available from the
  current example's example group. This is used, for example, by rspec-rails in order to wrap
  rails' built-in assertions (which depend on helper methods available in the test context).

  Scenario: call method defined on example from matcher
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec::Matchers.define :bar do
        match do |_|
          foo == "foo"
        end
      end

      RSpec.describe "something" do
        def foo
          "foo"
        end

        it "does something" do
          expect("foo").to bar
        end
      end
      """
    When I run `rspec ./example_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: call method _not_ defined on example from matcher
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec::Matchers.define :bar do
        match do |_|
          foo == "foo"
        end
      end

      RSpec.describe "something" do
        it "does something" do
          expect("foo").to bar
        end
      end
      """
    When I run `rspec ./example_spec.rb`
    Then the output should contain "1 example, 1 failure"
    And the output should match /undefined.*method/
    And the output should contain "RSpec::Matchers::DSL::Matcher"
    And the output should not contain "ExampleGroup"
