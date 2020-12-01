require 'rspec/support/mutex'

RSpec.describe RSpec::Support::Mutex do
  it "allows ::Mutex to be mocked", :if => defined?(::Mutex) do
    expect(Mutex).to receive(:new)
    ::Mutex.new
  end
end
