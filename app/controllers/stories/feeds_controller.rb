module Stories
  class FeedsController < ApplicationController
    respond_to :json

    def show
      @page = (params[:page] || 1).to_i
      @comments_variant = field_test(:comments_to_display, participant: @user)

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
      feed = if Settings::UserExperience.feed_strategy == "basic"
               Articles::Feeds::Basic.new(user: current_user, page: @page, tag: params[:tag])
             else
               Articles::Feeds.feed_for(
                 user: current_user,
                 controller: self,
                 page: @page,
                 tag: params[:tag],
                 number_of_articles: 35,
               )
             end
      Datadog::Tracing.trace("feed.query",
                             span_type: "db",
                             resource: "#{self.class}.#{__method__}",
                             tags: { feed_class: feed.class.to_s.dasherize }) do
        # Hey, why the to_a you say?  Because the
        # LargeForemExperimental has already done this.  But the
        # weighted strategy has not.  I also don't want to alter the
        # weighted query implementation as it returns a lovely
        # ActiveRecord::Relation.  So this is a compromise.
        scope = feed.more_comments_minimal_weight_randomized

        scope = case @comments_variant
                when "top_comments"
                  scope.includes(top_comments: :user)
                when "more_inclusive_top_comments"
                  scope.includes(more_inclusive_top_comments: :user)
                when "recent_good_comments"
                  scope.includes(recent_good_comments: :user)
                when "more_inclusive_recent_good_cmments"
                  scope.includes(more_inclusive_recent_good_cmments: :user)
                when "most_inclusive_recent_good_comments"
                  scope.includes(most_inclusive_recent_good_comments: :user)
                else
                  # Apply the default scope or an additional variant
                  scope
                end
        scope.to_a
      end
    end

    def signed_out_base_feed
      feed = if Settings::UserExperience.feed_strategy == "basic"
               Articles::Feeds::Basic.new(user: nil, page: @page, tag: params[:tag])
             else
               Articles::Feeds.feed_for(
                 user: current_user,
                 controller: self,
                 page: @page,
                 tag: params[:tag],
                 number_of_articles: 25,
               )
             end
      Datadog::Tracing.trace("feed.query",
                             span_type: "db",
                             resource: "#{self.class}.#{__method__}",
                             tags: { feed_class: feed.class.to_s.dasherize }) do
        # Hey, why the to_a you say?  Because the
        # LargeForemExperimental has already done this.  But the
        # weighted strategy has not.  I also don't want to alter the
        # weighted query implementation as it returns a lovely
        # ActiveRecord::Relation.  So this is a compromise.
        feed.default_home_feed(user_signed_in: false).to_a
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
