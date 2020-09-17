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
        user_resp = HTTParty.get("https://api.twitch.tv/helix/users", query: { login: user.twitch_username },
                                                                      headers: authentication_request_headers)

        # user_resp["data"].first["id"]
        twitch_user_id = user_resp.try(:[], "data").to_a.first.try(:[], "id")
        return unless twitch_user_id

        HTTParty.post(
          "https://api.twitch.tv/helix/webhooks/hub",
          body: webhook_request_body(twitch_user_id),
          headers: authentication_request_headers,
        )
      end

      private

      attr_reader :user, :access_token_service

      def webhook_request_body(twitch_user_id)
        {
          "hub.callback" => twitch_stream_updates_url_for_user(user),
          "hub.mode" => "subscribe",
          "hub.lease_seconds" => WEBHOOK_LEASE_SECONDS,
          "hub.topic" => "https://api.twitch.tv/helix/streams?user_id=#{twitch_user_id}",
          "hub.secret" => ApplicationConfig["TWITCH_WEBHOOK_SECRET"]
        }
      end

      def authentication_request_headers
        { "Authorization" => "Bearer #{access_token_service.call}" }
      end

      def twitch_stream_updates_url_for_user(user)
        Rails.application.routes.url_helpers.user_twitch_stream_updates_url(user_id: user.id,
                                                                            host: SiteConfig.app_domain)
      end
    end
  end
end
