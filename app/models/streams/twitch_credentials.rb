module Streams
  class TwitchCredentials
    ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY = :twitch_access_token_with_expiration

    class << self
      def access_token
        token, exp = Rails.cache.fetch(ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY)

        if token.nil? || Time.zone.now >= exp
          token, exp = get_new_token
          Rails.cache.write(ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY, [token, exp])
        end

        token
      end

      def generate_client
        Faraday.new("https://api.twitch.tv/helix", headers: { "Authorization" => "Bearer #{access_token}" }) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end
      end

      private

      def get_new_token
        resp = connection.post(
          "https://id.twitch.tv/oauth2/token",
          client_id: ApplicationConfig["TWITCH_CLIENT_ID"],
          client_secret: ApplicationConfig["TWITCH_CLIENT_SECRET"],
          grant_type: :client_credentials,
        )
        [resp.body["access_token"], resp.body["expires_in"].seconds.from_now]
      end

      def connection
        Faraday.new do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
