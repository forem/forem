module Comments
  class CreateIdCodeJob < ApplicationJob
    queue_as :comments_create_id_code

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      comment&.update_column(:id_code, comment.id.to_s(26))
    end
  end
end
