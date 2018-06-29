class NotificationCounter

  def initialize(user)
    @user = user
  end

  def unread_notification_count
    return 0 if Rails.env.test?
    StreamRails.feed_manager.get_notification_feed(@user.id).get['unseen']
  end

  def set_to_zero
    StreamRails.feed_manager.get_notification_feed(@user.id).get(mark_seen:true)
  end
end
