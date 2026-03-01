class RssFeedsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rss_feed, only: %i[show edit update destroy]

  def index
    @rss_feeds = current_user.rss_feeds.order(created_at: :desc)
  end

  def show
    @imports = @rss_feed.rss_feed_imports.order(created_at: :desc).limit(20)
  end

  def new
    @rss_feed = current_user.rss_feeds.new
  end

  def edit
  end

  def create
    @rss_feed = current_user.rss_feeds.new(rss_feed_params)

    if @rss_feed.save
      redirect_to rss_feeds_path, notice: "RSS Feed was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @rss_feed.update(rss_feed_params)
      redirect_to rss_feeds_path, notice: "RSS Feed was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rss_feed.destroy
    redirect_to rss_feeds_path, notice: "RSS Feed was successfully destroyed."
  end

  private

  def set_rss_feed
    @rss_feed = current_user.rss_feeds.find(params[:id])
  end

  def rss_feed_params
    permitted = [:url, :mark_canonical, :referential_link, :status, :fallback_user_id]
    permitted << :fallback_organization_id if current_user.any_admin?
    params.require(:rss_feed).permit(permitted)
  end
end
