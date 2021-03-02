require "rails_helper"

class TestService
  def call(*); end
end

RSpec.describe ThrottledCall do
  let(:redis_cache) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }
  let(:service) { TestService.new }

  before do
    allow(Rails).to receive(:cache).and_return(redis_cache)
    allow(service).to receive(:call)
  end

  after { Rails.cache.clear }

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
