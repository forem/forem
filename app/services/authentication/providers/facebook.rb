module Authentication
  module Providers
    # Facbook authentication provider, uses omniauth-facebook as backend
    class Facebook < Provider
      OFFICIAL_NAME = "Facebook".freeze
      SETTINGS_URL = "https://www.facebook.com/settings?tab=applications".freeze

      def new_user_data
        image_url = @info.image.gsub("http://", "https://")
        {
          name: @info.name,
          email: @info.email || "",
          remote_profile_image_url: Users::SafeRemoteProfileImageUrl.call(image_url),
          facebook_username: user_nickname,
          facebook_created_at: Time.zone.now
        }
      end

      def existing_user_data
        {
          facebook_username: @info.name,
          facebook_created_at: Time.zone.now
        }
      end

      # We're overriding this method because Facebook doesn't have a concept nickname or username.
      # Instead: we'll construct one based on the user's name with some randomization thrown in based
      # on uid, which is guaranteed to be present and unique on Facebook.
      def user_nickname
        [
          info.name.sub(" ", "_"),
          Digest::SHA512.hexdigest(raw_info.id),
        ].join("_")[0...25]
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
