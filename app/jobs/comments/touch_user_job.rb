module Comments
  class TouchUserJob < ApplicationJob
    queue_as :comments_touch_user

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      comment&.user&.touch(:updated_at, :last_comment_at)
    end
  end
end
