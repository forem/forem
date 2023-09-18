module Articles
  module Feeds
    module Following
      def self.call(user: nil)
        # [Ridhwana]: Should we pass through the article?
        # [Ridhwana]: any harm in passing the user in? I don't think so since this page won't be cached, only for signed
        # in users
        if (followed_tags = user.cached_followed_tag_names).any?
          articles = Article.cached_tagged_with_any(followed_tags)
        end

        # [Ridhwana]: we need to put this somewhere else as it applies to multiple feeds.
        # Maybe Base, but Base is also used for signed_out
        if (hidden_tags = user.cached_antifollowed_tag_names).any?
          articles = articles.not_cached_tagged_with_any(hidden_tags)
        end

        # If we do not have an y following tags or articles with the following tags
        articles || nil
      end
    end
  end
end
