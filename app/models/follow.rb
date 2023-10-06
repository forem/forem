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

  # NOTE: These assume that we have one follower_type (as defined by acts_as_follower).
  scope :follower_user, ->(id) { where(follower_id: id, followable_type: "User") }
  scope :follower_organization, ->(id) { where(follower_id: id, followable_type: "Organization") }
  scope :follower_podcast, ->(id) { where(follower_id: id, followable_type: "Podcast") }
  scope :follower_tag, ->(id) { where(follower_id: id, followable_type: "ActsAsTaggableOn::Tag") }

  scope :non_suspended, lambda { |followable_type, followable_id|
    joins("INNER JOIN users ON users.id = follows.follower_id")
      .joins("LEFT JOIN users_roles ON users_roles.user_id = users.id")
      .joins("LEFT JOIN roles ON roles.id = users_roles.role_id")
      .where(followable_type: followable_type, followable_id: followable_id)
      .where("follows.follower_type = 'User'")
      .where("roles.name != 'suspended' OR roles.name IS NULL")
  }

  counter_culture :follower, column_name: proc { |follow| COUNTER_CULTURE_COLUMN_NAME_BY_TYPE[follow.followable_type] },
                             column_names: COUNTER_CULTURE_COLUMNS_NAMES
  before_save :calculate_points
  after_create :send_email_notification
  after_save :touch_follower

  validates :blocked, inclusion: { in: [true, false] }
  validates :followable_type, presence: true
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

  def send_email_notification
    return unless followable.instance_of?(User) && followable.email?

    Follows::SendEmailNotificationWorker.perform_async(id)
  end
end
