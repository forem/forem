module Comments
  class BustCacheJob < ApplicationJob
    queue_as :comments_bust_cache

    def perform(comment_id, cache_buster = CacheBuster.new)
      comment = Comment.find_by(id: comment_id)
      Comment.comment_async_bust(comment.commentable, comment.user.username) if comment
      cache_buster.bust("#{comment.commentable.path}/comments") if comment&.commentable
    end
  end
end
