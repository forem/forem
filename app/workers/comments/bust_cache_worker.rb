module Comments
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(comment_id, service = "EdgeCache::Commentable::Bust")
      comment = Comment.find_by(id: comment_id)
      return unless comment&.commentable

      service.constantize.call(comment.commentable)
    end
  end
end
