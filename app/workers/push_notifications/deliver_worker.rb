module PushNotifications
  class DeliverWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    retry: 10,
                    lock: :until_expired,
                    lock_ttl: 30,
                    on_conflict: :log

    def perform
      # Deliver all pending Push Notifications
      Rpush.push
      # Callback for feedback (see `config/initializers/rpush.rb`)
      Rpush.apns_feedback
    end
  end
end
