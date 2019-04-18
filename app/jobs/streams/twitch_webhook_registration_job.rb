module Streams
  class TwitchWebhookRegistrationJob < ApplicationJob
    def perform(twitch_user_login)
      client = Streams::TwitchCredentials.generate_client

      user_resp = client.get("users", login: twitch_user_login)
      twitch_user_id = user_resp.body["data"].first["id"]

      client.post(
        "webhooks/hub",
        "hub.callback" => twitch_stream_updates_url,
        "hub.mode" => "subscribe",
        "hub.lease_seconds" => 300,
        "hub.topic" => "https://api.twitch.tv/helix/streams?user_id=#{twitch_user_id}",
      )

      # revoke_token(temp_access_token)
      # Docs say this should work for an app token but I keep getting a 400
      # prob means we need to manage the tokens more statefully
    end

    private

    def twitch_stream_updates_url
      Rails.application.routes.url_helpers.twitch_stream_updates_url(host: ApplicationConfig["APP_DOMAIN"])
    end
  end
end
