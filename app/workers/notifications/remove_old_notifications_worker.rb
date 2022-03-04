module Notifications
  class RemoveOldNotificationsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      Notification.fast_destroy_old_notifications
    end
  end
end
