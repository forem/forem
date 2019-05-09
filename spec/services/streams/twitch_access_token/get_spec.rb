require "rails_helper"

RSpec.describe Streams::TwitchAccessToken::Get, type: :service do
  describe ".access_token" do
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
        and_return(body: { access_token: "FAKE_BRAND_NEW_TWITCH_TOKEN", expires_in: 5_184_000 }.to_json, headers: { "Content-Type" => "application/json" })
    end

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TWITCH_CLIENT_ID").and_return("FAKE_TWITCH_CLIENT_ID")
      allow(ApplicationConfig).to receive(:[]).with("TWITCH_CLIENT_SECRET").and_return("FAKE_TWITCH_CLIENT_SECRET")
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
    end

    context "when there is an unexpired token in the cache" do
      it "returns the cached token" do
        Rails.cache.write(described_class::ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY, ["FAKE_UNEXPIRED_TWITCH_TOKEN", 15.days.from_now])

        expect(described_class.call).to eq "FAKE_UNEXPIRED_TWITCH_TOKEN"
        expect(twitch_token_stubbed_route).not_to have_been_requested
      end
    end

    context "when there is an expired token in the cache" do
      it "requests a new token and caches it" do
        Rails.cache.write(described_class::ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY, ["FAKE_EXPIRED_TWITCH_TOKEN", 15.days.ago])

        expect(described_class.call).to eq "FAKE_BRAND_NEW_TWITCH_TOKEN"
        expect(twitch_token_stubbed_route).to have_been_requested
      end
    end

    context "when the token is not in the cache" do
      it "requests a new token and caches it" do
        expect(described_class.call).to eq "FAKE_BRAND_NEW_TWITCH_TOKEN"
        expect(twitch_token_stubbed_route).to have_been_requested
      end
    end
  end
end
