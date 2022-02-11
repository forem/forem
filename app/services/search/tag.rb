module Search
  class Tag
    ATTRIBUTES = %i[id name hotness_score rules_html supported short_summary bg_color_hex badge_id].freeze

    DEFAULT_PER_PAGE = 60
    MAX_PER_PAGE = 100

    def self.search_documents(
      page: 0,
      per_page: DEFAULT_PER_PAGE,
      term: nil
    )
      results = ::Tag.search_by_name(term).supported.includes(:badge)
        .reorder(hotness_score: :desc).page(page).per(per_page).select(*ATTRIBUTES)
      serialize(results)
    end

    def self.serialize(results)
      Search::TagSerializer.new(results, is_collection: true).serializable_hash[:data].pluck(:attributes)
    end
    private_class_method :serialize
  end
end
