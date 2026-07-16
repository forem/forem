module Api
  module TrendsController
    extend ActiveSupport::Concern

    def index
      per_page = (params[:per_page] || 10).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @trends = Trend.hot_and_recent.page(page).per(num)

      set_surrogate_key_header Trend.table_key, @trends.map(&:record_key)
    end

    def show
      set_surrogate_key_header @trend.record_key
    end

    def articles
      per_page = (params[:per_page] || 10).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      sort_by = params[:sort] == "score" ? "articles.score DESC" : "trend_memberships.distance ASC, articles.score DESC"

      @articles = Article.published
                         .joins(:trend_memberships)
                         .where(trend_memberships: { trend_id: @trend.id })
                         .select(Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION)
                         .includes(user: :profile)
                         .order(sort_by)
                         .page(page)
                         .per(num)
                         .decorate

      set_surrogate_key_header @trend.record_key, *@articles.map(&:record_key)
      render "api/v0/articles/index", formats: :json
    end

    private

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    def find_trend
      id_or_slug = params[:trend_id_or_slug] || params[:id_or_slug]
      @trend = Trend.find_by(id: id_or_slug) || Trend.find_by(slug: id_or_slug)
      raise ActiveRecord::RecordNotFound unless @trend
    end
  end
end
