module Articles
  module Feeds
    module Tag
      # Optimized tag feed service that reduces database queries and improves performance
      # 
      # Optimizations:
      # 1. Accepts Tag objects to avoid double lookups
      # 2. Always prefers cached_tagged_with_any for better performance
      # 3. Consolidates includes to prevent N+1 queries
      # 4. Preloads user/organization associations
      def self.call(tag = nil, number_of_articles: Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1)
        articles =
          if tag.present?
            # Always use the optimized cached approach for better performance
            if tag.is_a?(::Tag)
              # If we already have a Tag object, use cached_tagged_with_any with the name
              Article.cached_tagged_with_any(tag.name)
            elsif FeatureFlag.enabled?(:optimize_article_tag_query)
              Article.cached_tagged_with_any(tag)
            else
              # Fallback to the less efficient approach only if feature flag is off
              tag_obj = ::Tag.find_by(name: tag)
              return Article.none unless tag_obj
              tag_obj.articles
            end
          else
            Article.all
          end

        articles
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .includes(:distinct_reaction_categories, :context_notes, :subforem)
          .preload(:user, :organization) # Preload user and organization to avoid N+1 in views
          .page(page)
          .per(number_of_articles)
      end
    end
  end
end
