module Streams
  class TwitchWebhookRegistrationJob < ApplicationJob
    def perform(twitch_user_login)
      temp_access_token = generate_access_token
      client = twitch_client temp_access_token

      user_resp = client.get("users", login: twitch_user_login)
      twitch_user_id = user_resp.body["data"].first["id"]

      client.post(
        "webhooks/hub",
        "hub.callback" => "URL/twitch-test",
        "hub.mode" => "subscribe",
        "hub.topic" => "https://api.twitch.tv/helix/streams?user_id=#{twitch_user_id}",
      )

      # revoke_token(temp_access_token)
      # Docs say this should work for an app token but I keep getting a 400
      # prob means we need to manage the tokens more statefully
    end

    def twitch_client(access_token)
      Faraday.new("https://api.twitch.tv/helix", headers: { "Authorization" => "Bearer #{access_token}" }) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    def connection
      @connection ||= Faraday.new("https://api.twitch.tv/helix") do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    def generate_access_token
      connection.post(
        "https://id.twitch.tv/oauth2/token",
        client_id: ApplicationConfig["TWITCH_CLIENT_ID"],
        client_secret: ApplicationConfig["TWITCH_CLIENT_SECRET"],
        grant_type: :client_credentials,
      ).body["access_token"]
    end

    def revoke_token(token)
      connection.post(
        "https://id.twitch.tv/oauth2/revoke",
        client_id: ApplicationConfig["TWITCH_CLIENT_ID"],
        token: token,
      )
    end
  end
end
