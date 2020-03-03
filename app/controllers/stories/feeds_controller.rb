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
              elsif user_signed_in?
                ab_test_user_signed_in_feed(feed)
              else
                feed.default_home_feed(user_signed_in: user_signed_in?)
              end
    ArticleDecorator.decorate_collection(stories)
  end

  def ab_test_user_signed_in_feed(feed)
    test_variant = field_test(:user_home_feed, participant: current_user)
    case test_variant
    when "base"
      feed.default_home_feed(user_signed_in: true)
    when "more_random"
      feed.default_home_feed_with_more_randomness
    when "mix_base_and_more_random"
      feed.mix_default_and_more_random
    when "more_tag_weight"
      feed.more_tag_weight
    else
      feed.default_home_feed(user_signed_in: true)
    end
  end
end
