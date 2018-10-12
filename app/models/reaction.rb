class Reaction < ApplicationRecord
  belongs_to :reactable, polymorphic: true
  counter_culture :reactable,
    column_name: proc { |model|
      model.points.positive? ? "positive_reactions_count" : "reactions_count"
    }
  counter_culture :user
  belongs_to :user

  validates :category, inclusion: { in: %w(like thinking hands unicorn thumbsdown vomit readinglist) }
  validates :reactable_type, inclusion: { in: %w(Comment Article) }
  validates :user_id, uniqueness: { scope: %i[reactable_id reactable_type category] }
  validate  :permissions

  before_save :assign_points
  after_save :update_reactable
  before_destroy :update_reactable_without_delay
  after_save :touch_user
  after_save :async_bust
  before_destroy :clean_up_before_destroy

  scope :for_article, ->(id) { where(reactable_id: id, reactable_type: "Article") }

  include StreamRails::Activity
  as_activity

  def self.count_for_article(id)
    Rails.cache.fetch("count_for_reactable-Article-#{id}", expires_in: 1.hour) do
      reactions = Reaction.for_article(id)

      ["like", "readinglist", "unicorn"].map do |type|
        { category: type, count: reactions.where(category: type).size }
      end
    end
  end

  def self.for_display(user)
    includes(:reactable).
      where(reactable_type: "Article", user_id: user.id).
      where("created_at > ?", 5.days.ago).
      select("distinct on (reactable_id) *").
      take(15)
  end

  # notifications

  def activity_object
    self
  end

  def activity_target
    "#{reactable_type}_#{reactable_id}"
  end

  def activity_notify
    return if user_id == reactable.user_id
    return if points.negative?
    [StreamNotifier.new(reactable.user.id).notify]
  end

  def remove_from_feed
    super
    User.find_by(id: reactable.user.id)&.touch(:last_notification_activity)
  end

  def self.cached_any_reactions_for?(reactable, user, category)
    Rails.cache.fetch("any_reactions_for-#{reactable.class.name}-#{reactable.id}-#{user.updated_at}-#{category}", expires_in: 24.hours) do
      Reaction.
        where(reactable_id: reactable.id, reactable_type: reactable.class.name, user_id: user.id, category: category).
        any?
    end
  end

  private

  def update_reactable
    cache_buster = CacheBuster.new
    if reactable_type == "Article"
      reactable.async_score_calc
      reactable.index!
      cache_buster.bust "/reactions?article_id=#{reactable_id}"
    elsif reactable_type == "Comment" && reactable
      reactable.save
      cache_buster.bust "/reactions?commentable_id=#{reactable.commentable_id}&commentable_type=#{reactable.commentable_type}"
    end
    cache_buster.bust user.path
    occasionally_sync_reaction_counts
  end
  handle_asynchronously :update_reactable

  def touch_user
    user.touch
  end
  handle_asynchronously :touch_user

  def async_bust
    featured_articles = Article.where(featured: true).order("hotness_score DESC").limit(3).pluck(:id)
    if featured_articles.include?(reactable.id)
      reactable.touch
      cache_buster = CacheBuster.new
      cache_buster.bust "/"
      cache_buster.bust "/"
      cache_buster.bust "/?i=i"
      cache_buster.bust "?i=i"
    end
  end
  handle_asynchronously :async_bust

  def clean_up_before_destroy
    reactable.index! if reactable_type == "Article"
  end

  BASE_POINTS = {
    "vomit" => -50.0,
    "thumbsdown" => -10.0
  }.freeze

  def assign_points
    base_points = BASE_POINTS.fetch(category, 1.0)
    self.points = user ? (base_points * user.reputation_modifier) : -5
  end

  def permissions
    if negative_reaction_from_untrusted_user?
      errors.add(:category, "is not valid.")
    end

    if reactable_type == "Article" && !reactable.published
      errors.add(:reactable_id, "is not valid.")
    end
  end

  def occasionally_sync_reaction_counts
    # Fixes any out-of-sync positive_reactions_count
    if rand(6) == 1 || reactable.positive_reactions_count.negative?
      reactable.update_column(:positive_reactions_count, reactable.reactions.where("points > ?", 0).size)
    end
  end

  def negative_reaction_from_untrusted_user?
    negative? && !user.trusted
  end

  def negative?
    category == "vomit" || category == "thumbsdown"
  end
end
