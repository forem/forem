module Articles
  module Feeds
    module Latest
      MINIMUM_SCORE = -20

      def self.call(articles: Article, number_of_articles: nil, page: 1, minimum_score: nil, tag: nil, user: nil)
        number_of_articles ||= Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE
        minimum_score ||= MINIMUM_SCORE

        articles = Articles::Feeds::FilterByTagQuery.call(tag: tag, articles: articles)
        articles = Articles::Feeds::BaseFeedQuery.call(articles: articles)
        articles = Articles::Feeds::FilterOutHiddenTagsQuery.call(articles: articles, user: user)
        # this could possibly be moved to a query as well so that the service just shows the queries that are run for the feed subtypes
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
