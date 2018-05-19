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
  validates :user_id, uniqueness: {:scope => [:reactable_id, :reactable_type, :category]}
  validate  :user_permissions

  before_save :assign_points
  after_save :update_reactable
  before_destroy :update_reactable_without_delay
  after_save :touch_user
  after_save :async_bust
  before_destroy :clean_up_before_destroy

  include StreamRails::Activity
  as_activity

  def self.count_for_reactable(reactable)
    Rails.cache.fetch("count_for_reactable-#{reactable.class.name}-#{reactable.id}", expires_in: 1.hour) do
      [{category:"like",count:Reaction.where(reactable_id:reactable.id, reactable_type: reactable.class.name, category: "like").size},
                                {category:"readinglist",count:Reaction.where(reactable_id:reactable.id, reactable_type: reactable.class.name, category: "readinglist").size},
                                {category:"unicorn",count:Reaction.where(reactable_id:reactable.id, reactable_type: reactable.class.name, category: "unicorn").size}]
    end
  end

  def self.for_display(user)
    self.includes(:reactable).
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
    User.find(reactable.user.id)&.touch(:last_notification_activity)
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
    if reactable_type == "Article"
      reactable.index!
      CacheBuster.new.bust "/reactions/logged_out_reaction_counts?article_id=#{reactable_id}"
    elsif reactable_type == "Comment"
      reactable.save
      CacheBuster.new.bust "/reactions/logged_out_reaction_counts?commentable_id=#{reactable.commentable_id}&commentable_type=#{reactable.commentable_type}"
    end
    CacheBuster.new.bust user.path
  end
  handle_asynchronously :update_reactable

  def touch_user
    user.touch
  end
  handle_asynchronously :touch_user

  def async_bust
    featured_articles = Article.where(featured: true).order('hotness_score DESC').limit(3).pluck(:id)
    if featured_articles.include?(reactable.id)
      reactable.touch
      CacheBuster.new.bust "/"
      CacheBuster.new.bust "/"
      CacheBuster.new.bust "/?i=i"
      CacheBuster.new.bust "?i=i"
    end
  end
  handle_asynchronously :async_bust

  def clean_up_before_destroy
    reactable.index! if reactable_type == "Article"
  end

  def assign_points
    base_points = if category == "vomit"
                    -25.0
                  elsif category == "thumbsdown"
                    -5.0
                  else
                    1.0
                  end
    self.points = user ? (base_points * user.reputation_modifier) : -5
  end

  def user_permissions
    if category == "vomit" || category == "thumbsdown"
      errors.add(:category, "is not valid.") unless user.has_role?(:trusted)
    end
  end
end
