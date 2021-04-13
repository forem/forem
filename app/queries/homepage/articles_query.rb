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

    def self.call(...)
      new(...).call
    end

    # TODO: [@rhymes] change frontend to start from page 1
    def initialize(published_at: nil, sort_by: nil, sort_direction: nil, page: 0, per_page: DEFAULT_PER_PAGE)
      @relation = Article.published.select(*ATTRIBUTES)

      @published_at = published_at
      @sort_by = sort_by
      @sort_direction = sort_direction

      @page = page.to_i + 1
      @per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min
    end

    def call
      filter.merge(sort).merge(paginate)
    end

    private

    attr_accessor :relation
    attr_reader :published_at, :sort_by, :sort_direction, :page, :per_page

    def filter
      return relation unless published_at

      relation.where(published_at: published_at)
    end

    def sort
      return relation unless sort_by

      relation.order(sort_by => sort_direction)
    end

    def paginate
      relation.page(page).per(per_page)
    end
  end
end
