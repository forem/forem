module Articles
  module Feeds
    module Timeframe
      def self.call(timeframe, tag: nil, number_of_articles: 50, page: 1)
        articles = ::Articles::Feeds::Tag.call(tag)

        articles
          .where("published_at > ?", ::Timeframe.datetime(timeframe))
          .order(score: :desc)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
