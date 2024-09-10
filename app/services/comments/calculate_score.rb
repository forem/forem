module Comments
  class CalculateScore
    def self.call(...)
      new(...).call
    end

    def initialize(comment)
      @comment = comment
    end

    def call
      score = BlackBox.comment_quality_score(comment)
      score -= 500 if comment.user&.spam?
      score += Settings::UserExperience.index_minimum_score if comment.user&.base_subscriber?
      comment.update_columns(score: score, updated_at: Time.current)

      comment.user&.touch(:last_comment_at)

      # update commentable
      commentable = comment.commentable

      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
      Comments::Count.call(commentable, recalculate: true) if commentable.is_a?(Article)

      # busting comment cache includes busting commentable cache
      Comments::BustCacheWorker.new.perform(comment.id)
    end

    private

    attr_reader :comment
  end
end
