module Comments
  class CreateFirstReactionJob < ApplicationJob
    queue_as :comments_create_first_reaction

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)

      Reaction.create(user_id: comment.user_id, reactable_id: comment.id, reactable_type: "Comment", category: "like") if comment
    end
  end
end
