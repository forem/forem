module Authentication
  module Providers
    # Apple authentication provider, uses omniauth-apple as backend
    class Apple < Provider
      OFFICIAL_NAME = "Apple".freeze
      CREATED_AT_FIELD = "apple_created_at".freeze
      USERNAME_FIELD = "apple_username".freeze
      SETTINGS_URL = "https://appleid.apple.com/account/manage".freeze

      def new_user_data
        {

        }
      end

      def existing_user_data
        {
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
    end
  end
end
