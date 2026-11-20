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
  scope :follower_subforem, ->(id) { where(follower_id: id, followable_type: "Subforem") }

  # Follows from users who don't have suspended or spam role.
  # Joining on `roles.id = (users_roles.role_id + 0)` prevents PostgreSQL from driving
  # the anti-join via `index_users_roles_on_role_id` (which scans all suspended/spam
  # rows when `roles.id` is unknown at plan time) and forces per-follower index-only
  # lookups on `index_users_roles_on_user_id_and_role_id` followed by `roles_pkey`.
  scope :non_suspended, lambda { |followable_type, followable_id|
    joins("INNER JOIN users ON users.id = follows.follower_id")
      .where(followable_type: followable_type, followable_id: followable_id, follower_type: "User")
      .where(<<~SQL.squish, %w[suspended spam])
        NOT EXISTS (
          SELECT 1
          FROM users_roles
          INNER JOIN roles ON roles.id = (users_roles.role_id + 0)
          WHERE users_roles.user_id = follows.follower_id
            AND roles.name IN (?)
            AND roles.resource_type IS NULL
            AND roles.resource_id IS NULL
        )
      SQL
  }

  counter_culture :follower, column_name: proc { |follow| COUNTER_CULTURE_COLUMN_NAME_BY_TYPE[follow.followable_type] },
                             column_names: COUNTER_CULTURE_COLUMNS_NAMES
  before_save :calculate_points
  after_create :send_email_notification
  after_save :touch_follower
  after_create_commit :update_user_activities
  after_destroy :update_user_activities

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
    return if follower&.badge_achievements_count&.zero? # Only email if follower is active enough to have received badge
    return unless followable.instance_of?(User) && followable.email?

    Follows::SendEmailNotificationWorker.perform_async(id)
  end

  def update_user_activities
    UserActivity.find_or_create_by(user_id: follower_id).set_activity!
  end
end
