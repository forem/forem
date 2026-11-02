module PushNotifications
  class DeliverWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority,
                    retry: 10,
                    lock: :until_expired,
                    lock_ttl: 30,
                    on_conflict: :log

    def perform
      # Deliver all pending Push Notifications
      Rpush.push
    end
  end
end
