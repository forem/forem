class ModerationService
  def initialize
    @available_moderators = User.with_role(:trusted).where("last_moderation_notification < ?", 28.hours.ago)
  end

  def send_moderation_notification(object)
    if @available_moderators.any?
      moderator = @available_moderators.sample
      Notification.create(
        user_id: moderator.id,
        notifiable_id: object.id,
        notifiable_type: object.class.name,
        action: "Moderation",
      )
      moderator.update_column(:last_moderation_notification, Time.current)
    end
  end
  handle_asynchronously :send_moderation_notification
end
