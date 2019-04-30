module Comments
  class CalculateScoreJob < ApplicationJob
    queue_as :comments_calculate_score

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)

      comment&.update_columns(score: BlackBox.comment_quality_score(comment), spaminess_rating: BlackBox.calculate_spaminess(comment))
      comment.root.save if comment && !comment.is_root?
    end
  end
end
