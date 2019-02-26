class ReadNotificationsService
  def initialize(receiver)
    @receiver = receiver
  end

  def mark_as_read
    NotificationCounter.new(@receiver).set_to_zero
    # remove_notifications(@recipient.id)
    "read"
  end

  # This was not working as expected. Go back to drawing board.
  # def remove_notifications(user_id)
  #   return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64
  #   payload = {
  #     apns: {
  #       aps: {
  #         alert: {
  #           title: "DEV Notifications",
  #           body: "Marking as read 🙂"
  #         }
  #       },
  #       data: {
  #         url: "REMOVE_NOTIFICATIONS"
  #       }
  #     }
  #   }
  #   Pusher::PushNotifications.publish(interests: ["user-notifications-#{user_id}"], payload: payload)
  # end
end
