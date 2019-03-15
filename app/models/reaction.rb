class Reaction < ApplicationRecord
  CATEGORIES = %w[like readinglist unicorn thinking hands thumbsdown vomit].freeze

  belongs_to :reactable, polymorphic: true
  belongs_to :user

  counter_culture :reactable,
    column_name: proc { |model|
      model.points.positive? ? "positive_reactions_count" : "reactions_count"
    }
  counter_culture :user

  validates :category, inclusion: { in: CATEGORIES }
  validates :reactable_type, inclusion: { in: %w[Comment Article] }
  validates :status, inclusion: { in: %w[valid invalid confirmed] }
  validates :user_id, uniqueness: { scope: %i[reactable_id reactable_type category] }
  validate  :permissions

  before_save :assign_points
  after_save :update_reactable, :bust_reactable_cache, :touch_user, :async_bust
  before_destroy :update_reactable_without_delay, unless: :destroyed_by_association
  before_destroy :bust_reactable_cache_without_delay

  class << self
    def count_for_article(id)
      Rails.cache.fetch("count_for_reactable-Article-#{id}", expires_in: 1.hour) do
        reactions = Reaction.where(reactable_id: id, reactable_type: "Article")
        %w[like readinglist unicorn].map do |type|
          { category: type, count: reactions.where(category: type).size }
        end
      end
    end

    def for_display(user)
      includes(:reactable).
        where(reactable_type: "Article", user: user).
        where("created_at > ?", 5.days.ago).
        select("distinct on (reactable_id) *").
        take(15)
    end

    def cached_any_reactions_for?(reactable, user, category)
      cache_name = "any_reactions_for-#{reactable.class.name}-#{reactable.id}-#{user.updated_at}-#{category}"
      Rails.cache.fetch(cache_name, expires_in: 24.hours) do
        Reaction.where(reactable_id: reactable.id, reactable_type: reactable.class.name, user: user, category: category).any?
      end
    end
  end

  private

  def cache_buster
    @cache_buster ||= CacheBuster.new
  end

  def touch_user
    Users::TouchJob.perform_later(user_id)
  end

  def update_reactable
    Reactions::UpdateReactableJob.perform_later(id)
  end

  def bust_reactable_cache
    Reactions::BustReactableCacheJob.perform_later(id)
  end

  def async_bust
    Reactions::BustHomepageCacheJob.perform_later(id)
  end

  def bust_reactable_cache_without_delay
    Reactions::BustReactableCacheJob.perform_now(id)
  end

  def update_reactable_without_delay
    Reactions::UpdateReactableJob.perform_now(id)
  end

  BASE_POINTS = {
    "vomit" => -50.0,
    "thumbsdown" => -10.0
  }.freeze

  def assign_points
    base_points = BASE_POINTS.fetch(category, 1.0)
    base_points = 0 if status == "invalid"
    base_points *= 2 if status == "confirmed"
    self.points = user ? (base_points * user.reputation_modifier) : -5
  end

  def permissions
    errors.add(:category, "is not valid.") if negative_reaction_from_untrusted_user?

    errors.add(:reactable_id, "is not valid.") if reactable_type == "Article" && !reactable&.published
  end

  def negative_reaction_from_untrusted_user?
    negative? && !user.trusted
  end

  def negative?
    category == "vomit" || category == "thumbsdown"
  end
end
