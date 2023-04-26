module Articles
  class ApiSearchQuery
    DEFAULT_PER_PAGE = 30

    def self.call(...)
      new(...).call
    end

    def initialize(params)
      @q = params[:q]
      @top = params[:top]
      @page = params[:page].to_i
      @per_page = [(params[:per_page] || DEFAULT_PER_PAGE).to_i, per_page_max].min
    end

    def call
      @articles = published_articles_with_users_and_organizations

      if q.present?
        @articles = query_articles
      end

      if top.present?
        @articles = top_articles
      end

      @articles
    end

    private

    attr_reader :q, :top, :page, :per_page

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    def query_articles
      @articles
        .search_articles(q)
        .order(hotness_score: :desc)
        .page(page)
        .per(per_page || DEFAULT_PER_PAGE)
    end

    def top_articles
      @articles
        .where("published_at > ?", top.to_i.days.ago)
        .order(public_reactions_count: :desc)
        .page(page).per(per_page || DEFAULT_PER_PAGE)
    end

    def base_articles
      @articles
        .featured
        .order(hotness_score: :desc)
        .page(page)
        .per(per_page || DEFAULT_PER_PAGE)
    end

    def published_articles_with_users_and_organizations
      Article.published.includes([{ user: :profile }, :organization])
    end
  end
end
