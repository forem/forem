module Authentication
  module Providers
    # Facbook authentication provider, uses omniauth-facebook as backend
    class Twitch < Provider
      OFFICIAL_NAME = "Twitch".freeze
      SETTINGS_URL = "https://www.twitch.tv/settings/connections".freeze

      def new_user_data
        {
          name: info.name,
          email: info.email.to_s,
          remote_profile_image_url: info.image,
          twitch_username: info.nickname,
          twitch_created_at: Time.zone.now
        }
      end

      def existing_user_data
        {
          twitch_username: info.nickname,
          twitch_created_at: Time.zone.now
        }
      end

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

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
