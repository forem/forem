module Articles
  module Feeds
    class FilterQuery
      MINIMUM_SCORE = -20
      # add defaults for page and number_of_articles

      def self.call(...)
        new(...).call
      end

      def initialize(type:, timeframe:, tag: nil, number_of_articles: nil, page: 1, minimum_score: nil)
        @type = type
        @timeframe = timeframe
        @tag = tag
        @number_of_articles = number_of_articles
        @page = page
        @minimum_score = minimum_score
      end

      def call
        @filtered_articles = base_operations

        if @tag.present?
          @filtered_articles = filter_by_tags
        end

        if @timeframe.in?(Timeframe::FILTER_TIMEFRAMES)
          @filtered_articles = timeframe_feed
        end

        if @timeframe == Timeframe::LATEST_TIMEFRAME
          @filtered_articles = latest_feed
        end

        @filtered_articles
      end

      private

      def base_operations
        Article
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .includes(:distinct_reaction_categories)
          .page(page)
          .per(number_of_articles)
      end

      def filter_by_tags
        if FeatureFlag.enabled?(:optimize_article_tag_query)
          Article.cached_tagged_with_any(tag)
        else
          ::Tag.find_by(name: tag).articles
        end
      end

      def latest_feed
        @filtered_articles
          .order(published_at: :desc)
          .where("score > ?", minimum_score)
      end

      def timeframe_feed
        @filtered_articles
          .where("published_at > ?", ::Timeframe.datetime(@timeframe))
          .order(score: :desc)
      end
    end
  end
end
