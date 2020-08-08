module Comments
  class SendNewCommentNotificationsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      Notifications::NewComment::Send.call(comment) if comment
    end
  end
end
