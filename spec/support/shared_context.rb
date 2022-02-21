RSpec.shared_context "when proper status" do
  around do |example|
    original_show_exceptions = Rails.application.env_config["action_dispatch.show_exceptions"]
    Rails.application.env_config["action_dispatch.show_exceptions"] = true

    example.run

    Rails.application.env_config["action_dispatch.show_exceptions"] = original_show_exceptions
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
