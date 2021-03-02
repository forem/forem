Feature: arbitrary file suffix

  Scenario: `.spec`
    Given a file named "a.spec" with:
      """ruby
      RSpec.describe "something" do
        it "does something" do
          expect(3).to eq(3)
        end
      end
      """
    When I run `rspec a.spec`
    Then the examples should all pass
