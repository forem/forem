Feature: Calling the original implementation

  Use `and_call_original` to make a partial double response as it normally would. This can
  be useful when you want to expect a message without interfering with how it responds. You
  can also use it to configure the default response for most arguments, and then override
  that for specific arguments using `with`.

  Note: `and_call_original` is only supported on partial doubles, as normal test doubles do
  not have an original implementation.

  Background:
    Given a file named "lib/calculator.rb" with:
      """ruby
      class Calculator
        def self.add(x, y)
          x + y
        end
      end
      """

  Scenario: `and_call_original` makes the partial double respond as it normally would
    Given a file named "spec/and_call_original_spec.rb" with:
      """ruby
      require 'calculator'

      RSpec.describe "and_call_original" do
        it "responds as it normally would" do
          expect(Calculator).to receive(:add).and_call_original
          expect(Calculator.add(2, 3)).to eq(5)
        end
      end
      """
    When I run `rspec spec/and_call_original_spec.rb`
    Then the examples should all pass

  Scenario: `and_call_original` can configure a default response that can be overridden for specific args
    Given a file named "spec/and_call_original_spec.rb" with:
      """ruby
      require 'calculator'

      RSpec.describe "and_call_original" do
        it "can be overridden for specific arguments using #with" do
          allow(Calculator).to receive(:add).and_call_original
          allow(Calculator).to receive(:add).with(2, 3).and_return(-5)

          expect(Calculator.add(2, 2)).to eq(4)
          expect(Calculator.add(2, 3)).to eq(-5)
        end
      end
      """
    When I run `rspec spec/and_call_original_spec.rb`
    Then the examples should all pass
