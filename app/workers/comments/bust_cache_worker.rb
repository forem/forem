module Comments
  class BustCacheWorker < BustCacheBaseWorker
    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment&.commentable

      comment.purge
      comment.commentable.purge

      EdgeCache::Commentable::Bust.call(comment.commentable)
    end
  end
end
