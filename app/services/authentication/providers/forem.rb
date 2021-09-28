module Authentication
  module Providers
    class Forem < Provider
      OFFICIAL_NAME = "Forem".freeze
      DOMAIN_URL = ApplicationConfig["PASSPORT_OAUTH_URL"] || "https://passport.forem.com".freeze
      SETTINGS_URL = "#{DOMAIN_URL}/oauth/authorized_applications".freeze

      def new_user_data
        {
          email: info.email,
          name: info.name,
          remote_profile_image_url: raw_info.remote_profile_image_url,
          forem_username: info.user_nickname
        }
      end

      def existing_user_data
        {
          email: info.email,
          name: info.name,
          forem_username: info.user_nickname
        }
      end

      delegate :user_nickname, to: :info

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

      # Remove sensible data from the payload: None in this case so return as-is
      # For more details see Authentication::Providers::Provider#cleanup_payload
      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
