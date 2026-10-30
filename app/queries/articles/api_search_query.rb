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
      requested_per_page = params[:per_page].to_i
      @per_page = requested_per_page.positive? ? [requested_per_page, per_page_max].min : DEFAULT_PER_PAGE
    end

    def call
      @articles = published_articles_with_users_and_organizations

      if q.present?
        @articles = query_articles
        @articles = if top.present?
                      # Use `(articles.score + 0)` when combined with full-text search so PostgreSQL
                      # drives the query via the GIN index (`index_articles_on_reading_list_document`)
                      # instead of scanning the score B-tree index backwards on rare terms, while
                      # `.reorder` drops `ts_rank` so `reading_list_document` is not de-TOASTed.
                      top_articles.reorder(Arel.sql("(articles.score + 0) DESC, articles.id ASC"))
                    else
                      # Use `(articles.hotness_score + 0)` so PostgreSQL cannot choose a slow backward
                      # B-tree scan on `index_articles_on_hotness_score` when `LIMIT` is small and
                      # the search term matches few or zero rows.
                      @articles.reorder(Arel.sql("(articles.hotness_score + 0) DESC, articles.id ASC"))
                    end
      elsif top.present?
        @articles = top_articles.order(score: :desc)
      else
        @articles = @articles.order(hotness_score: :desc)
      end

      @articles.page(page).per(per_page)
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
      if q.present?
        # Wrap `published_at` in an expression when combined with full-text search so
        # PostgreSQL does not abandon `index_articles_on_reading_list_document` to scan
        # `index_articles_on_published_at_and_score` and de-TOAST `reading_list_document`
        # on every article in the timeframe window.
        @articles.where("(articles.published_at + INTERVAL '0 seconds') > ?", top.to_i.days.ago)
      else
        @articles.where("published_at > ?", top.to_i.days.ago)
      end
    end

    def published_articles_with_users_and_organizations
      score_clause = q.present? ? "(articles.score + 0) >= ?" : "score >= ?"
      Article.published.from_subforem
        .includes([{ user: :profile }, :organization])
        .where(score_clause, Settings::UserExperience.index_minimum_score)
    end
  end
end
