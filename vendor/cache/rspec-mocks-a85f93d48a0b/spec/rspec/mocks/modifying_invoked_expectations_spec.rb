require "spec_helper"

RSpec.describe "Modifying invoked expectations" do
  shared_examples_for "a customization on an invoked expectation" do |customization_method, *args|
    it "raises when the #{customization_method} method is called, indicating the expectation has already been invoked" do
      dbl = double
      msg_expectation = expect(dbl).to receive(:foo)
      expect(dbl.foo).to eq(nil)

      expect {
        msg_expectation.__send__(customization_method, *args)
      }.to raise_error(
        RSpec::Mocks::MockExpectationAlreadyInvokedError,
        a_string_including(dbl.inspect, "foo", customization_method.to_s)
      )
    end
  end

  it_behaves_like "a customization on an invoked expectation", :with, :some_arg
  it_behaves_like "a customization on an invoked expectation", :and_return, 1
  it_behaves_like "a customization on an invoked expectation", :and_raise, "boom"
  it_behaves_like "a customization on an invoked expectation", :and_throw, :symbol
  it_behaves_like "a customization on an invoked expectation", :and_yield, 1
  it_behaves_like "a customization on an invoked expectation", :exactly, :once
  it_behaves_like "a customization on an invoked expectation", :at_least, :once
  it_behaves_like "a customization on an invoked expectation", :at_most, :once
end
