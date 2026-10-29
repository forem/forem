module Comments
  # Busts the cache of a commentable after some of its comments were removed,
  # e.g. when the commenter's account is deleted.
  class BustCommentableCacheWorker < BustCacheBaseWorker
    def perform(commentable_type, commentable_id)
      return unless Comment::COMMENTABLE_TYPES.include?(commentable_type)

      commentable = commentable_type.constantize.find_by(id: commentable_id)
      return unless commentable

      EdgeCache::BustComment.call(commentable)
    end
  end
end
