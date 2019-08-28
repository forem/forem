module Notifications
  class NewCommentJob < ApplicationJob
    queue_as :send_new_comment_notification

    def perform(comment_id, service = NewComment::Send)
      comment = Comment.find_by(id: comment_id)
      service.call(comment) if comment
    end
  end
end
