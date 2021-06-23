module Stories
  class FeedsController < ApplicationController
    respond_to :json

    def show
      @stories = assign_feed_stories
    end

    private

    def assign_feed_stories
      stories = if params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
                  timeframe_feed
                elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
                  latest_feed
                elsif user_signed_in?
                  signed_in_base_feed
                else
                  signed_out_base_feed
                end
      ArticleDecorator.decorate_collection(stories)
    end

    def signed_in_base_feed
      if Settings::UserExperience.feed_strategy == "basic"
        Articles::Feeds::Basic.new(user: current_user, page: @page, tag: params[:tag]).feed
      else
        optimized_signed_in_feed
      end
    end

    def signed_out_base_feed
      if Settings::UserExperience.feed_strategy == "basic"
        Articles::Feeds::Basic.new(user: nil, page: @page, tag: params[:tag]).feed
      else
        Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
          .default_home_feed(user_signed_in: user_signed_in?)
      end
    end

    def timeframe_feed
      feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
      feed.top_articles_by_timeframe(timeframe: params[:timeframe])
    end

    def latest_feed
      feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
      feed.latest_feed
    end

    def optimized_signed_in_feed
      feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
      feed.more_comments_minimal_weight_randomized_at_end
    end
  end
end
