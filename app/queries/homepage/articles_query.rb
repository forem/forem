module Homepage
  class ArticlesQuery
    ATTRIBUTES = %i[
      cached_tag_list
      comments_count
      crossposted_at
      id
      organization_id
      path
      public_reactions_count
      published_at
      reading_time
      title
      user_id
      video_duration_in_seconds
      video_thumbnail_url
    ].freeze
    DEFAULT_PER_PAGE = 60
    MAX_PER_PAGE = 100

    SORT_PARAMS = %i[hotness_score public_reactions_count published_at].freeze
    DEFAULT_SORT_DIRECTION = :desc

    def self.call(...)
      new(...).call
    end

    # TODO: [@rhymes] change frontend to start from page 1
    def initialize(
      approved: nil,
      published_at: nil,
      user_id: nil,
      organization_id: nil,
      tags: [],
      hidden_tags: [],
      sort_by: nil,
      sort_direction: nil,
      page: 0,
      per_page: DEFAULT_PER_PAGE
    )
      @relation = Article.published.select(*ATTRIBUTES)
        .includes(:distinct_reaction_categories)

      @approved = approved
      @published_at = published_at
      @user_id = user_id
      @organization_id = organization_id
      @tags = tags.presence || []
      @hidden_tags = hidden_tags.presence || []

      @sort_by = sort_by
      @sort_direction = sort_direction || DEFAULT_SORT_DIRECTION

      @page = page.to_i + 1
      @per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min
    end

    def call
      filter.merge(sort).merge(paginate)
    end

    private

    attr_reader :relation, :approved, :published_at, :user_id, :organization_id, :tags, :hidden_tags,
                :sort_by, :sort_direction, :page, :per_page

    def filter
      @relation = @relation.where(approved: approved) unless approved.nil?
      @relation = @relation.where(published_at: published_at) if published_at.present?
      @relation = @relation.where(user_id: user_id) if user_id.present?
      @relation = @relation.where(organization_id: organization_id) if organization_id.present?
      @relation = @relation.cached_tagged_with_any(tags) if tags.any?
      @relation = @relation.not_cached_tagged_with_any(hidden_tags) if hidden_tags.any?
      @relation = @relation.includes(:distinct_reaction_categories)
      @relation = @relation.where("score >= 0") # Never return negative score articles

      relation
    end

    def sort
      return relation unless SORT_PARAMS.include?(sort_by&.to_sym)

      relation.order(sort_by => sort_direction)
    end

    def paginate
      relation.page(page).per(per_page)
    end
  end
end
