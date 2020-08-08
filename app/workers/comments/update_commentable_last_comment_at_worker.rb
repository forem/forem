module Comments
  class UpdateCommentableLastCommentAtWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(commentable_id, commentable_type)
      commentable = commentable_type.constantize.find(commentable_id)
      commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
    end
  end
end
