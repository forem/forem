class RssFeedsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    @rss_feed = current_user.rss_feeds.new(rss_feed_params)
    authorize @rss_feed

    if @rss_feed.save
      flash[:settings_notice] = I18n.t("rss_feeds.created")
    else
      flash[:error] = @rss_feed.errors_as_sentence
    end

    redirect_to user_settings_path("extensions")
  end

  def update
    @rss_feed = RssFeed.find(params[:id])
    authorize @rss_feed

    if @rss_feed.update(rss_feed_params)
      flash[:settings_notice] = I18n.t("rss_feeds.updated")
    else
      flash[:error] = @rss_feed.errors_as_sentence
    end

    redirect_to user_settings_path("extensions")
  end

  def destroy
    @rss_feed = RssFeed.find(params[:id])
    authorize @rss_feed

    if @rss_feed.destroy
      flash[:settings_notice] = I18n.t("rss_feeds.deleted")
    else
      flash[:error] = @rss_feed.errors_as_sentence
    end

    redirect_to user_settings_path("extensions")
  end

  def fetch
    @rss_feed = RssFeed.find(params[:id])
    authorize @rss_feed

    Feeds::ImportArticlesWorker.perform_async([current_user.id])
    flash[:settings_notice] = I18n.t("rss_feeds.fetch_queued")

    redirect_to user_settings_path("extensions")
  end

  private

  def rss_feed_params
    params.require(:rss_feed).permit(
      :feed_url, :name, :mark_canonical, :referential_link,
      :fallback_organization_id, :fallback_author_id, :status
    )
  end
end
