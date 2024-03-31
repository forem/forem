module Authentication
  module Providers
    # Google OAuth 2.0 authentication provider, uses omniauth-google-oauth2 as backend
    class GoogleOauth2 < Provider
      OFFICIAL_NAME = "Google".freeze
      SETTINGS_URL = "https://console.cloud.google.com/apis/credentials".freeze

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        ::Authentication::Paths.sign_in_path(
          "google_oauth2",
          **kwargs,
        )
      end

      def new_user_data
        {
          name: info.name,
          email: info.email || "",
          remote_profile_image_url: Images::SafeRemoteProfileImageUrl.call(@info.image),
          google_oauth2_username: user_nickname
        }
      end

      def existing_user_data
        {
          google_oauth2_username: info.name
        }
      end

      # We're overriding this method because Google doesn't have a concept nickname or username.
      # Instead: we'll construct one based on the user's name with some randomization thrown in based
      # on uid, which is guaranteed to be present and unique from Google.
      def user_nickname
        [
          info.name.sub(" ", "_"),
          Digest::SHA512.hexdigest(auth_payload.uid),
        ].join("_")[0...25]
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
