module Articles
  module Feeds
    module Tag
      def self.call(tag = nil)
        if tag.present?
          if FeatureFlag.enabled?(:optimize_article_tag_query)
            Article.cached_tagged_with_any(tag)
          else
            ::Tag.find_by(name: tag).articles
          end
        else
          Article.all
        end
      end
    end
  end
end
