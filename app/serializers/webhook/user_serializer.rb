module Webhook
  class UserSerializer
    include FastJsonapi::ObjectSerializer

    attributes :name, :username, :twitter_username, :github_username
    attribute :website_url, &:processed_website_url
    attribute :profile_image do |user|
      ProfileImage.new(user).get(640)
    end
    attribute :profile_image_90 do |user|
      ProfileImage.new(user).get(90)
    end
  end
end
