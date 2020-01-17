module Notifications
  class NewCommentWorker
    include Sidekiq::Worker
    sidekiq_options queue: :medium_priority, retry: 10

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      Notifications::NewComment::Send.call(comment) if comment
    end
  end
end
