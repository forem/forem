module Authentication
  module Providers
    # Apple authentication provider, uses omniauth-apple as backend
    class Apple < Provider
      OFFICIAL_NAME = "Apple".freeze
      CREATED_AT_FIELD = :apple_created_at
      USERNAME_FIELD = :apple_username
      SETTINGS_URL = "https://appleid.apple.com/account/manage".freeze

      def new_user_data
        # NOTE: Apple sends `first_name` and `last_name` as separate fields
        name = "#{info.first_name} #{info.last_name}"

        # Apple has no concept of username, so we use the first name
        username = info.first_name.downcase

        {
          email: info.email,
          apple_created_at: Time.zone.at(raw_info.auth_time),
          apple_username: username,
          name: name
        }
      end

      def existing_user_data
        {
          apple_created_at: Time.zone.at(raw_info.auth_time)
        }
      end

      def self.user_created_at_field
        CREATED_AT_FIELD
      end

      def self.user_username_field
        USERNAME_FIELD
      end

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(params = {})
        ::Authentication::Paths.sign_in_path(
          provider_name,
          params,
        )
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
