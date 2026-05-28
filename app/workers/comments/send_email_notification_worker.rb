module Comments
  class SendEmailNotificationWorker
    include Sidekiq::Job

    sidekiq_options queue: :mailers

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment && comment.score > -1

      NotifyMailer.with(comment: comment).new_reply_email.deliver_now
    rescue ArgumentError => e
      raise unless e.message.include?("SMTP To address may not be blank")
    end
  end
end
