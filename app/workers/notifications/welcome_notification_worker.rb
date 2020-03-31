module Notifications
  class WelcomeNotificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(receiver_id, broadcast_id)
      return unless (welcome_broadcast = Broadcast.active.find_by(id: broadcast_id))

      Notifications::WelcomeNotification::Send.call(receiver_id, welcome_broadcast)
    end
  end
end
