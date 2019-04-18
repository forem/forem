module Streams
  class TwitchCredentials
    ACCESS_TOKEN_CACHE_KEY = :twitch_access_token

    include Singleton

    def access_token
      Rails.cache.fetch(ACCESS_TOKEN_CACHE_KEY, expires_in: 7.days) do
        connection.post(
          "https://id.twitch.tv/oauth2/token",
          client_id: ApplicationConfig["TWITCH_CLIENT_ID"],
          client_secret: ApplicationConfig["TWITCH_CLIENT_SECRET"],
          grant_type: :client_credentials,
        ).body["access_token"]
      end
    end

    def self.access_token
      instance.access_token
    end

    def revoke_token(token)
      connection.post(
        "https://id.twitch.tv/oauth2/revoke",
        client_id: ApplicationConfig["TWITCH_CLIENT_ID"],
        token: token,
      )
    end

    def generate_client
      Faraday.new("https://api.twitch.tv/helix", headers: { "Authorization" => "Bearer #{access_token}" }) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.generate_client
      instance.generate_client
    end

    private

    def connection
      Faraday.new("https://api.twitch.tv/helix") do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
