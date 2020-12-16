module Users
  module DeleteComments
    module_function

    def call(user, cache_buster = CacheBuster)
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.reactions.delete_all
        EdgeCache::BustComment.call(comment.commentable)
        comment.remove_notifications
        comment.remove_from_elasticsearch
        comment.delete
      end
      cache_buster.bust_user(user)
    end
  end
end
