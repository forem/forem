module Mentions
  class SendEmailNotificationJob < ApplicationJob
    queue_as :mentions_send_email_notification

    def perform(mention_id)
      mention = Mention.find_by(id: mention_id)
      NotifyMailer.new_mention_email(mention) if mention
    end
  end
end
