module Follows
  class SendEmailNotificationJob < ApplicationJob
    queue_as :send_follow_email_notification

    def perform(follow_id, mailer = NotifyMailer)
      follow = Follow.find_by(id: follow_id, followable_type: "User")
      return unless follow&.followable&.email? && follow.followable.email_follower_notifications
      return if EmailMessage.where(user_id: follow.followable_id).
        where("sent_at > ?", rand(15..35).hours.ago).
        where("subject LIKE ?", "%followed you on dev.to%").any?

      mailer.new_follower_email(follow).deliver
    end
  end
end
