module Emails
  class BatchCustomSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority

    def perform(user_ids, subject, content, type_of, email_id)
      user_ids.each do |id|
        user = User.find_by(id: id)
        next unless user

        unless subject.start_with?("[TEST] ")
          last_email_message = user.email_messages.where(email_id: email_id).last
          # Fix the "last_email" bug by referencing 'last_email_message'
          next if last_email_message && !last_email_message.subject.start_with?("[TEST] ")
        end

        CustomMailer
          .with(
            user: user,
            subject: subject,
            content: content,
            type_of: type_of,
            email_id: email_id
          )
          .custom_email
          .deliver_now
      rescue StandardError => e
        Rails.logger.error("Error sending email to user with id: #{id}. Error: #{e.message}")
      end
    end
  end
end
