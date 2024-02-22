module Comments
  class CalculateScoreWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment

      score = BlackBox.comment_quality_score(comment)
      score -= 500 if comment.user&.spam?
      comment.update_columns(score: score, updated_at: Time.current)

      comment.commentable.touch(:last_comment_at) if comment.commentable.respond_to?(:last_comment_at)
      comment.user.touch(:last_comment_at) if comment.user

      # busting comment cache includes busting commentable cache
      Comments::BustCacheWorker.new.perform(comment.id)
    end
  end
end
