module Comments
  class SendEmailNotificationJob < ApplicationJob
    queue_as :comments_send_email_notification

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      NotifyMailer.new_reply_email(comment)&.deliver if comment
    end
  end
end
