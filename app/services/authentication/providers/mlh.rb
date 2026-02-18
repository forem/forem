module Authentication
  module Providers
    # MyMLH authentication provider, uses omniauth-mlh as backend
    class Mlh < Provider
      OFFICIAL_NAME = "MyMLH".freeze
      SETTINGS_URL = "https://my.mlh.io/oauth/applications".freeze

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        ::Authentication::Paths.sign_in_path(
          provider_name,
          **kwargs,
        )
      end

      def new_user_data
        {
          email: info.email.to_s,
          mlh_username: info.nickname,
          name: info.name,
        }
      end

      def existing_user_data
        {
          mlh_username: info.nickname
        }
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
