module Visits
  class RemoveOldVisitsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      EmailMessage.fast_destroy_old_retained_email_deliveries
    end
  end
end
