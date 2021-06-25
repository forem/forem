module Follows
  class SendEmailNotificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 10

    def perform(follow_id, mailer = NotifyMailer.name)
      follow = Follow.find_by(id: follow_id, followable_type: "User")
      return unless follow&.followable.present? && follow.followable.receives_follower_email_notifications?

      return if EmailMessage.where(user_id: follow.followable_id)
        .where("sent_at > ?", rand(15..35).hours.ago)
        .exists?(["subject LIKE ?", "%#{NotifyMailer.new.subjects[:new_follower_email]}"])

      mailer.constantize.with(follow: follow).new_follower_email.deliver_now
    end
  end
end
