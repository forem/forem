Feature: Partial test doubles

  A _partial test double_ is an extension of a real object in a system that is instrumented with
  test-double like behaviour in the context of a test. This technique is very common in Ruby
  because we often see class objects acting as global namespaces for methods. For example,
  in Rails:

  ```ruby
  person = double("person")
  allow(Person).to receive(:find) { person }
  ```

  In this case we're instrumenting Person to return the person object we've defined whenever
  it receives the `find` message. We can also set a message expectation so that the example
  fails if `find` is not called:

  ```ruby
  person = double("person")
  expect(Person).to receive(:find) { person }
  ```

  RSpec replaces the method we're stubbing or mocking with its own test-double like method.
  At the end of the example, RSpec verifies any message expectations, and then restores the
  original methods.

  Note: we recommend enabling the [`verify_partial_doubles`](../verifying-doubles/partial-doubles) config option.

  Scenario: Only the specified methods are redefined
    Given a file named "partial_double_spec.rb" with:
      """ruby
      RSpec.describe "A partial double" do
        # Note: stubbing a string like this is a terrible idea.
        #       This is just for demonstration purposes.
        let(:string) { "a string" }
        before { allow(string).to receive(:length).and_return(500) }

        it "redefines the specified methods" do
          expect(string.length).to eq(500)
        end

        it "does not effect other methods" do
          expect(string.reverse).to eq("gnirts a")
        end
      end
      """
     When I run `rspec partial_double_spec.rb`
     Then the examples should all pass

  Scenario: The original method is restored when the example completes
    Given a file named "partial_double_spec.rb" with:
      """ruby
      class User
        def self.find(id)
          :original_return_value
        end
      end

      RSpec.describe "A partial double" do
        it "redefines a method" do
          allow(User).to receive(:find).and_return(:redefined)
          expect(User.find(3)).to eq(:redefined)
        end

        it "restores the redefined method after the example completes" do
          expect(User.find(3)).to eq(:original_return_value)
        end
      end
      """
     When I run `rspec partial_double_spec.rb --order defined`
     Then the examples should all pass
