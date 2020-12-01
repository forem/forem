Feature: Hide Undefined Constant

  Hiding a constant that is already undefined is a no-op. This can be useful when a spec file
  may run in either an isolated environment (e.g. when running one spec file) or in a full
  environment with all parts of your code base loaded (e.g. when running your entire suite).

  Scenario: Hiding undefined constant
    Given a file named "hide_const_spec.rb" with:
      """ruby
      RSpec.describe "hiding UNDEFINED_CONSTANT" do
        it "has no effect" do
          hide_const("UNDEFINED_CONSTANT")
          expect { UNDEFINED_CONSTANT }.to raise_error(NameError)
        end

        it "is still undefined after the example completes" do
          expect { UNDEFINED_CONSTANT }.to raise_error(NameError)
        end
      end
      """
    When I run `rspec hide_const_spec.rb`
    Then the examples should all pass
