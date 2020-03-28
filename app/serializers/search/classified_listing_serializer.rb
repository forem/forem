module Search
  class ClassifiedListingSerializer
    include FastJsonapi::ObjectSerializer

    attributes :id,
               :body_markdown,
               :bumped_at,
               :category,
               :contact_via_connect,
               :expires_at,
               :location,
               :processed_html,
               :published,
               :slug,
               :title,
               :user_id

    attribute :tags, &:tag_list

    attribute :author do |cl|
      ClassifiedListingAuthorSerializer.new(cl.author).
        serializable_hash.
        dig(:data, :attributes)
    end
  end
end
