require "rails_helper"

class TestService
  def call(*); end
end

RSpec.describe ThrottledCall, throttled_call: true do
  let(:service) { TestService.new }

  before do
    allow(service).to receive(:call)
  end

  it "calls the block if the call is not currently throttled" do
    described_class.perform(:test, throttle_for: 1.minute) { service.call }

    expect(service).to have_received(:call)
  end

  it "does not call the block if the call is currently throttled" do
    described_class.perform(:test, throttle_for: 1.minute) { service.call }
    described_class.perform(:test, throttle_for: 1.minute) { service.call }

    expect(service).to have_received(:call).once
  end
end
