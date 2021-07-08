module Mentions
  class SendEmailNotificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 10

    def perform(mention_id)
      mention = Mention.find_by(id: mention_id)
      return unless mention

      NotifyMailer.with(mention: mention).new_mention_email.deliver_now
    end
  end
end
