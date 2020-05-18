module Search
  class ListingAuthorSerializer
    include FastJsonapi::ObjectSerializer

    attributes :username, :name, :profile_image_90
  end
end
