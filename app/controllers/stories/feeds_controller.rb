class Stories::FeedsController < ApplicationController
  respond_to :json

  def show
    @stories = assign_feed_stories
  end

  private

  def assign_feed_stories
    feed = Articles::Feed.new(number_of_articles: 35, page: @page, tag: params[:tag])
    stories = if %w[week month year infinity].include?(params[:timeframe])
                feed.top_articles_by_timeframe(timeframe: params[:timeframe])
              elsif params[:timeframe] == "latest"
                feed.latest_feed
              else
                feed.default_home_feed(user_signed_in: user_signed_in?)
              end
    ArticleDecorator.decorate_collection(stories)
  end
end
