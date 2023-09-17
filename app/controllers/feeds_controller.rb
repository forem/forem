class FeedsController < ApplicationController
  respond_to :json

  def show
    @page = (params[:page] || 1).to_i

    # /explore/:timeframe
    if params[:feed_type] == "explore"
      @stories = assign_explore_feed_posts
    end

    if params[:feed_type] == "following"
      @stories = assign_following_feed_posts
    end

    add_pinned_article
  end

  private

  # we want to create a base feed controller that does the following:
  # 1. We have a base class Articles::Feeds::Base that checks for published and maybe orders accordingly
  # 2. if we are in the following path then it calls Articles::Feed::Following which returns articles that are followed.
  # 4. if we have a tag then it will amend those passed in articles accordingly from Articles::Feed::Tag
  # (although this really seems unused)
  # 3. if we have a timeframe then it will amend those passed in articles accordingly from Articles
  # Articles::Feed::Timeframes::Latest, Articles::Feed:Timeframes::Top, Articles::Feed::Timeframes::Recommended
  # 4. if we have a signed in user then

  # /recommended
  # /latest
  # /top/week
  # /top/month

  def add_pinned_article
    return if params[:timeframe].present?

    pinned_article = PinnedArticle.get
    return if pinned_article.nil? || @stories.detect { |story| story.id == pinned_article.id }

    @stories.prepend(pinned_article.decorate)
  end

  def assign_following_feed_posts
    posts = if params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
              timeframe_feed
            elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
              latest_feed
            elsif user_signed_in?
              signed_in_base_feed
            else
              signed_out_base_feed
            end

    ArticleDecorator.decorate_collection(posts)
  end

  def assign_explore_feed_posts
    posts = if params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
              timeframe_feed
            elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
              latest_feed
            elsif user_signed_in?
              signed_in_base_feed
            else
              signed_out_base_feed
            end

    ArticleDecorator.decorate_collection(posts)
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
      feed.more_comments_minimal_weight_randomized.to_a
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
    # [Ridhwana]: It doesnt seem like we need articles_filtered_by_tag because it doesnt match existing behaviour
    # in our application.
    articles_filtered_by_tag = Articles::Feeds::Tag.call(params[:tag])
    # [Ridhwana]: we could add this Base class call in Articles::Feeds::Timeframe?
    articles = Articles::Feeds::Base.call(articles: articles_filtered_by_tag, page: @page)
    # [Ridhwana]: page is duplicated here, lets figure out what to do with it.
    Articles::Feeds::Timeframe.call(params[:timeframe], articles: articles, page: @page)
  end

  def latest_feed
    # [Ridhwana]: It doesnt seem like we need articles_filtered_by_tag because it doesnt match existing behaviour
    # in our application.
    articles_filtered_by_tag = Articles::Feeds::Tag.call(params[:tag])
    # [Ridhwana]: we could add this Base class call in Articles::Feeds::Latest?
    articles = Articles::Feeds::Base.call(articles: articles_filtered_by_tag, page: @page)
    # [Ridhwana]: page is duplicated here, lets figure out what to do with it.
    Articles::Feeds::Latest.call(articles: articles, page: @page)
  end
end
