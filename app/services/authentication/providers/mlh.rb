module Authentication
  module Providers
    # MyMLH authentication provider, uses omniauth-mlh as backend
    class Mlh < Provider
      OFFICIAL_NAME = "MyMLH".freeze
      SETTINGS_URL = "https://my.mlh.io/oauth/applications".freeze

      def self.official_name
        OFFICIAL_NAME
      end

      # MLH has no users.<provider>_username column: the link to the MLH Core
      # account lives on the identity row, whose uid IS the Core user id.
      def self.user_username_field
        nil
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        # For MLH, we do not inject a callback_url param; OmniAuth will use its
        # configured callback path, which must match the URL registered in MyMLH.
        ::Authentication::Paths.authentication_path(provider_name, **kwargs)
      end

      def new_user_data
        {
          email: info.email.to_s,
          name: info.name
        }
      end

      def existing_user_data
        {}
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
