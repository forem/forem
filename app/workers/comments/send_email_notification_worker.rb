module Comments
  class SendEmailNotificationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :mailers

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      NotifyMailer.new_reply_email(comment).deliver_now if comment
    end
  end
end
