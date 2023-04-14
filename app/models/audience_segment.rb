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

  after_validation :run_query, on: :create

  QUERIES = {
    manual: ->(scope = User) { scope.where(id: nil) },
    trusted: ->(scope = User) { scope.with_role(:trusted) },
    no_posts_yet: ->(scope = User) { scope.where(articles_count: 0) },
    posted: ->(scope = User) { scope.where("articles_count > 0") },
    dark_theme: ->(scope = User) { scope.where(id: Users::Setting.dark_theme.select(:user_id)) },
    light_theme: ->(scope = User) { scope.where(id: Users::Setting.light_theme.select(:user_id)) },
    experience1: ->(scope = User) { scope.with_experience_level(1) },
    experience2: ->(scope = User) { scope.with_experience_level(2) },
    experience3: ->(scope = User) { scope.with_experience_level(3) },
    experience4: ->(scope = User) { scope.with_experience_level(4) },
    experience5: ->(scope = User) { scope.with_experience_level(5) },
    no_experience: ->(scope = User) { scope.with_experience_level(nil) }
  }.freeze

  def self.all_users_in_segment(symbol, scope: User)
    query_for_segment(symbol)&.call(scope) || []
  end

  def self.query_for_segment(symbol)
    QUERIES[symbol.to_sym]
  end

  def self.human_readable_segments
    list = type_ofs.to_a
    (list[1...] + list[0...1]) # move the :manual segment to end of list
      .map { |(type, enum)| [I18n.t("models.#{model_name.i18n_key}.type_ofs.#{type}"), enum] }
  end

  def run_query
    self.users = self.class.all_users_in_segment(type_of)
  end

  def refresh!
    return if manual?

    run_query
    save!
  end
end
