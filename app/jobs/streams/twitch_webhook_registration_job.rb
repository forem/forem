module Streams
  class TwitchWebhookRegistrationJob < ApplicationJob
    WEBHOOK_LEASE_SECONDS = 7.days.to_i

    def perform(user)
      return if user.twitch_username.blank?

      client = Streams::TwitchCredentials.generate_client

      user_resp = client.get("users", login: user.twitch_username)
      twitch_user_id = user_resp.body["data"].first["id"]

      client.post(
        "webhooks/hub",
        "hub.callback" => twitch_stream_updates_url_for_user(user),
        "hub.mode" => "subscribe",
        "hub.lease_seconds" => WEBHOOK_LEASE_SECONDS,
        "hub.topic" => "https://api.twitch.tv/helix/streams?user_id=#{twitch_user_id}",
        "hub.secret" => ApplicationConfig["TWITCH_WEBHOOK_SECRET"],
      )
    end

    private

    def twitch_stream_updates_url_for_user(user)
      Rails.application.routes.url_helpers.user_twitch_stream_updates_url(user_id: user.id, host: ApplicationConfig["APP_DOMAIN"])
    end
  end
end
