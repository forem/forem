require 'rspec/support/spec/in_sub_process'
main = self

RSpec.describe "Loading rspec/mocks/standalone" do
  include RSpec::Support::InSubProcess

  it "exposes the RSpec::Mocks API on `main`" do
    in_sub_process do
      require 'rspec/mocks/standalone'
      main.instance_eval do
        dbl = double
        expect(dbl).to receive(:foo)
        dbl.foo
        RSpec::Mocks.verify
        RSpec::Mocks.teardown
      end
    end
  end

  it "does not infect other objects with the RSpec::Mocks API" do
    in_sub_process do
      require 'rspec/mocks/standalone'
      object = Object.new
      expect(object).not_to respond_to(:double, :expect)
    end
  end
end
