module Search
  class ListingSerializer < ApplicationSerializer
    attributes :id,
               :body_markdown,
               :bumped_at,
               :category,
               :contact_via_connect,
               :expires_at,
               :originally_published_at,
               :location,
               :processed_html,
               :published,
               :slug,
               :title,
               :user_id

    attribute :tags do |listing|
      listing.cached_tag_list.to_s.split(", ")
    end

    attribute :author do |listing|
      ListingAuthorSerializer.new(listing.author)
        .serializable_hash
        .dig(:data, :attributes)
    end
  end
end
