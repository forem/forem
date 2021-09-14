module Articles
  module Feeds
    module Latest
      MINIMUM_SCORE = -20

      def self.call(tag: nil, number_of_articles: 50, page: 1)
        Articles::Feeds::Tag.call(tag)
          .order(published_at: :desc)
          .where("score > ?", MINIMUM_SCORE)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
