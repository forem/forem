module Mentions
  class SendEmailNotificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 10

    def perform(mention_id)
      mention = Mention.find_by(id: mention_id)
      NotifyMailer.new_mention_email(mention) if mention
    end
  end
end
