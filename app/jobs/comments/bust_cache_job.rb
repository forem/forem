module Comments
  class BustCacheJob < ApplicationJob
    queue_as :comments_bust_cache

    def perform(comment_id, service = EdgeCache::Commentable::Bust)
      comment = Comment.find_by(id: comment_id)
      return unless comment&.commentable

      comment.purge
      comment.commentable.purge

      service.call(comment.commentable)
    end
  end
end
