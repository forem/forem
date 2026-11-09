class AudienceSegment < ApplicationRecord
  # enum does not like names that start with "not_"
  enum :type_of, {
    manual: 0, # never matches anyone, used in test factory
    trusted: 1,
    posted: 2,
    no_posts_yet: 3,
    dark_theme: 4,
    light_theme: 5,
    no_experience: 6,
    experience1: 7,
    experience2: 8,
    experience3: 9,
    experience4: 10,
    experience5: 11
  }

  has_many :segmented_users, dependent: :destroy
  has_many :users, through: :segmented_users
  has_many :emails, dependent: :restrict_with_error

  validates :name, length: { maximum: 255 }, allow_nil: true
  validates :name, uniqueness: { case_sensitive: false }, allow_nil: true, if: -> { name.present? }
  validate :name_cannot_be_cleared, if: -> { manual? && persisted? && name_was.present? }

  SYSTEM_USER_COUNTS_CACHE_KEY = "audience_segments/system_user_counts".freeze

  attr_writer :user_count

  after_validation :persist_recently_active_users, unless: :manual?
  before_destroy :ensure_not_in_use_and_destroyable
  after_commit :expire_system_user_counts_cache, unless: :manual?

  QUERIES = {
    manual: ->(scope = User) { scope.where(id: nil) },
    trusted: ->(scope = User) { scope.with_role(:trusted) },
    no_posts_yet: ->(scope = User) { scope.where(articles_count: 0) },
    posted: ->(scope = User) { scope.where("articles_count > 0") },
    dark_theme: ->(scope = User) { scope.where(id: Users::Setting.dark_theme.select(:user_id)) },
    light_theme: ->(scope = User) { scope.where(id: Users::Setting.light_theme.select(:user_id)) },
    experience1: ->(scope = User) { scope.with_experience_level(1) },
    # see SettingsHelper#user_experience_levels
    experience2: ->(scope = User) { scope.with_experience_level(3) },
    experience3: ->(scope = User) { scope.with_experience_level(5) },
    experience4: ->(scope = User) { scope.with_experience_level(8) },
    experience5: ->(scope = User) { scope.with_experience_level(10) },
    no_experience: ->(scope = User) { scope.with_experience_level(nil) }
  }.freeze

  def self.scoped_users_in_segment(segment_type, scope: nil)
    query_for_segment(segment_type)&.call(scope) || []
  end

  def self.all_users_in_segment(segment_type, scope: User)
    query_for_segment(segment_type)&.call(scope) || []
  end

  def self.recently_active_users_in_segment(segment_type, scope: User.recently_active)
    scoped_users_in_segment(segment_type, scope: scope)
  end

  def self.query_for_segment(segment_type)
    QUERIES[segment_type.to_sym]
  end

  def self.human_readable_description_for(type)
    I18n.t("models.#{model_name.i18n_key}.type_ofs.#{type}")
  end

  def self.including_user_counts
    select(
      "audience_segments.*, " \
      "(SELECT COUNT(*) FROM segmented_users " \
      "WHERE segmented_users.audience_segment_id = audience_segments.id) AS user_count",
    )
  end

  def self.system_segments_with_cached_counts
    segments = not_manual.order(:type_of).to_a
    return segments if segments.empty?

    segment_ids = segments.map(&:id)
    counts = Rails.cache.fetch(SYSTEM_USER_COUNTS_CACHE_KEY, expires_in: 15.minutes) do
      SegmentedUser.where(audience_segment_id: segment_ids).group(:audience_segment_id).count
    end
    segments.each { |segment| segment.user_count = counts[segment.id].to_i }
  end

  def persist_recently_active_users
    self.users = self.class.recently_active_users_in_segment(type_of)
  end

  def all_users_in_segment
    return users if manual?

    self.class.all_users_in_segment(type_of)
  end

  def includes?(user_or_id)
    user_id = user_or_id.respond_to?(:id) ? user_or_id.id : user_or_id
    all_users_in_segment.exists?(user_id)
  end

  def display_name
    name.presence || self.class.human_readable_description_for(type_of)
  end

  def user_count
    return @user_count if defined?(@user_count)

    @user_count = has_attribute?(:user_count) ? self[:user_count].to_i : segmented_users.count
  end

  def email_eligible_users
    users.email_eligible
  end

  alias refresh! save!

  private

  def ensure_not_in_use_and_destroyable
    unless manual?
      errors.add(:base, "System audience segments cannot be destroyed.")
      throw :abort
    end

    if Billboard.approved_and_published.exists?(audience_segment_id: id)
      errors.add(:base, "Cannot delete audience segment while in use by billboards.")
      throw :abort
    end

    return unless emails.exists?

    errors.add(:base, "Cannot delete audience segment while associated with emails.")
    throw :abort
  end

  def name_cannot_be_cleared
    errors.add(:name, :blank) if name.blank?
  end

  def expire_system_user_counts_cache
    Rails.cache.delete(SYSTEM_USER_COUNTS_CACHE_KEY)
  end
end
