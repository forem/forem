class TrendsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index show]

  def index
    skip_authorization
    @trends = Trend.hot_and_recent.limit(20)
  end

  def show
    skip_authorization
    @trend = Trend.find_by!(slug: params[:slug])
    @articles = @trend.articles.published
                       .joins(:trend_memberships)
                       .where(trend_memberships: { trend_id: @trend.id })
                       .order("trend_memberships.distance ASC, articles.score DESC")
                       .page(params[:page])
                       .per(18)
  end
end
