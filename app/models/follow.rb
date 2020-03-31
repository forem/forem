class Follow < ApplicationRecord
  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  # Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, polymorphic: true
  belongs_to :follower,   polymorphic: true

  scope :followable_user, ->(id) { where(followable_id: id, followable_type: "User") }
  scope :followable_tag, ->(id) { where(followable_id: id, followable_type: "ActsAsTaggableOn::Tag") }

  scope :follower_user, ->(id) { where(follower_id: id, followable_type: "User") }
  scope :follower_organization, ->(id) { where(follower_id: id, followable_type: "Organization") }
  scope :follower_podcast, ->(id) { where(follower_id: id, followable_type: "Podcast") }
  scope :follower_tag, ->(id) { where(follower_id: id, followable_type: "ActsAsTaggableOn::Tag") }

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
    ["follows.followable_type = ?", "ActsAsTaggableOn::Tag"] => "following_tags_count"
  }
  after_save :touch_follower
  after_create :send_email_notification
  after_create_commit :create_chat_channel
  before_destroy :modify_chat_channel_status

  validates :followable_id, uniqueness: { scope: %i[followable_type follower_id] }
  validates :subscription_status, inclusion: { in: %w[all_articles none] }

  def self.need_new_follower_notification_for?(followable_type)
    %w[User Organization].include?(followable_type)
  end

  private

  def touch_follower
    follower.touch(:updated_at, :last_followed_at)
  end

  def create_chat_channel
    return unless followable_type == "User"

    Follows::CreateChatChannelWorker.perform_async(id)
  end

  def send_email_notification
    return unless followable.class.name == "User" && followable.email?

    Follows::SendEmailNotificationWorker.perform_async(id)
  end

  def modify_chat_channel_status
    return unless followable_type == "User" && followable.following?(follower)

    channel = follower.chat_channels.
      find_by("slug LIKE ? OR slug like ?", "%/#{followable.username}%", "%#{followable.username}/%")
    channel&.update(status: "inactive")
  end
end
