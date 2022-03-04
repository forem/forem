module Articles
  # NOTE: articles cache either users or organizations, but they have the same attributes.
  CachedEntity = Struct.new(:name, :username, :slug, :profile_image_90, :profile_image_url) do
    include Images::Profile.for(:profile_image_url)

    def self.from_object(object)
      new(
        object.name,
        object.username,
        object.respond_to?(:slug) ? object.slug : object.username,
        object.profile_image_90,
        object.profile_image_url,
      )
    end
  end
end
