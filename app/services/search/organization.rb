module Search
  class Organization
    DEFAULT_SORT_BY = "name".freeze
    ATTRIBUTES = %i[id name hotness_score rules_html supported short_summary bg_color_hex badge_id].freeze

    DEFAULT_PER_PAGE = 75
    private_constant :DEFAULT_PER_PAGE

    MAX_PER_PAGE = 150 # to avoid querying too many items, we set a maximum amount for a page
    private_constant :MAX_PER_PAGE

    DEFAULT_SORT_DIRECTION = :desc
    private_constant :DEFAULT_SORT_DIRECTION

    def self.search_documents(
      term: nil,
      sort_by: DEFAULT_SORT_BY,
      sort_direction: DEFAULT_SORT_DIRECTION,
      page: 0,
      per_page: DEFAULT_PER_PAGE
    )

      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      relation = ::Organization.all

      relation = relation.search_organizations(term) if term.present?

      relation = sort(relation, term, sort_by, sort_direction).page(page).per(per_page)

      Search::OrganizationSerializer
        .new(relation, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end

    def self.sort(relation, term, sort_by, sort_direction)
      return relation if term.present? && sort_by.blank?

      return relation.reorder(sort_by => sort_direction) if sort_direction

      relation.reorder(DEFAULT_SORT_BY)
    end
    private_class_method :sort
  end
end
