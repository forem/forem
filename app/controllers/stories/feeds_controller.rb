module Stories
  class FeedsController < ApplicationController
    respond_to :json

    def show
      @stories = assign_feed_stories

      add_pinned_article
    end

    private

    def add_pinned_article
      return if params[:timeframe].present?

      pinned_article = PinnedArticle.get
      return if pinned_article.nil? || @stories.detect { |story| story.id == pinned_article.id }

      @stories.prepend(pinned_article.decorate)
    end

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
        feed = Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
        feed.more_comments_minimal_weight_randomized_at_end
      end
    end

    def signed_out_base_feed
      if Settings::UserExperience.feed_strategy == "basic"
        Articles::Feeds::Basic.new(user: nil, page: @page, tag: params[:tag]).feed
      else
        Articles::Feeds::LargeForemExperimental.new(user: current_user, page: @page, tag: params[:tag])
          .default_home_feed(user_signed_in: false)
      end
    end

    def timeframe_feed
      Articles::Feeds::Timeframe.call(params[:timeframe], tag: params[:tag], page: @page)
    end

    def latest_feed
      Articles::Feeds::Latest.call(tag: params[:tag], page: @page)
    end
  end
end
