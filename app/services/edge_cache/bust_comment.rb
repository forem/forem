module EdgeCache
  class BustComment < Bust
    def self.call(commentable)
      return unless commentable

      bust_article_comment(commentable) if commentable.is_a?(Article)
      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)

      bust("#{commentable.path}/comments/")
      bust(commentable.path.to_s)

      commentable.comments.includes(:user).find_each do |comment|
        bust(comment.path)
        bust("#{comment.path}?i=i")
      end

      bust("#{commentable.path}/comments/*")
    end

    # bust commentable if it's an article
    def bust_article_comment(commentable)
      bust("/") if Article.published.order(hotness_score: :desc).limit(3).ids.include?(commentable.id)

      if commentable.decorate.cached_tag_list_array.include?("discuss") &&
          commentable.featured_number.to_i > 35.hours.ago.to_i
        bust("/")
        bust("/?i=i")
        bust("?i=i")
      end
    end
  end
end
