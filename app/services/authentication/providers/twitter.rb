module Authentication
  module Providers
    # Twitter authentication provider, uses omniauth-twitter as backend
    module Twitter
      NAME = "twitter".freeze
      CREATED_AT_FIELD = "#{NAME}_created_at".freeze
      USERNAME_FIELD = "#{NAME}_username".freeze

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
          name: name,
          remote_profile_image_url: remote_profile_image_url,
          twitter_created_at: raw_info.created_at,
          twitter_followers_count: raw_info.followers_count.to_i,
          twitter_following_count: raw_info.friends_count.to_i,
          twitter_username: info.nickname
        }
      end

      def self.existing_user_data(auth_payload)
        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        {
          twitter_created_at: raw_info.created_at,
          twitter_followers_count: raw_info.followers_count.to_i,
          twitter_following_count: raw_info.friends_count.to_i,
          twitter_username: info.nickname
        }
      end
    end
  end
end
