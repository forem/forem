# [Ridhwana]: These feel like they should be queries rather than services?
module Articles
  module Feeds
    module BaseFeedQuery
      def self.call(articles: Article)
        # again this is a hack until i fix teh stuffs
        articles = Article if articles.blank?

        articles
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .includes(:distinct_reaction_categories)
      end
    end
  end
end
