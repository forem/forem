module Authentication
  module Providers
    # Apple authentication provider, uses omniauth-apple as backend
    class Apple < Provider
      SETTINGS_URL = "https://appleid.apple.com/account/manage".freeze

      def new_user_data
        # Apple sends `first_name` and `last_name` as separate fields
        name = "#{info.first_name} #{info.last_name}"

        {
          email: info.email,
          apple_created_at: Time.zone.at(raw_info.auth_time),
          apple_username: apple_username,
          name: name,
          remote_profile_image_url: SiteConfig.mascot_image_url
        }
      end

      def existing_user_data
        {
          apple_created_at: Time.zone.at(raw_info.auth_time),
          apple_username: apple_username
        }
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

      # Apple has no concept of username, so we use a hash of the email
      # NOTE: we can't use the email itself, as Apple private relay emails
      # exceed the limit of 30 chars we set for username and the username field
      # is auto generated from the provider username on sign up
      def apple_username
        # we generate 25 characters from the username to make sure we never
        # incur in a length validation error in User#set_temp_username
        Digest::SHA512.hexdigest(info.email)[0...25]
      end
    end
  end
end
