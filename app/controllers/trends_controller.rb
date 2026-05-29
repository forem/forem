class TrendsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index show]

  def index
    skip_authorization
    @active_trend_tags = Tag.joins(:trends)
      .merge(Trend.where("trends.last_observed_at >= ?", 7.days.ago))
      .distinct
      .order(:name)

    if params[:tag].present?
      @tag = Tag.find_by(name: params[:tag])
      @trends = Trend.hot_and_recent.where(tag: @tag).limit(20)
    else
      @trends = Trend.hot_and_recent.limit(20)
    end

    set_surrogate_key_header Trend.table_key, *@trends.map(&:record_key), *@active_trend_tags.map(&:record_key)
  end

  def show
    skip_authorization
    @trend = Trend.find_by!(slug: params[:slug])
    @articles = Article.published
      .joins(:trend_memberships)
      .where(trend_memberships: { trend_id: @trend.id })
      .order("trend_memberships.distance ASC, articles.score DESC")
      .page(params[:page])
      .per(18)
    set_surrogate_key_header @trend.record_key, *@articles.map(&:record_key)
  end
end
