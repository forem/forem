module Stories
  class TaggedArticlesController < ApplicationController
    before_action :set_cache_control_headers, only: :index

    SIGNED_OUT_RECORD_COUNT = 60

    rescue_from ArgumentError, with: :bad_request

    def index
      @tag = Tag.find_by(name: params[:tag].downcase) || not_found

      if @tag.alias_for.present?
        redirect_permanently_to("/t/#{@tag.alias_for}")
        return
      end

      @page = (params[:page] || 1).to_i
      @article_index = true
      @moderators = User.with_role(:tag_moderator, @tag).select(:username, :profile_image, :id)

      set_number_of_articles(tag: @tag)

      set_stories(number_of_articles: @number_of_articles, tag: @tag, page: @page)
      not_found_if_not_established(tag: @tag, stories: @stories)

      set_surrogate_key_header "articles-#{@tag}"
      set_cache_control_headers(600,
                                stale_while_revalidate: 30,
                                stale_if_error: 86_400)
    end

    private

    def set_number_of_articles(tag:)
      @num_published_articles = if tag.requires_approval?
                                  tag.articles.published.approved.count
                                elsif Settings::UserExperience.feed_strategy == "basic"
                                  tagged_count(tag: tag)
                                else
                                  Rails.cache.fetch("article-cached-tagged-count-#{tag.name}", expires_in: 2.hours) do
                                    tagged_count(tag: tag)
                                  end
                                end

      @number_of_articles = user_signed_in? ? 5 : SIGNED_OUT_RECORD_COUNT
    end

    def set_stories(number_of_articles:, page:, tag:)
      stories = Articles::Feeds::Tag.call(tag.name, number_of_articles: number_of_articles, page: page)

      stories = stories.approved if tag.requires_approval?

      stories = stories_by_timeframe(stories: stories)
      @stories = stories.decorate
    end

    def tagged_count(tag:)
      tag.articles.published.where(score: Settings::UserExperience.tag_feed_minimum_score..).count
    end

    def not_found_if_not_established(stories:, tag:)
      not_found if stories.none? && !tag.supported?
    end

    def stories_by_timeframe(stories:)
      if Timeframe::FILTER_TIMEFRAMES.include?(params[:timeframe])
        stories.where("published_at > ?", Timeframe.datetime(params[:timeframe]))
          .order(public_reactions_count: :desc)
      elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
        stories.where(score: -20..).order(published_at: :desc)
      else
        stories.order(hotness_score: :desc).with_at_least_home_feed_minimum_score
      end
    end
  end
end
