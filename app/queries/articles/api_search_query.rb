module Articles
  class ApiSearchQuery
    DEFAULT_PER_PAGE = 30

    def self.call(...)
      new(...).call
    end

    def initialize(params)
      @q = params[:q]
      @top = params[:top]
      @sort_by = params[:sortBy]
      @username = params[:username]
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

      if sort_by.present?
        @articles = sort_by_articles(sort_by)
      end

      @articles
    end

    private

    attr_reader :q, :sort_by, :username, :page, :top, :per_page

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

    def sort_by_articles(sort_by)
      articles = @articles

      articles = case sort_by
                 when "newest"
                   articles.where(
                     "public_reactions_count < ? AND published_at > ? AND score > ?", 2, 7.hours.ago, -2
                   )
                 when "rising"
                   articles.where(
                     "public_reactions_count > ? AND public_reactions_count < ? AND published_at > ?",
                     19, 33, 3.days.ago
                   )
                 when "popular"
                   articles.where(
                     "public_reactions_count > ? AND published_at > ?", 33, 5.days.ago
                   )
                 when "recent"
                   articles.order(published_at: :desc)
                 else
                   Article.none
                 end

      articles.page(page).per(per_page || DEFAULT_PER_PAGE)
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
