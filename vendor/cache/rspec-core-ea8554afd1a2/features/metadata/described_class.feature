Feature: described class

  If the first argument to an example group is a class, the class is exposed to
  each example in that example group via the `described_class()` method.

  Scenario: Access the described class from the example
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe Fixnum do
        describe 'inner' do
          describe String do
            it "is available as described_class" do
              expect(described_class).to eq(String)
            end
          end
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the example should pass
