require "rails_helper"

describe Rack::Attack, type: :request, throttle: true do
  describe "search_throttle" do
    before do
      redis_url = "redis://localhost:6379"
      cache_db = ActiveSupport::Cache::RedisStore.new(redis_url)
      allow(Rails).to receive(:cache) { cache_db }
    end

    it "throttles /search endpoints based on IP" do
      Timecop.freeze do
        allow(Search::User).to receive(:search_documents).and_return({})
        valid_responses = Array.new(5).map do
          get "/search/users", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        throttled_response = get "/search/users", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        new_ip_response = get "/search/users", headers: { "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" }

        valid_responses.each { |r| expect(r).not_to eq(429) }
        expect(throttled_response).to eq(429)
        expect(new_ip_response).not_to eq(429)
      end
    end
  end
end
