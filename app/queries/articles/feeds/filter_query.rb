module Articles
  module Feeds
    class FilterQuery
      # [Ridhwana]: Important to note that this is a POC and is not thoroughly tested manually or
      # in an automated fashion as yet. More verification is required.
      MINIMUM_SCORE = -20

      def self.call(...)
        new(...).call
      end

      def initialize(feed_type: "explore", minimum_score: MINIMUM_SCORE,
                     number_of_articles: ::Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE,
                     page: 1, timeframe: nil, tag: nil, user: nil)
        @filtered_articles = Article.all
        @feed_type = feed_type
        @minimum_score = minimum_score
        @number_of_articles = number_of_articles
        @page = page
        @timeframe = timeframe
        @tag = tag
        @user = user
      end

      def call
        if @tag.present?
          @filtered_articles = filter_by_tags
        end

        if @feed_type == "following"
          @filtered_articles = filter_by_following_users_and_organization
        end

        @filtered_articles = base_operations

        if @timeframe == ::Timeframe::LATEST_TIMEFRAME
          @filtered_articles = latest_feed
        elsif @timeframe.in?(::Timeframe::FILTER_TIMEFRAMES)
          @filtered_articles = timeframe_feed
        end

        @filtered_articles = filter_out_hidden_tagged_articles

        @filtered_articles
      end

      private

      def base_operations
        @filtered_articles
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .includes(:distinct_reaction_categories)
          .page(@page)
          .per(@number_of_articles)
      end

      def filter_by_following_users_and_organization
        followed_user_ids = @user.cached_following_users_ids
        followed_organization_ids = @user.cached_following_organizations_ids
        return unless followed_user_ids.any? || followed_organization_ids.any?

        # Just want to call out that the users articles will not be included in the following
        # feed. This is because the user is not following themselves. Will confirm with product
        # that this is expected behaviour.
        @filtered_articles
          .where(user_id: followed_user_ids)
          .or(@filtered_articles.where(organization_id: followed_organization_ids))
      end

      def filter_by_tags
        if FeatureFlag.enabled?(:optimize_article_tag_query)
          @filtered_articles.cached_tagged_with_any(tag)
        else
          ::Tag.find_by(name: tag).articles
        end
      end

      def filter_out_hidden_tagged_articles
        return unless (hidden_tags = @user.cached_antifollowed_tag_names).any?

        @filtered_articles.not_cached_tagged_with_any(hidden_tags)
      end

      def latest_feed
        @filtered_articles
          .order(published_at: :desc)
          .where("score > ?", @minimum_score)
      end

      def timeframe_feed
        @filtered_articles
          .where("published_at > ?", ::Timeframe.datetime(@timeframe))
          .order(score: :desc)
      end
    end
  end
end
