require "rails_helper"

RSpec.describe "Rack::Attack Lead Submissions Throttling", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    Rails.cache.clear
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "lead_submissions_throttle" do
    let(:headers) { { "REMOTE_ADDR" => "5.6.7.8" } }

    it "throttles POST requests to /lead_submissions to 5 per minute per IP" do
      # Make 5 successful requests
      5.times do
        post "/lead_submissions", params: { name: "Test User", email: "test@example.com" }, headers: headers
        # Even if it returns 422 Unprocessable Entity due to missing form IDs,
        # point is it DOES NOT return 429 Too Many Requests.
        expect(response).not_to have_http_status(:too_many_requests)
      end

      # The 6th request should be throttled
      post "/lead_submissions", params: { name: "Test User", email: "test@example.com" }, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Retry later")

      # Advance time to allow requests again
      travel 1.minute + 1.second do
        post "/lead_submissions", params: { name: "Test User", email: "test@example.com" }, headers: headers
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
