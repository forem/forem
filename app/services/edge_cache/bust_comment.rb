module EdgeCache
  class BustComment
    def self.call(comment_or_commentable)
      comment = comment_or_commentable.is_a?(Comment) ? comment_or_commentable : nil
      commentable = comment&.commentable || comment_or_commentable
      return unless commentable

      keys = [commentable.record_key, comment&.record_key].compact
      fallback_paths = [commentable.path, comment&.path].compact
      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
      bust_article_comment(commentable) if commentable.is_a?(Article)
      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
      ## Legacy commentable busting — can be removed after Feb 7
      if commentable.is_a?(Article)
        cache_bust = EdgeCache::Bust.new
        cache_bust.call("/#{commentable.slug}")
      end
    end

    # bust commentable if it's an article
    def self.bust_article_comment(article)
      if Article.published.order(hotness_score: :desc).limit(3).ids.include?(article.id)
        EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/")
      end

      return unless article.decorate.discussion?

      EdgeCache::PurgeByKey.call("main_app_home_page", fallback_paths: "/")
    end

    private_class_method :bust_article_comment
  end
end
