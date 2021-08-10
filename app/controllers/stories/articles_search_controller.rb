module Stories
  class ArticlesSearchController < ApplicationController
    before_action :set_cache_control_headers, only: :index

    rescue_from ArgumentError, with: :bad_request

    def index
      @query = "...searching"
      @article_index = true
      @current_ordering = current_search_results_ordering
      set_surrogate_key_header "articles-page-with-query"
    end

    private

    def current_search_results_ordering
      return :relevance unless params[:sort_by] == "published_at" && params[:sort_direction].present?

      params[:sort_direction] == "desc" ? :newest : :oldest
    end
  end
end
