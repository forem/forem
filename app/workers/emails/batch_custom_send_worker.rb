module Emails
  class BatchCustomSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15

    def perform(user_ids, subject, content)
      user_ids.each do |id|
        CustomMailer.with(user: User.find(id), subject: subject, content: subject).custom_email.deliver_now
      end
    end
  end
end