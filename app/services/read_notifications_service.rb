class ReadNotificationsService
  def initialize(user)
    @user = user
  end

  def mark_as_read
    NotificationCounter.new(@user).set_to_zero
    remove_notifications(@user.id)
    "read"
  end

  def remove_notifications(user_id)
    return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64
    payload = {
      apns: {
        aps: {
          alert: {
            title: "DEV Notifications",
            body: "Marking as read 🙂"
          }
        },
        data: {
          url: "REMOVE_NOTIFICATIONS"
        }
      }
    }
    Pusher::PushNotifications.publish(interests: ["user-notifications-#{user_id}"], payload: payload)
  end
end
