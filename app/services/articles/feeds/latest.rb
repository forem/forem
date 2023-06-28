module Articles
  module Feeds
    module Latest
      MINIMUM_SCORE = -20

      def self.call(tag: nil, number_of_articles: nil, page: 1, minimum_score: nil)
        number_of_articles ||= Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE
        minimum_score ||= MINIMUM_SCORE

        Articles::Feeds::Tag.call(tag)
          .order(published_at: :desc)
          .includes(:distinct_reaction_categories)
          .where("score > ?", minimum_score)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
