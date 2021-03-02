Feature: Mixed responses

  Use `and_invoke` to invoke a Proc when a message is received. Pass `and_invoke` multiple
  Procs to have different behavior for consecutive calls. The final Proc will continue to be
  called if the message is received additional times.

  Scenario: Mixed responses
    Given a file named "raises_and_then_returns.rb" with:
      """ruby
      RSpec.describe "when the method is called multiple times" do
        it "raises and then later returns a value" do
          dbl = double
          allow(dbl).to receive(:foo).and_invoke(lambda { raise "failure" }, lambda { true })

          expect { dbl.foo }.to raise_error("failure")
          expect(dbl.foo).to eq(true)
        end
      end
      """
     When I run `rspec raises_and_then_returns.rb`
     Then the examples should all pass
