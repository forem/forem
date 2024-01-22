module Comments
  class CalculateScoreWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment

      score = BlackBox.comment_quality_score(comment)
      score -= 500 if comment.user&.spam?
      comment.update_columns(score: score)
      comment.root.save! if !comment.is_root? && comment.root_exists?
    end
  end
end
