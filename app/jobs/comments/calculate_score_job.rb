module Comments
  class CalculateScoreJob < ApplicationJob
    queue_as :comments_calculate_score

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      comment.update_column(:score, BlackBox.comment_quality_score(self))
      comment.update_column(:spaminess_rating, BlackBox.calculate_spaminess(self))
      comment.root.save unless comment.is_root?
    end
  end
end
