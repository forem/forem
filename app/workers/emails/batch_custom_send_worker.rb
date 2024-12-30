module Emails
  class BatchCustomSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority

    def perform(user_ids, subject, content, type_of, email_id)
      user_ids.each do |id|
        CustomMailer.with(user: User.find(id), subject: subject, content: content, type_of: type_of, email_id: email_id).custom_email.deliver_now
      rescue StandardError => e
        Rails.logger.error("Error sending email to user with id: #{id}. Error: #{e.message}")
      end
    end
  end
end