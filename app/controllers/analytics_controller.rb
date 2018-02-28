class AnalyticsController < ApplicationController
  caches_action :index,
    cache_path: Proc.new { "#{request.params}___#{current_user.id}" },
    expires_in: 15.minutes

  def index
    article_ids = analytics_params.split(",")
    if has_analytics_privilege?(article_ids.first, current_user)
      cache_name = "pageviews-#{article_ids}/dashboard-index"
      pageviews = Rails.cache.fetch(cache_name, expires_in: 15.minutes) do
        GoogleAnalytics.new(article_ids).get_pageviews
      end
      render json: pageviews.to_json
    else
      render json: {}
    end
  end

  private

  def has_analytics_privilege?(article_id, current_user)
    return false unless current_user
    current_user_is_admin? ||
      current_user_is_author_with_beta_acess?(article_id, current_user) ||
      current_user_is_org_admin?(article_id, current_user)
  end

  def current_user_is_author_with_beta_acess?(article_id, user)
    author = Article.find_by_id(article_id)&.user
    author == user && user.has_role?(:analytics_beta_tester)
  end

  def current_user_is_org_admin?(article_id, user)
    org_id = Article.find_by_id(article_id)&.organization_id
    user.org_admin && user.organization_id == org_id
  end

  def analytics_params
    params.require(:article_ids)
  end
end
