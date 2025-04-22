module Visits
  class RemoveOldVisitsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      Visit.fast_destroy_old_visits
    end
  end
end
