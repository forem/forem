module Notifications
  class WelcomeNotificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(receiver_id)
      welcome_broadcast = Broadcast.find_by(title: "Welcome Notification")

      Notifications::WelcomeNotification::Send.call(receiver_id, welcome_broadcast) if welcome_broadcast
    end
  end
end
