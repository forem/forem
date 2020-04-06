module Comments
  class CalculateScoreWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment

      score = BlackBox.comment_quality_score(comment)
      spaminess_rating = BlackBox.calculate_spaminess(comment)

      comment.update_columns(score: score, spaminess_rating: spaminess_rating)
      comment.root.save! if !comment.is_root? && comment.root_exists?
    end
  end
end
