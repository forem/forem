module Articles
  module Feeds
    module Latest
      # NOTE: This constant is no longer used in this context, but may be used elsewhere
      MINIMUM_SCORE = -20

      def self.call(tag: nil, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1)
        Articles::Feeds::Tag.call(tag)
          .order(published_at: :desc)
          .with_at_least_home_feed_minimum_score
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
