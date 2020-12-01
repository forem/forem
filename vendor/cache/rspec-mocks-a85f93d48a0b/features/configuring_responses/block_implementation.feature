Feature: Block implementation

  When you pass a block, RSpec will use your block as the implementation of the method. Any
  arguments (or a block) provided by the caller will be yielded to your block implementation.
  This feature is extremely flexible, and supports many use cases that are not directly
  supported by the more declaritive fluent interface.

  You can pass a block to any of the fluent interface methods:

    * `allow(dbl).to receive(:foo) { do_something }`
    * `allow(dbl).to receive(:foo).with("args") { do_something }`
    * `allow(dbl).to receive(:foo).once { do_something }`
    * `allow(dbl).to receive(:foo).ordered { do_something }`

  Some of the more common use cases for block implementations are shown below, but this
  is not an exhaustive list.

  Scenario: Use a block to specify a return value with a terser syntax
    Given a file named "return_value_spec.rb" with:
      """ruby
      RSpec.describe "Specifying a return value using a block" do
        it "returns the block's return value" do
          dbl = double
          allow(dbl).to receive(:foo) { 14 }
          expect(dbl.foo).to eq(14)
        end
      end
      """
     When I run `rspec return_value_spec.rb`
     Then the examples should all pass

  Scenario: Use a block to verify arguments
    Given a file named "verify_arguments_spec.rb" with:
      """ruby
      RSpec.describe "Verifying arguments using a block" do
        it "fails when the arguments do not meet the expectations set in the block" do
          dbl = double

          allow(dbl).to receive(:foo) do |arg|
            expect(arg).to eq("bar")
          end

          dbl.foo(nil)
        end
      end
      """
     When I run `rspec verify_arguments_spec.rb`
     Then it should fail with:
      """
      Failure/Error: expect(arg).to eq("bar")
      """

  Scenario: Use a block to perform a calculation
    Given a file named "perform_calculation_spec.rb" with:
      """ruby
      RSpec.describe "Performing a calculation using a block" do
        it "returns the block's return value" do
          loan = double("Loan", :amount => 100)

          allow(loan).to receive(:required_payment_for_rate) do |rate|
            loan.amount * rate
          end

          expect(loan.required_payment_for_rate(0.05)).to eq(5)
          expect(loan.required_payment_for_rate(0.1)).to eq(10)
        end
      end
      """
     When I run `rspec perform_calculation_spec.rb`
     Then the examples should all pass

  Scenario: Yield to the caller's block
    Given a file named "yield_to_caller_spec.rb" with:
      """ruby
      RSpec.describe "When the caller passes a block" do
        it "can be yielded to from your implementation block" do
          dbl = double
          allow(dbl).to receive(:foo) { |&block| block.call(14) }
          expect { |probe| dbl.foo(&probe) }.to yield_with_args(14)
        end
      end
      """
     When I run `rspec yield_to_caller_spec.rb`
     Then the examples should all pass

  Scenario: Delegate to partial double's original implementation within the block
    Given a file named "delegate_to_original_spec.rb" with:
      """ruby
      class Calculator
        def self.add(x, y)
          x + y
        end
      end

      RSpec.describe "When using a block implementation on a partial double" do
        it "supports delegating to the original implementation" do
          original_add = Calculator.method(:add)

          allow(Calculator).to receive(:add) do |x, y|
            original_add.call(x, y) * 2
          end

          expect(Calculator.add(2, 5)).to eq(14)
        end
      end
      """
     When I run `rspec delegate_to_original_spec.rb`
     Then the examples should all pass

  Scenario: Simulating a transient network failure
    Given a file named "simulate_transient_network_failure_spec.rb" with:
      """ruby
      RSpec.describe "An HTTP API client" do
        it "can simulate transient network failures" do
          client = double("MyHTTPClient")

          call_count = 0
          allow(client).to receive(:fetch_data) do
            call_count += 1
            call_count.odd? ? raise("timeout") : { :count => 15 }
          end

          expect { client.fetch_data }.to raise_error("timeout")
          expect(client.fetch_data).to eq(:count => 15)
          expect { client.fetch_data }.to raise_error("timeout")
          expect(client.fetch_data).to eq(:count => 15)
        end
      end
      """
     When I run `rspec simulate_transient_network_failure_spec.rb`
     Then the examples should all pass
