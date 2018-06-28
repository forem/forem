class AnalyticsController < ApplicationController
  caches_action :index,
    cache_path: Proc.new { "#{request.params}___#{current_user.id}" },
    expires_in: 15.minutes
  after_action :verify_authorized

  def index
    article_ids = analytics_params.split(",")
    article_to_check = Article.find_by(id: article_ids.first)
    authorize article_to_check, :analytics_index?
    cache_name = "pageviews-#{article_ids}/dashboard-index"
    pageviews = Rails.cache.fetch(cache_name, expires_in: 15.minutes) do
      GoogleAnalytics.new(article_ids).get_pageviews
    end
    render json: pageviews.to_json
  end

  private

  def analytics_params
    params.require(:article_ids)
  end
end
