class Follow < ApplicationRecord

  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  include StreamRails::Activity
  as_activity

  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, :polymorphic => true
  belongs_to :follower,   :polymorphic => true
  counter_culture :follower, column_name: proc { |follow|
    case follow.followable_type
    when "User"
      "following_users_count"
    when "Organization"
      "following_orgs_count"
    when "ActsAsTaggableOn::Tag"
      "following_tags_count"
    # Andy: Add more whens if we add more follow types
    end
  }, column_names: {
    ["follows.followable_type = ?", "User"] => "following_users_count",
    ["follows.followable_type = ?", "Organization"] => "following_orgs_count",
    ["follows.followable_type = ?", "ActsAsTaggableOn::Tag"] => "following_tags_count",
  }
  after_save :touch_user
  after_create :send_email_notification

  def activity_actor
    follower
  end

  def activity_notify
    return if followable.class.name != "User"
    [StreamNotifier.new(followable.id).notify]
  end

  def activity_object
    followable
  end

  def activity_target
    return "follow_#{Time.now}"
  end

  def remove_from_feed
    super
    if followable_type == "User"
      User.find(followable.id)&.touch(:last_notification_activity)
    end
  end


  private

  def touch_user
    follower.touch
  end
  handle_asynchronously :touch_user

  def send_email_notification
    if followable.class.name == "User" && followable.email.present? && followable.email_follower_notifications
      return if EmailMessage.where(user_id: followable.id).
        where("sent_at > ?", rand(6..35).hours.ago).
        where("subject LIKE ?", "%followed you on dev.to%").any?
      NotifyMailer.new_follower_email(self).deliver
    end
  end
  handle_asynchronously :send_email_notification

end
