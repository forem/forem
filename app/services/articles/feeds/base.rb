module Articles
  module Feeds
    module Base
      def self.call(articles: Article, page: 1, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE)
        articles
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .includes(:distinct_reaction_categories)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
