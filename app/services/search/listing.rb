module Search
  class Listing
    ATTRIBUTES = %i[
      id
      body_markdown
      bumped_at
      cached_tag_list
      classified_listing_category_id
      contact_via_connect
      expires_at
      organization_id
      originally_published_at
      location
      processed_html
      published
      slug
      title
      user_id
    ].freeze
    private_constant :ATTRIBUTES

    DEFAULT_PER_PAGE = 75
    private_constant :DEFAULT_PER_PAGE

    MAX_PER_PAGE = 150 # to avoid querying too many items, we set a maximum amount for a page
    private_constant :MAX_PER_PAGE

    def self.search_documents(category: nil, page: 0, per_page: DEFAULT_PER_PAGE, term: nil)
      # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
      # to start from page 1
      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      relation = ::Listing
        .includes(:user, :organization, :listing_category)
        .where(published: true)

      relation = relation.where("classified_listing_categories.slug": category) if category.present?

      relation = relation.search_listings(term) if term.present?

      relation = relation.select(*ATTRIBUTES).order(bumped_at: :desc)

      results = relation.page(page).per(per_page)

      serialize(results)
    end

    def self.serialize(results)
      Search::ListingSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize
  end
end
