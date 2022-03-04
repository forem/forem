require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Forem < OmniAuth::Strategies::OAuth2
      option :name, :forem

      option :client_options, {
        site: ApplicationConfig["PASSPORT_OAUTH_URL"] || "https://passport.forem.com".freeze,
        authorize_url: "/oauth/authorize"
      }

      uid { raw_info[:id] }

      info do
        {
          email: raw_info[:email],
          name: raw_info[:name],
          user_nickname: raw_info[:username]
        }
      end

      extra do
        skip_info? ? {} : { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get("/api/v0/me").parsed.with_indifferent_access
      end

      def callback_url
        "#{full_host}#{script_name}#{callback_path}"
      end
    end
  end
end
