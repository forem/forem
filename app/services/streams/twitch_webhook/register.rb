module Streams
  module TwitchWebhook
    class Register
      WEBHOOK_LEASE_SECONDS = 7.days.to_i

      def initialize(user, access_token_service = TwitchAccessToken::Get)
        @user = user
        @access_token_service = access_token_service
      end

      def self.call(*args)
        new(*args).call
      end

      def call
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

      attr_reader :user, :access_token_service

      def client
        @client ||= Faraday.new("https://api.twitch.tv/helix", headers: { "Authorization" => "Bearer #{access_token_service.call}" }) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end
      end

      def twitch_stream_updates_url_for_user(user)
        Rails.application.routes.url_helpers.user_twitch_stream_updates_url(user_id: user.id, host: ApplicationConfig["APP_DOMAIN"])
      end
    end
  end
end
