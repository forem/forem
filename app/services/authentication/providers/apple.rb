module Authentication
  module Providers
    # Apple authentication provider, uses omniauth-apple as backend
    class Apple < Provider
      SETTINGS_URL = "https://appleid.apple.com/account/manage".freeze

      def new_user_data
        # NOTE: Apple sends `first_name` and `last_name` as separate fields
        name = "#{info.first_name} #{info.last_name}"

        # Apple has no concept of username, so we use the first name
        apple_username = info.first_name.downcase

        {
          email: info.email,
          apple_created_at: Time.zone.at(raw_info.auth_time),
          apple_username: apple_username,
          name: name,
          remote_profile_image_url: SiteConfig.mascot_image_url
        }
      end

      def existing_user_data
        # Apple by default will send nil `first_name` and `last_name` after
        # the first login. To cover the case where a user disconnects their
        # Apple authorization, signs in again and then changes their name,
        # we update the username only if the name is not nil
        apple_username = info.first_name.present? ? info.first_name.downcase : nil

        data = { apple_created_at: Time.zone.at(raw_info.auth_time) }
        data[:apple_username] = apple_username if apple_username
        data
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
