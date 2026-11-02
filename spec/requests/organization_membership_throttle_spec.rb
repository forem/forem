require "rails_helper"

RSpec.describe "Organization membership verification throttle", :throttle do
  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store.clear
    Rack::Attack.cache.store = previous_store
  end

  it "limits writes by source IP without limiting reads or another IP" do
    Timecop.freeze do
      20.times do
        post "/foobar/join", headers: { "REMOTE_ADDR" => "203.0.113.1" }
        expect(response).not_to have_http_status(:too_many_requests)
      end
      patch "/foobar/join", headers: { "REMOTE_ADDR" => "203.0.113.1" }
      expect(response).to have_http_status(:too_many_requests)
      get "/foobar/join", headers: { "REMOTE_ADDR" => "203.0.113.1" }
      expect(response).not_to have_http_status(:too_many_requests)
      post "/foobar/join", headers: { "REMOTE_ADDR" => "203.0.113.2" }
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
