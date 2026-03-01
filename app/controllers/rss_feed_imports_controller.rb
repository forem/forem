class RssFeedImportsController < ApplicationController
  before_action :authenticate_user!

  def show
    @rss_feeds = current_user.rss_feeds.includes(:rss_feed_items).order(:created_at)
  end
end
