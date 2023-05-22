module Search
  class OrganizationSerializer < ApplicationSerializer
    attribute :class_name, -> { "Organization" }
    attributes :id, :name, :summary, :profile_image, :twitter_username, :nav_image, :slug
  end
end
