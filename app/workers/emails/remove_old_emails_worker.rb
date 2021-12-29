module Emails
  class RemoveOldEmailsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      EmailMessage.fast_destroy_old_retained_email_deliveries
    end
  end
end
