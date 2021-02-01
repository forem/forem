module Search
  module Postgres
    class Listing
      SELECT_FIELDS = %i[
        body_markdown
        bumped_at
        cached_tag_list
        classified_listing_category_id
        contact_via_connect
        expires_at
        id
        location
        organization_id
        originally_published_at
        processed_html
        published
        slug
        title
        user_id
      ].freeze

      def self.search_documents(term: nil, category: nil, tags: [], tags_mode: :any, page: 1, per_page: 75)
        page = (page || 1).to_i
        per_page = (per_page || 75).to_i
        tagged_with_any = tags_mode.to_sym == :any

        relation = ::Listing.published
        relation = relation.search(term) if term.present?
        relation = relation.in_category(category) if category.present?
        relation = relation.tagged_with(tags, any: tagged_with_any) if tags.present?

        relation = relation.order(bumped_at: :desc).select(SELECT_FIELDS).page(page).per(per_page)

        rows = Search::ListingSerializer.new(relation).serializable_hash[:data]
        rows.map { |row| row[:attributes].as_json }
      end
    end
  end
end
