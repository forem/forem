module Articles
  module Feeds
    module Latest
      MINIMUM_SCORE = -20

      def self.call(articles: Article, number_of_articles: nil, page: 1, minimum_score: nil)
        number_of_articles ||= Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE
        minimum_score ||= MINIMUM_SCORE

        # [Ridhwana] I moved the where clause to the top here because it seems more efficient to filter first and
        # we matching the behavior of timeframe.
        articles
          .where("score > ?", minimum_score)
          .includes(:distinct_reaction_categories)
          .order(published_at: :desc)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
