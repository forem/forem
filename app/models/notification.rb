class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user

  include StreamRails::Activity
  as_activity

  validates :user_id, presence: true,
            uniqueness: { scope: [:notifiable_id,
                                  :notifiable_type,
                                  :action] }

  class << self
    def send_all(notifiable, action)
      if notifiable.class.name == "Article"
        return if notifiable.created_at < Time.new(2017,07,07,00,00,00,"+00:00")
        notifiable.user.followers.each do |follower|
          Notification.create(
            user_id: follower.id,
            notifiable_id: notifiable.id,
            notifiable_type: "Article",
            action: action
          )
        end
      elsif notifiable.class.name == "Broadcast"
        if action == "Announcement"
          User.all.each do |user|
            Notification.create!(
              user_id: user.id,
              notifiable_id: notifiable.id,
              notifiable_type: "Broadcast",
              action: action,
            )
          end
        end
      end
    end
    handle_asynchronously :send_all

    def remove_all(notifiable, action)
      Notification.where(
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
        action: action
      ).destroy_all
    end
    handle_asynchronously :remove_all
  end

  def activity_actor
    if notifiable.class.name == "Broadcast" || action == "Moderation"
      User.find(ENV["DEVTO_USER_ID"])
    else
      notifiable.user
    end
  end

  def activity_object
    notifiable
  end

  def activity_verb
    "#{notifiable_type}_#{action}"
  end

  def activity_target
    "#{notifiable_type.downcase}_#{Time.now}"
  end

  def activity_notify
    [StreamNotifier.new(user_id).notify]
  end

  def remove_from_feed
    User.find(user_id)&.touch(:last_notification_activity)
  end

end
