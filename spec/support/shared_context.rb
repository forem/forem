RSpec.shared_context "when proper status" do
  before do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    Rails.application.env_config["action_dispatch.show_exceptions"] = true
  end

  after do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = true
    Rails.application.env_config["action_dispatch.show_exceptions"] = false
  end
end

RSpec.configure do |rspec|
  rspec.include_context "when proper status", proper_status: true
end

RSpec.shared_context "with ThrottledCall" do
  let(:redis_cache) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }

  before do
    allow(Rails).to receive(:cache).and_return(redis_cache)
    allow(ThrottledCall).to receive(:perform).and_call_original
  end

  after { Rails.cache.clear }
end

RSpec.configure do |rspec|
  rspec.include_context "with ThrottledCall", throttled_call: true
end
