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

      @moderators = User.with_role(:tag_moderator, @tag)
        .order(badge_achievements_count: :desc)
        .select(:username, :profile_image, :id)

      set_number_of_articles(tag: @tag)

      set_stories(number_of_articles: @number_of_articles, tag: @tag, page: @page)

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
                                  Rails.cache.fetch("#{tag.cache_key}/article-cached-tagged-count",
                                                    expires_in: 2.hours) do
                                    tagged_count(tag: tag)
                                  end
                                end

      @number_of_articles = user_signed_in? ? 5 : SIGNED_OUT_RECORD_COUNT
    end

    # @raise [ActiveRecord::NotFound] if we don't have an "established" tag
    def set_stories(number_of_articles:, page:, tag:)
      stories = Articles::Feeds::Tag.call(tag.name, number_of_articles: number_of_articles, page: page)

      stories = stories.approved if tag.requires_approval?

      # NOTE: We want to check if there are any stories regardless of timeframe.
      not_found unless established?(stories: stories, tag: tag)

      # Now, apply the filter.
      stories = stories_by_timeframe(stories: stories)
      @stories = stories.decorate
    end

    def tagged_count(tag:)
      tag.articles.published.where(score: Settings::UserExperience.tag_feed_minimum_score..).count
    end

    # Do we have an established tag?  That means it's supported OR we have at least one published story.
    #
    # @param stories [ActiveRecord::Relation<Article>]
    # @param tag [Tag]
    # @return [TrueClass] if we have published stories for this tag
    # @return [FalseClass] if we do not
    def established?(stories:, tag:)
      return true if tag.supported?
      return true if stories.published.exists?

      false
    end

    def stories_by_timeframe(stories:)
      if Timeframe::FILTER_TIMEFRAMES.include?(params[:timeframe])
        stories.where("published_at > ?", Timeframe.datetime(params[:timeframe]))
          .where(score: -20..)
          .order(public_reactions_count: :desc)
      elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
        stories.where(score: -20..).order(published_at: :desc)
      else
        stories.order(hotness_score: :desc).with_at_least_home_feed_minimum_score
      end
    end
  end
end
