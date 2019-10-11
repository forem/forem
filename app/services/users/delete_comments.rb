module Users
  module DeleteComments
    module_function

    def call(user, cache_buster = CacheBuster.new)
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.reactions.delete_all
        cache_buster.bust_comment(comment.commentable)
        comment.delete
        comment.remove_notifications
      end
      cache_buster.bust_user(user)
    end
  end
end
