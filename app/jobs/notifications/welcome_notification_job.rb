module Notifications
  class WelcomeNotificationJob < ApplicationJob
    queue_as :send_welcome_notification

    def perform(receiver_id, service = WelcomeNotification::Send)
      welcome_broadcast = Broadcast.find_by(title: "Welcome Notification")

      service.call(receiver_id, welcome_broadcast) if welcome_broadcast
    end
  end
end
