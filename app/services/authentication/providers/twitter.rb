module Authentication
  module Providers
    # Twitter authentication provider, uses omniauth-twitter as backend
    class Twitter < Provider
      SETTINGS_URL = "https://twitter.com/settings/applications".freeze

      def new_user_data
        name = raw_info.name.presence || info.name
        remote_profile_image_url = info.image.to_s.gsub("_normal", "")

        {
          email: info.email.to_s,
          name: name,
          remote_profile_image_url: Users::SafeRemoteProfileImageUrl.call(remote_profile_image_url),
          twitter_created_at: raw_info.created_at,
          twitter_username: info.nickname
        }
      end

      def existing_user_data
        {
          twitter_created_at: raw_info.created_at,
          twitter_username: info.nickname
        }
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        # see https://github.com/arunagw/omniauth-twitter#authentication-options
        mandatory_params = { secure_image_url: true }

        ::Authentication::Paths.sign_in_path(
          provider_name,
          **kwargs.merge(mandatory_params),
        )
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload.tap do |auth|
          # Twitter sends the server side access token keys in the payload
          # for each authentication. We definitely do not want to store those
          auth.extra.delete("access_token")
        end
      end
    end
  end
end
