module Articles
  # NOTE: articles cache either users or organization, but they have the same attributes
  CachedEntity = Struct.new(:name, :username, :slug, :profile_image_90, :profile_image_url) do
    def self.from_object(object)
      new(
        object.name,
        object.username,
        object.is_a?(Organization) ? object.slug : object.username,
        object.profile_image_90,
        object.profile_image_url,
      )
    end
  end
end
