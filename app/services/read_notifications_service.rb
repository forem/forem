class ReadNotificationsService

  def initialize(user)
    @user = user
  end

  def mark_as_read
    NotificationCounter.new(@user).set_to_zero
    "read"
  end
end
