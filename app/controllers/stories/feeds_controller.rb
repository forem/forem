class Stories::FeedsController < ApplicationController
  respond_to :json

  def show
    @stories = assign_feed_stories
  end

  private

  def assign_feed_stories
    feed = Articles::Feed.new(user: current_user, page: @page, tag: params[:tag])
    stories = if params[:timeframe].in?(Timeframer::FILTER_TIMEFRAMES)
                feed.top_articles_by_timeframe(timeframe: params[:timeframe])
              elsif params[:timeframe] == Timeframer::LATEST_TIMEFRAME
                feed.latest_feed
              else
                feed.default_home_feed(user_signed_in: user_signed_in?)
              end
    ArticleDecorator.decorate_collection(stories)
  end
end
