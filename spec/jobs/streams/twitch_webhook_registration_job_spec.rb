require "rails_helper"

RSpec.describe Streams::TwitchWebhookRegistrationJob, type: :job do
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

  it "registers for webhooks" do
    allow(Streams::TwitchCredentials).to receive(:access_token).and_return("FAKE_TWITCH_TOKEN")

    described_class.perform_now(user)

    expect(twitch_webhook_registration_stubbed_route).to have_been_requested
    expect(twitch_user_stubbed_route).to have_been_requested
  end
end
