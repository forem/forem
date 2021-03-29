module Search
  class UsernameSerializer < ApplicationSerializer
    attributes :id,
               :name,
               :profile_image_90,
               :username
  end
end
