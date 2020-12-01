Feature: Returning a value

  Use `and_return` to specify a return value. Pass `and_return` multiple values to specify
  different return values for consecutive calls. The final value will continue to be returned if
  the message is received additional times.

  Scenario: Nil is returned by default
    Given a file named "returns_nil_spec.rb" with:
      """ruby
      RSpec.describe "The default response" do
        it "returns nil when no response has been configured" do
          dbl = double
          allow(dbl).to receive(:foo)
          expect(dbl.foo).to be_nil
        end
      end
      """
     When I run `rspec returns_nil_spec.rb`
     Then the examples should all pass

  Scenario: Specify a return value
    Given a file named "and_return_spec.rb" with:
      """ruby
      RSpec.describe "Specifying a return value" do
        it "returns the specified return value" do
          dbl = double
          allow(dbl).to receive(:foo).and_return(14)
          expect(dbl.foo).to eq(14)
        end
      end
      """
     When I run `rspec and_return_spec.rb`
     Then the examples should all pass

  Scenario: Specify different return values for multiple calls
    Given a file named "multiple_calls_spec.rb" with:
      """ruby
      RSpec.describe "When the method is called multiple times" do
        it "returns the specified values in order, then keeps returning the last value" do
          dbl = double
          allow(dbl).to receive(:foo).and_return(1, 2, 3)

          expect(dbl.foo).to eq(1)
          expect(dbl.foo).to eq(2)
          expect(dbl.foo).to eq(3)
          expect(dbl.foo).to eq(3)
          expect(dbl.foo).to eq(3)
        end
      end
      """
     When I run `rspec multiple_calls_spec.rb`
     Then the examples should all pass
