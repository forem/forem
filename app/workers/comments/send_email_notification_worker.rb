module Comments
  class SendEmailNotificationWorker
    include Sidekiq::Job

    sidekiq_options queue: :mailers

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      NotifyMailer.with(comment: comment).new_reply_email.deliver_now if comment
    end
  end
end
