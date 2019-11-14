module Comments
  class TouchUserJob < ApplicationJob
    queue_as :comments_touch_user

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      user = comment&.user
      user&.touch(:updated_at, :last_comment_at)
      user&.update_columns(
        trailing_7_day_comments_count: user&.comments&.where("created_at > ?", 7.days.ago)&.size || 0,
        trailing_28_day_comments_count: user&.comments&.where("created_at > ?", 28.days.ago)&.size || 0,
      )
    end
  end
end
