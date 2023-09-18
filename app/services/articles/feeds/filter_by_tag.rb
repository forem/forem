module Articles
  module Feeds
    module FilterByTag
      def self.call(articles: Article, tag: nil)
        # [Ridhwana]: time didnt allow to amke this smarter but I will.
        articles = Article if articles.blank?

        return articles if tag.blank?

        if FeatureFlag.enabled?(:optimize_article_tag_query)
          Article.cached_tagged_with_any(tag)
        else
          ::Tag.find_by(name: tag).articles
        end
      end
    end
  end
end
