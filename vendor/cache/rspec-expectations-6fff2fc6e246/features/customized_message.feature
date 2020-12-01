Feature: customized message

  RSpec tries to provide useful failure messages, but for cases in which you want more
  specific information, you can define your own message right in the example.This works for
  any matcher _other than the operator matchers_.

  Scenario: customize failure message
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe Array do
        context "when created with `new`" do
          it "is empty" do
            array = Array.new
            array << 1 # trigger a failure to demonstrate the message
            expect(array).to be_empty, "expected empty array, got #{array.inspect}"
          end
        end
      end

      """
    When I run `rspec example_spec.rb --format documentation`
    Then the output should contain "expected empty array, got [1]"

  Scenario: customize failure message with a proc
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe Array do
        context "when created with `new`" do
          it "is empty" do
            array = Array.new
            array << 1 # trigger a failure to demonstrate the message
            expect(array).to be_empty, lambda { "expected empty array, got #{array.inspect}" }
          end
        end
      end

      """
    When I run `rspec example_spec.rb --format documentation`
    Then the output should contain "expected empty array, got [1]"
