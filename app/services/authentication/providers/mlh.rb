module Authentication
  module Providers
    # MyMLH authentication provider, uses omniauth-mlh as backend
    class Mlh < Provider
      # "MLH" rather than "MyMLH": this is the name we show people in settings
      # copy, connect buttons and anywhere else `official_name` surfaces.
      OFFICIAL_NAME = "MLH".freeze
      SETTINGS_URL = "https://my.mlh.io/oauth/applications".freeze

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        # For MLH, we do not inject a callback_url param; OmniAuth will use its
        # configured callback path, which must match the URL registered in MyMLH.
        ::Authentication::Paths.authentication_path(provider_name, **kwargs)
      end

      # users.mlh_username is intentionally never written: the MLH ↔ Core
      # link lives on the identity row (uid = Core user id), so the column
      # stays nil rather than mirroring the OAuth nickname.
      def new_user_data
        {
          email: info.email.to_s,
          name: info.name,
          username: Users::UsernameGenerator.call([user_nickname])
        }
      end

      def existing_user_data
        {}
      end

      # MLH has no nickname, so seed username generation from the email
      # local-name so we don't end up with a random string
      def user_nickname
        info.email.to_s.split("@").first.to_s
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
