class StreamNotifier
  attr_accessor :user_id, :user
  def initialize(user_id)
    @user_id = user_id
    @user = User.find(user_id)
  end

  def notify
    user&.touch(:last_notification_activity)
    StreamRails.feed_manager.get_notification_feed(user_id)
  end
end
