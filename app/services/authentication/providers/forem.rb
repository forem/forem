module Authentication
  module Providers
    # GitHub authentication provider, uses omniauth-github as backend
    class Forem < Provider
      OFFICIAL_NAME = "Forem".freeze
      SETTINGS_URL = "https://passport.forem.com".freeze

      def new_user_data
        name = raw_info.name.presence || info.name

        {
          email: info.email.to_s,
          name: name,
          remote_profile_image_url: Users::SafeRemoteProfileImageUrl.call(info.image.to_s)
        }
      end

      def existing_user_data
        {}
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
