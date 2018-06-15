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
    # add more whens if we add more follow types
    end
  }, column_names: {
    ["follows.followable_type = ?", "User"] => "following_users_count",
    ["follows.followable_type = ?", "Organization"] => "following_orgs_count",
    ["follows.followable_type = ?", "ActsAsTaggableOn::Tag"] => "following_tags_count",
  }
  after_save :touch_user
  after_save :touch_user_followed_at
  after_create :send_email_notification
  after_create :create_chat_channel
  before_destroy :modify_chat_channel_status

  validates :followable_id, uniqueness: { scope: [:followable_type, :follower_id] }

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

  def touch_user_followed_at
    follower.touch(:last_followed_at)
  end
  handle_asynchronously :touch_user_followed_at

  def create_chat_channel
    if followable_type == "User" && followable.following?(follower)
      ChatChannel.create_with_users([followable, follower])
    end
  end
  handle_asynchronously :create_chat_channel

  def send_email_notification
    if followable.class.name == "User" && followable.email.present? && followable.email_follower_notifications
      return if EmailMessage.where(user_id: followable.id).
        where("sent_at > ?", rand(15..35).hours.ago).
        where("subject LIKE ?", "%followed you on dev.to%").any?
      NotifyMailer.new_follower_email(self).deliver
    end
  end
  handle_asynchronously :send_email_notification

  def modify_chat_channel_status
    if followable_type == "User" && followable.following?(follower)
      follower.chat_channels.
        where("slug LIKE ? OR slug like ?", "%/#{followable.username}%", "%#{followable.username}/%").
        first.update(status: "inactive")
    end
  end
end
