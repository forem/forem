module Search
  class SimpleUserSerializer < ApplicationSerializer
    attribute :class_name, -> { "User" }
    attributes :id, :path
    attribute :title, &:name

    attribute :user do |user|
      {
        # currently the frontend expects this to be the username, despite the attribute name
        name: user.username,
        profile_image_90: user.profile_image_90,
        username: user.username
      }
    end
  end
end
