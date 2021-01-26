module Users
  module DeleteComments
    module_function

    def call(user)
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.reactions.delete_all
        EdgeCache::BustComment.call(comment.commentable)
        comment.remove_notifications
        comment.remove_from_elasticsearch
        comment.delete
      end
      EdgeCache::BustUser.call(user)
    end
  end
end
