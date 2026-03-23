module Notifications
  class CleanupUserWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5
    sidekiq_throttle(concurrency: { limit: 5 })

    def perform(user_id)
      Notification.fast_cleanup_older_than_150_for(user_id)
    end
  end
end
