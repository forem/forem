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
        @articles = top_articles.order(public_reactions_count: :desc)
      end

      @articles.page(page).per(per_page || DEFAULT_PER_PAGE)
    end

    private

    attr_reader :q, :top, :page, :per_page

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    def query_articles
      @articles.search_articles(q)
    end

    def top_articles
      @articles.where("published_at > ?", top.to_i.days.ago)
    end

    def published_articles_with_users_and_organizations
      Article.published.from_subforem
        .includes([{ user: :profile }, :organization])
        .where("score >= ?", Settings::UserExperience.index_minimum_score)
        .order(hotness_score: :desc)
    end
  end
end
