class PushNotificationsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :medium_priority, retry: 10, lock: :until_executed

  def perform
    # Will attempt to deliver all pending Push Notifications
    Rpush.push
    # Callback for feedback (see `config/initializers/rpush.rb`)
    Rpush.apns_feedback
  end
end
