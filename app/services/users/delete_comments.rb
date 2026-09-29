module Users
  module DeleteComments
    module_function

    # Comments are deleted inline, but edge cache purges are enqueued (one job
    # per batch of comments and one per commented-on record) so deleting a
    # prolific commenter isn't slowed down by an HTTP purge per comment.
    def call(user)
      return unless user.comments.any?

      commentables = Set.new
      user.comments.includes(:user).find_in_batches do |comments|
        Notification.remove_all_without_delay(notifiable_ids: comments.map(&:id), notifiable_type: "Comment")

        keys = []
        paths = []
        comments.each do |comment|
          comment.reactions.delete_all
          keys << comment.record_key
          paths << comment.path
          commentables << [comment.commentable_type, comment.commentable_id] if comment.commentable_id
          comment.delete
        end
        EdgeCache::PurgeByKeyWorker.perform_async(keys, paths)
      end

      commentables.each do |commentable_type, commentable_id|
        Comments::BustCommentableCacheWorker.perform_async(commentable_type, commentable_id)
      end
      EdgeCache::PurgeByKeyWorker.perform_async(user.profile_cache_keys, user.profile_cache_bust_paths)
    end
  end
end
