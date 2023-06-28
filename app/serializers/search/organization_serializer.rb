module Search
  class OrganizationSerializer < ApplicationSerializer
    attribute :class_name, -> { "Organization" }
    attributes :id, :name, :summary, :profile_image, :twitter_username, :slug
  end
end
