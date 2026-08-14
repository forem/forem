module Comments
  class BustCacheWorker < BustCacheBaseWorker
    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment&.commentable

      comment.purge
      comment.commentable.purge

      if comment.commentable_type == "Article"
        Articles::UpdateDependentEmbedsWorker.perform_async(comment.commentable_id)
      end
    end
  end
end
