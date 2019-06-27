require "rails_helper"

RSpec.describe Streams::TwitchWebhook::Register, type: :service do
  describe "::call" do
    let(:twitch_access_token_get) { instance_double(Streams::TwitchAccessToken::Get, call: "FAKE_TWITCH_TOKEN") }
    let(:user) { create(:user, twitch_username: "test-username") }

    let(:expected_headers) do
      { "Authorization" => "Bearer FAKE_TWITCH_TOKEN" }
    end
    let(:expected_twitch_webhook_params) do
      {
        "hub.callback" => "http://#{ApplicationConfig['APP_DOMAIN']}/users/#{user.id}/twitch_stream_updates",
        "hub.mode" => "subscribe",
        "hub.lease_seconds" => 604_800,
        "hub.topic" => "https://api.twitch.tv/helix/streams?user_id=654321",
        "hub.secret" => ApplicationConfig["TWITCH_WEBHOOK_SECRET"]
      }
    end

    let(:expected_twitch_user_params) { { login: "test-username" } }

    let!(:twitch_webhook_registration_stubbed_route) do
      stub_request(:post, "https://api.twitch.tv/helix/webhooks/hub").
        with(body: URI.encode_www_form(expected_twitch_webhook_params), headers: expected_headers).
        and_return(status: 204)
    end

    context "when twitch returns data" do
      let!(:twitch_user_stubbed_route) do
        stub_request(:get, "https://api.twitch.tv/helix/users").
          with(query: expected_twitch_user_params, headers: expected_headers).
          and_return(body: { data: [{ id: 654_321 }] }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "registers for webhooks" do
        described_class.call(user, twitch_access_token_get)

        expect(twitch_webhook_registration_stubbed_route).to have_been_requested
        expect(twitch_user_stubbed_route).to have_been_requested
      end
    end

    context "when twitch return no data" do
      let!(:twitch_user_stubbed_route) do
        stub_request(:get, "https://api.twitch.tv/helix/users").
          with(query: expected_twitch_user_params, headers: expected_headers).
          and_return(body: {}.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "doesn't fail when twitch doesn't return data" do
        described_class.call(user, twitch_access_token_get)
        expect(twitch_user_stubbed_route).to have_been_requested
      end

      it "doesn't register for webhooks" do
        described_class.call(user, twitch_access_token_get)
        expect(twitch_webhook_registration_stubbed_route).not_to have_been_requested
      end
    end

    context "when twitch returns empty data" do
      let!(:twitch_user_stubbed_route) do
        stub_request(:get, "https://api.twitch.tv/helix/users").
          with(query: expected_twitch_user_params, headers: expected_headers).
          and_return(body: { "data" => [] }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "doesn't fail" do
        described_class.call(user, twitch_access_token_get)
        expect(twitch_user_stubbed_route).to have_been_requested
      end

      it "doesn't register for webhooks" do
        described_class.call(user, twitch_access_token_get)
        expect(twitch_webhook_registration_stubbed_route).not_to have_been_requested
      end
    end
  end
end
