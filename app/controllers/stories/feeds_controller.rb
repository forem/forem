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

    def render_user_chosen_feed(feed_setting)
      case feed_setting
      when "default"
        signed_in_base_feed
      when "latest"
        latest_feed
      when "top_week", "top_month", "top_year", "top_infinity"
        timeframe_feed(feed_setting)
      else
        signed_in_base_feed
      end
    end

    def appropriate_feed(timeframe_param)
      feed_setting =
        Users::Setting.find_by(user_id: current_user.id).config_homepage_feed

      timeframe_feed(timeframe_param) if timeframe_param.in?(Timeframe::FILTER_TIMEFRAMES)
      latest_feed if timeframe_param == Timeframe::LATEST_TIMEFRAME
      render_user_chosen_feed(feed_setting) if user_signed_in?
      signed_out_base_feed
    end

    def assign_feed_stories
      stories = appropriate_feed(params[:timeframe])
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

    def timeframe_feed(timeframe)
      Articles::Feeds::Timeframe.call(timeframe, tag: params[:tag], page: @page)
    end

    def latest_feed
      Articles::Feeds::Latest.call(tag: params[:tag], page: @page)
    end
  end
end
