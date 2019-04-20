require "rails_helper"

RSpec.describe "TwitchStramUpdates", type: :request do
  let(:user) { create(:user, twitch_user_name: "my-twtich-username", currently_streaming_on: currently_streaming_on) }
  let(:currently_streaming_on) { nil }

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
