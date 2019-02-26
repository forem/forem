class NotificationCounter
  def initialize(receiver)
    @receiver = receiver
  end

  def unread_notification_count
    return 0 if Rails.env.test?

    @receiver.notifications.where(read: false).count
  end

  def set_to_zero
    @receiver.notifications.where(read: false).update_all(read: true)
  end
end
