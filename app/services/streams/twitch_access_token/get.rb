module Streams
  module TwitchAccessToken
    class Get
      ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY = :twitch_access_token_with_expiration
      def self.call
        new.call
      end

      def call
        token, exp = RedisRailsCache.fetch(ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY)

        if token.nil? || Time.zone.now >= exp
          token, exp = get_new_token
          RedisRailsCache.write(ACCESS_TOKEN_AND_EXPIRATION_CACHE_KEY, token, expires_in: exp)
        end

        token
      end

      private

      def get_new_token
        resp = HTTParty.post(
          "https://id.twitch.tv/oauth2/token",
          body: {
            client_id: ApplicationConfig["TWITCH_CLIENT_ID"],
            client_secret: ApplicationConfig["TWITCH_CLIENT_SECRET"],
            grant_type: :client_credentials
          },
        )
        [resp["access_token"], resp["expires_in"].seconds.from_now]
      end
    end
  end
end
