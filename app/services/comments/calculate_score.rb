module Comments
  class CalculateScore
    def initialize(comment)
      @comment = comment
    end

    def self.call(...)
      new(...).call
    end

    def call
      score = BlackBox.comment_quality_score(comment)
      score -= 500 if comment.user&.spam?
      comment.update_columns(score: score, updated_at: Time.current)

      comment.user.touch(:last_comment_at) if comment.user

      # update commentable
      commentable = comment.commentable

      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
      commentable.update_column(:displayed_comments_count, Comments::Count.call(commentable)) if commentable.is_a?(Article)

      # busting comment cache includes busting commentable cache
      Comments::BustCacheWorker.new.perform(comment.id)
    end

    private

    attr_reader :comment
  end
end
