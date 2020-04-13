module Authentication
  module Providers
    # GitHub authentication provider, uses omniauth-github as backend
    module Github
      NAME = "github".freeze
      USERNAME_FIELD = "github_username".freeze

      def self.payload(auth_payload)
        auth_payload.dup.tap do |auth|
          auth.extra.delete("access_token")
        end
      end

      def self.new_user_data(auth_payload)
        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        name = raw_info.name.presence || info.name
        remote_profile_image_url = info.image.to_s.gsub("_normal", "")

        {
          email: info.email.to_s,
          github_created_at: raw_info.created_at,
          github_username: info.nickname,
          name: name,
          remote_profile_image_url: remote_profile_image_url
        }
      end

      def self.existing_user_data(auth_payload)
        raw_info = auth_payload.extra.raw_info

        {
          github_created_at: raw_info.created_at
        }
      end
    end
  end
end
