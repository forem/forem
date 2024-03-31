class AudienceSegment < ApplicationRecord
  # enum does not like names that start with "not_"
  enum type_of: {
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

  after_validation :persist_recently_active_users, unless: :manual?

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
    left_joins(:segmented_users)
      .select("audience_segments.*, COUNT(segmented_users.id) AS user_count")
      .group("audience_segments.id")
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

  alias refresh! save!
end
