require "rails_helper"

describe Rack::Attack, type: :request, throttle: true do
  before do
    redis_url = "redis://localhost:6379"
    cache_db = ActiveSupport::Cache::RedisStore.new(redis_url)
    allow(Rails).to receive(:cache) { cache_db }
    cache_db.data.flushdb
    allow(Honeycomb).to receive(:add_field)
  end

  describe "search_throttle" do
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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(11).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
      end
    end
  end

  describe "api_throttle" do
    it "throttles api get endpoints based on IP" do
      Timecop.freeze do
        valid_responses = Array.new(3).map do
          get api_articles_path, headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        throttled_response = get api_articles_path, headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        new_ip_response = get api_articles_path, headers: { "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" }

        valid_responses.each { |r| expect(r).not_to eq(429) }
        expect(throttled_response).to eq(429)
        expect(new_ip_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(7).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
      end
    end
  end

  describe "api_write_throttle" do
    let(:api_secret) { create(:api_secret) }
    let(:another_api_secret) { create(:api_secret) }

    it "throttles api write endpoints based on api-key" do
      headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
      dif_headers = { "api-key" => another_api_secret.secret, "content-type" => "application/json" }
      params = { body_markdown: "", title: Faker::Book.title }

      Timecop.freeze do
        valid_response = post api_articles_path, params: { article: params }.to_json, headers: headers
        throttled_response = post api_articles_path, params: { article: params }.to_json, headers: headers
        new_api_response = post api_articles_path, params: { article: params }.to_json, headers: dif_headers

        expect(valid_response).not_to eq(429)
        expect(throttled_response).to eq(429)
        expect(new_api_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("user_api_key", api_secret.secret).exactly(2).times
        expect(Honeycomb).to have_received(:add_field).with("user_api_key", another_api_secret.secret)
      end
    end
  end

  describe "message_throttle" do
    let(:user) { create(:user) }
    let(:chat_channel) { create(:chat_channel) }
    let(:new_message) do
      {
        message_markdown: "hi",
        user_id: user.id,
        temp_id: "sd78jdssd",
        chat_channel_id: chat_channel.id
      }
    end

    before do
      allow(Pusher).to receive(:trigger).and_return(true)
      sign_in user
    end

    it "throttles creating messages" do
      headers = { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
      dif_headers = { "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" }

      Timecop.freeze do
        valid_responses = Array.new(2).map do
          post messages_path, params: { message: new_message }, headers: headers
        end
        throttled_response = post messages_path, params: { message: new_message }, headers: headers
        new_api_response = post messages_path, params: { message: new_message }, headers: dif_headers

        valid_responses.each { |r| expect(r).not_to eq(429) }
        expect(throttled_response).to eq(429)
        expect(new_api_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(6).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
      end
    end
  end
end
