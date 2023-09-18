# [Ridhwana]: These feel like they should be queries rather than services?
module Articles
  module Feeds
    module FilterOutHiddenTagsQuery
      def self.call(user: nil, articles: Article)
        if (hidden_tags = user.cached_antifollowed_tag_names).any?
          articles.not_cached_tagged_with_any(hidden_tags)
        end
        articles
      end
    end
  end
end
