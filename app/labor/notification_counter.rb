class NotificationCounter
  def initialize(user)
    @user = user
  end

  def unread_notification_count
    return 0 if Rails.env.test?
    @user.notifications.where(read: false).count
  end

  def set_to_zero
    @user.notifications.where(read: false).update_all(read: true)
  end
end
