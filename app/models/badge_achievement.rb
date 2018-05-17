class BadgeAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :badge
  belongs_to :rewarder, class_name: "User", optional: true

  counter_culture :user, column_name: "badge_achievements_count"

  validates :badge_id, uniqueness: { scope: :user_id }

  include StreamRails::Activity
  as_activity

  after_create :send_email_notification

  def name_of_user
    user.name
  end

  # Stream/notification methods
  def activity_actor
    self
  end

  def activity_notify
    [StreamNotifier.new(user.id).notify]
  end

  def activity_object
    user
  end

  def activity_target
    "badge_#{Time.now}"
  end

  def remove_from_feed
    super
    if user.class.name == "User"
      User.find(user.id)&.touch(:last_notification_activity)
    end
  end

  private

  def send_email_notification
    if user.class.name == "User" && user.email.present? && user.email_badge_notifications
      NotifyMailer.new_badge_email(self).deliver
    end
  end
  handle_asynchronously :send_email_notification
end
