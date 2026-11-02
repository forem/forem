module Users
  module DeleteComments
    module_function

    # Comments are deleted inline, but edge cache purges are enqueued (one job
    # per batch of comments and one per commented-on record) so deleting a
    # prolific commenter isn't slowed down by an HTTP purge per comment.
    #
    # Each batch is deleted in the same transaction that enqueues its purges,
    # so if enqueuing fails the batch is rolled back and a retry finds it again.
    def call(user)
      return unless user.comments.any?

      user.comments.includes(:user).find_in_batches do |comments|
        Comment.transaction { delete_batch(comments) }
      end
      EdgeCache::PurgeByKeyWorker.perform_async(user.profile_cache_keys, user.profile_cache_bust_paths)
    end

    def delete_batch(comments)
      Notification.remove_all_without_delay(notifiable_ids: comments.map(&:id), notifiable_type: "Comment")

      keys = []
      paths = []
      commentables = Set.new
      comments.each do |comment|
        comment.reactions.delete_all
        keys << comment.record_key
        paths << comment.path
        commentables << [comment.commentable_type, comment.commentable_id] if comment.commentable_id
        comment.delete
      end

      delay = BustCacheBaseWorker::AFTER_COMMIT_DELAY
      EdgeCache::PurgeByKeyWorker.perform_in(delay, keys, paths)
      commentables.each do |commentable_type, commentable_id|
        Comments::BustCommentableCacheWorker.perform_in(delay, commentable_type, commentable_id)
      end
    end
  end
end
