module Articles
  module Feeds
    module Timeframe
      # [Ridhwana]: We should make timframe a keyword argument
      def self.call(timeframe, articles: Article, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE,
                    page: 1)
        articles
          .where("published_at > ?", ::Timeframe.datetime(timeframe))
          .includes(:distinct_reaction_categories)
          .order(score: :desc)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
