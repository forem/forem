require "rails_helper"

RSpec.describe "Rack::Attack AI Chats Throttling", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    # Enable Rack::Attack for this spec
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    Rails.cache.clear
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "ai_chats_throttle" do
    let(:user) { create(:user) }
    let(:headers) { { "REMOTE_ADDR" => "1.2.3.4" } }

    before do
      sign_in user
      stub_const("AI_AVAILABLE", true)
    end

    it "throttles POST requests to /ai_chats to 10 per minute per IP" do
      # Make 10 successful requests
      10.times do
        post "/ai_chats", params: { message: "hello", chat_context: "editor" }, headers: headers
        expect(response).not_to have_http_status(:too_many_requests)
      end

      # The 11th request should be throttled
      post "/ai_chats", params: { message: "hello", chat_context: "editor" }, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Retry later")

      # Advance time to allow requests again
      travel 1.minute + 1.second do
        post "/ai_chats", params: { message: "hello", chat_context: "editor" }, headers: headers
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end

    it "does not throttle GET requests to /ai_chats" do
      10.times do
        get "/ai_chats", headers: headers
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
