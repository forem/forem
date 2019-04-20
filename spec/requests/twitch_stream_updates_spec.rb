require "rails_helper"

RSpec.describe "TwitchStramUpdates", type: :request do
  let(:user) { create(:user, twitch_username: "my-twtich-username", currently_streaming_on: currently_streaming_on) }
  let(:currently_streaming_on) { nil }

  describe "GET /users/:user_id/twitch_stream_updates" do
    context "when the subscription was successfull" do
      let(:challenge) { "FAKE_CHALLENGE" }
      let(:twitch_webhook_subscription_params) do
        {
          "hub.mode" => "subscribe",
          "hub.topic" => "SOME_TOPIC_URL",
          "hub.lease_seconds" => "864000",
          "hub.challenge" => challenge
        }
      end

      it "returns the challenge" do
        get "/users/#{user.id}/twitch_stream_updates", params: twitch_webhook_subscription_params

        expect(response.body).to eq challenge
      end
    end

    context "when the subscription is denied" do
      let(:twitch_webhook_subscription_params) do
        {
          "hub.mode" => "denied",
          "hub.topic" => "SOME_TOPIC_URL",
          "hub.reason" => "unauthorized"
        }
      end

      it "returns a 204" do
        get "/users/#{user.id}/twitch_stream_updates", params: twitch_webhook_subscription_params

        expect(response.status).to eq 204
      end
    end
  end

  describe "POST /users/:user_id/twitch_stream_updates" do
    context "when the user was not streaming and starts streaming" do
      let(:currently_streaming_on) { nil }

      let(:twitch_webhook_params) do
        {
          data: [{
            id: "0123456789",
            user_id: "5678",
            user_name: "wjdtkdqhs",
            game_id: "21779",
            community_ids: [],
            type: "live",
            title: "Best Stream Ever",
            viewer_count: 417,
            started_at: "2017-12-01T10:09:45Z",
            language: "en",
            thumbnail_url: "https://link/to/thumbnail.jpg"
          }]
        }
      end

      it "updates the Users twitch streaming status" do
        expect { post "/users/#{user.id}/twitch_stream_updates", params: twitch_webhook_params }.
          to change { user.reload.currently_streaming? }.from(false).to(true).
          and change { user.reload.currently_streaming_on_twitch? }.from(false).to(true)
      end
    end

    context "when the user was streaming and stops" do
      let(:currently_streaming_on) { :twitch }

      let(:twitch_webhook_params) do
        {
          data: []
        }
      end

      it "updates the Users twitch streaming status" do
        expect { post "/users/#{user.id}/twitch_stream_updates", params: twitch_webhook_params }.
          to change { user.reload.currently_streaming? }.from(true).to(false).
          and change { user.reload.currently_streaming_on_twitch? }.from(true).to(false)
      end
    end
  end
end
