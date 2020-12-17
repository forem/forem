class Follow < ApplicationRecord
  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  COUNTER_CULTURE_COLUMN_NAME_BY_TYPE = {
    "User" => "following_users_count",
    "Organization" => "following_orgs_count",
    "ActsAsTaggableOn::Tag" => "following_tags_count"
  }.freeze

  COUNTER_CULTURE_COLUMNS_NAMES = {
    ["follows.followable_type = ?", "User"] => "following_users_count",
    ["follows.followable_type = ?", "Organization"] => "following_orgs_count",
    ["follows.followable_type = ?", "ActsAsTaggableOn::Tag"] => "following_tags_count"
  }.freeze

  # Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, polymorphic: true
  belongs_to :follower, polymorphic: true

  scope :followable_user, ->(id) { where(followable_id: id, followable_type: "User") }
  scope :followable_tag, ->(id) { where(followable_id: id, followable_type: "ActsAsTaggableOn::Tag") }

  scope :follower_user, ->(id) { where(follower_id: id, followable_type: "User") }
  scope :follower_organization, ->(id) { where(follower_id: id, followable_type: "Organization") }
  scope :follower_podcast, ->(id) { where(follower_id: id, followable_type: "Podcast") }
  scope :follower_tag, ->(id) { where(follower_id: id, followable_type: "ActsAsTaggableOn::Tag") }

  counter_culture :follower, column_name: proc { |follow| COUNTER_CULTURE_COLUMN_NAME_BY_TYPE[follow.followable_type] },
                             column_names: COUNTER_CULTURE_COLUMNS_NAMES
  before_save :calculate_points
  after_create :send_email_notification
  before_destroy :modify_chat_channel_status
  after_save :touch_follower
  after_create_commit :create_chat_channel

  validates :blocked, inclusion: { in: [true, false] }
  validates :followable_id, presence: true
  validates :followable_type, presence: true
  validates :follower_id, presence: true
  validates :follower_type, presence: true
  validates :subscription_status, presence: true, inclusion: { in: %w[all_articles none] }

  def self.need_new_follower_notification_for?(followable_type)
    %w[User Organization].include?(followable_type)
  end

  private

  def calculate_points
    self.points = explicit_points + implicit_points
  end

  def touch_follower
    follower.touch(:updated_at, :last_followed_at)
  end

  def create_chat_channel
    return unless followable_type == "User"

    Follows::CreateChatChannelWorker.perform_async(id)
  end

  def send_email_notification
    return unless followable.instance_of?(User) && followable.email?

    Follows::SendEmailNotificationWorker.perform_async(id)
  end

  def modify_chat_channel_status
    return unless followable_type == "User" && followable.following?(follower)

    channel = follower.chat_channels
      .find_by("slug LIKE ? OR slug like ?", "%/#{followable.username}%", "%#{followable.username}/%")
    channel&.update(status: "inactive")
  end
end
