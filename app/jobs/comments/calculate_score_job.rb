module Comments
  class CalculateScoreJob < ApplicationJob
    queue_as :comments_calculate_score

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment

      comment.update_columns(score: BlackBox.comment_quality_score(comment), spaminess_rating: BlackBox.calculate_spaminess(comment))
      comment.user.calculate_score
      comment.root.save if comment && !comment.is_root?
    end
  end
end
