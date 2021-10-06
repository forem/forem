module Articles
  module Feeds
    module Tag
      def self.call(tag = nil, number_of_articles: 50, page: 1)
        articles =
          if tag.present?
            if FeatureFlag.enabled?(:optimize_article_tag_query)
              Article.cached_tagged_with_any(tag)
            else
              ::Tag.find_by(name: tag).articles
            end
          else
            Article.all
          end

        articles
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
