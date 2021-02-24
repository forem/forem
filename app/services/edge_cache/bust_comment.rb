module EdgeCache
  class BustComment < Buster
    def self.call(commentable)
      return unless commentable

      buster = EdgeCache::Buster.new
      bust_article_comment(buster, commentable) if commentable.is_a?(Article)
      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)

      buster.bust("#{commentable.path}/comments/")
      buster.bust(commentable.path.to_s)

      commentable.comments.includes(:user).find_each do |comment|
        buster.bust(comment.path)
        buster.bust("#{comment.path}?i=i")
      end

      buster.bust("#{commentable.path}/comments/*")
    end

    # bust commentable if it's an article
    def self.bust_article_comment(buster, article)
      buster.bust("/") if Article.published.order(hotness_score: :desc).limit(3).ids.include?(article.id)

      return unless article.decorate.discussion?

      buster.bust("/")
      buster.bust("/?i=i")
      buster.bust("?i=i")
    end

    private_class_method :bust_article_comment
  end
end
