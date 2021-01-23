module Authentication
  module Providers
    # Facbook authentication provider, uses omniauth-facebook as backend
    class Discord < Provider
      OFFICIAL_NAME = "Discord".freeze
      SETTINGS_URL = "https://discord.com/channels/@me".freeze

      def new_user_data
        {
          name: info.name,
          email: info.email.to_s,
          remote_profile_image_url: info.image,
          discord_username: user_nickname,
          discord_created_at: Time.zone.now
        }
      end

      def existing_user_data
        {
          discord_username: user_nickname,
          discord_created_at: Time.zone.now
        }
      end

      def user_nickname
        info.name + raw_info.discriminator
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
