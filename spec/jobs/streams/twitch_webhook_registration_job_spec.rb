require "rails_helper"

RSpec.describe Streams::TwitchWebhookRegistrationJob, type: :job do
  let(:user) { create(:user, twitch_username: "test-username") }

  let(:expected_headers) { {} }
  let(:expected_twitch_webhook_params) do
    {
      "hub.callback" => "http://#{ApplicationConfig['APP_DOMAIN']}/users/#{user.id}/twitch_stream_updates",
      "hub.mode" => "subscribe",
      "hub.lease_seconds" => 300,
      "hub.topic" => "https://api.twitch.tv/helix/streams?user_id=654321"
    }
  end
  let!(:twitch_webhook_registration_stubbed_route) do
    stub_request(:post, "https://api.twitch.tv/helix/webhooks/hub").
      with(body: expected_twitch_webhook_params, headers: expected_headers).
      and_return(status: 204)
  end

  let(:expected_twitch_user_params) { { login: "test-username" } }
  let!(:twitch_user_stubbed_route) do
    stub_request(:get, "https://api.twitch.tv/helix/users").
      with(query: expected_twitch_user_params, headers: expected_headers).
      and_return(body: { data: [{ id: 654_321 }] }.to_json)
  end

  context "when the user does NOT have a twitch username present" do
    let(:user) { create(:user) }

    it "noops" do
      described_class.perform_now(user)

      expect(twitch_webhook_registration_stubbed_route).not_to have_been_requested
      expect(twitch_user_stubbed_route).not_to have_been_requested
    end
  end

  context "when there is already a token in the cache" do
    let(:expected_headers) do
      { "Authorization" => "Bearer FAKE_CACHED_TWITCH_TOKEN" }
    end

    it "uses the token in the cache and registers for webhooks" do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
      Rails.cache.write(Streams::TwitchCredentials::ACCESS_TOKEN_CACHE_KEY, "FAKE_CACHED_TWITCH_TOKEN")

      described_class.perform_now(user)

      expect(twitch_webhook_registration_stubbed_route).to have_been_requested
      expect(twitch_user_stubbed_route).to have_been_requested
    end
  end

  context "when there is not a token in the cache" do
    let(:expected_headers) do
      { "Authorization" => "Bearer FAKE_BRAND_NEW_TWITCH_TOKEN" }
    end

    let(:expected_twitch_token_body) do
      {
        client_id: "FAKE_TWITCH_CLIENT_ID",
        client_secret: "FAKE_TWITCH_CLIENT_SECRET",
        grant_type: "client_credentials"
      }
    end
    let!(:twitch_token_stubbed_route) do
      stub_request(:post, "https://id.twitch.tv/oauth2/token").
        with(body: expected_twitch_token_body).
        and_return(body: { access_token: "FAKE_BRAND_NEW_TWITCH_TOKEN" }.to_json)
    end

    it "gets a new token and caches it" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TWITCH_CLIENT_ID").and_return("FAKE_TWITCH_CLIENT_ID")
      allow(ApplicationConfig).to receive(:[]).with("TWITCH_CLIENT_SECRET").and_return("FAKE_TWITCH_CLIENT_SECRET")
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache.lookup_store(:memory_store))

      described_class.perform_now(user)

      expect(twitch_webhook_registration_stubbed_route).to have_been_requested
      expect(twitch_user_stubbed_route).to have_been_requested
      expect(twitch_token_stubbed_route).to have_been_requested

      expect(Rails.cache.fetch(Streams::TwitchCredentials::ACCESS_TOKEN_CACHE_KEY)).to eq "FAKE_BRAND_NEW_TWITCH_TOKEN"
    end
  end
end
