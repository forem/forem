module EdgeCache
  class BustComment
    def self.call(commentable)
      return unless commentable

      cache_bust = EdgeCache::Bust.new
      bust_article_comment(cache_bust, commentable) if commentable.is_a?(Article)
      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)

      cache_bust.call("#{commentable.path}/comments/")
      cache_bust.call(commentable.path.to_s)

      commentable.comments.includes(:user).find_each do |comment|
        cache_bust.call(comment.path)
        cache_bust.call("#{comment.path}?i=i")
      end

      cache_bust.call("#{commentable.path}/comments/*")
    end

    # bust commentable if it's an article
    def self.bust_article_comment(cache_bust, article)
      cache_bust.call("/") if Article.published.order(hotness_score: :desc).limit(3).ids.include?(article.id)

      return unless article.decorate.discussion?

      cache_bust.call("/")
      cache_bust.call("/?i=i")
      cache_bust.call("?i=i")
    end

    private_class_method :bust_article_comment
  end
end
