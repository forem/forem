module Comments
  class BustCacheWorker < BustCacheBaseWorker
    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment&.commentable

      comment.purge
      comment.commentable.purge
    end
  end
end
