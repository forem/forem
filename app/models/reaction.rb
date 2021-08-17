class Reaction < ApplicationRecord
  BASE_POINTS = {
    "vomit" => -50.0,
    "thumbsup" => 5.0,
    "thumbsdown" => -10.0
  }.freeze

  CATEGORIES = %w[like readinglist unicorn thinking hands thumbsup thumbsdown vomit].freeze
  PUBLIC_CATEGORIES = %w[like readinglist unicorn thinking hands].freeze
  REACTABLE_TYPES = %w[Comment Article User].freeze
  STATUSES = %w[valid invalid confirmed archived].freeze

  belongs_to :reactable, polymorphic: true
  belongs_to :user

  counter_culture :reactable,
                  column_name: proc { |model|
                    PUBLIC_CATEGORIES.include?(model.category) ? "public_reactions_count" : "reactions_count"
                  }
  counter_culture :user

  scope :public_category, -> { where(category: PUBLIC_CATEGORIES) }
  scope :readinglist, -> { where(category: "readinglist") }
  scope :for_articles, ->(ids) { where(reactable_type: "Article", reactable_id: ids) }
  scope :eager_load_serialized_data, -> { includes(:reactable, :user) }
  scope :article_vomits, -> { where(category: "vomit", reactable_type: "Article") }
  scope :comment_vomits, -> { where(category: "vomit", reactable_type: "Comment") }

  validates :category, inclusion: { in: CATEGORIES }
  validates :reactable_type, inclusion: { in: REACTABLE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: %i[reactable_id reactable_type category] }
  validate  :permissions

  before_save :assign_points
  after_create :notify_slack_channel_about_vomit_reaction, if: -> { category == "vomit" }
  before_destroy :bust_reactable_cache_without_delay
  before_destroy :update_reactable_without_delay, unless: :destroyed_by_association
  after_commit :async_bust
  after_commit :bust_reactable_cache, :update_reactable, on: %i[create update]

  class << self
    def count_for_article(id)
      Rails.cache.fetch("count_for_reactable-Article-#{id}", expires_in: 10.hours) do
        reactions = Reaction.where(reactable_id: id, reactable_type: "Article")
        counts = reactions.group(:category).count

        %w[like readinglist unicorn].map do |type|
          { category: type, count: counts.fetch(type, 0) }
        end
      end
    end

    def cached_any_reactions_for?(reactable, user, category)
      class_name = reactable.instance_of?(ArticleDecorator) ? "Article" : reactable.class.name
      cache_name = "any_reactions_for-#{class_name}-#{reactable.id}-" \
                   "#{user.reactions_count}-#{user.public_reactions_count}-#{category}"
      Rails.cache.fetch(cache_name, expires_in: 24.hours) do
        Reaction.where(reactable_id: reactable.id, reactable_type: class_name, user: user, category: category).any?
      end
    end
  end

  # no need to send notification if:
  # - reaction is negative
  # - receiver is the same user as the one who reacted
  # - receive_notification is disabled
  def skip_notification_for?(_receiver)
    reactor_id = case reactable
                 when User
                   reactable.id
                 else
                   reactable.user_id
                 end

    points.negative? || (user_id == reactor_id)
  end

  def vomit_on_user?
    reactable_type == "User" && category == "vomit"
  end

  def reaction_on_organization_article?
    reactable_type == "Article" && reactable.organization.present?
  end

  def target_user
    reactable_type == "User" ? reactable : reactable.user
  end

  def negative?
    category == "vomit" || category == "thumbsdown"
  end

  private

  def update_reactable
    Reactions::UpdateRelevantScoresWorker.perform_async(id)
  end

  def bust_reactable_cache
    Reactions::BustReactableCacheWorker.perform_async(id)
  end

  def async_bust
    Reactions::BustHomepageCacheWorker.perform_async(id)
  end

  def bust_reactable_cache_without_delay
    Reactions::BustReactableCacheWorker.new.perform(id)
  end

  def update_reactable_without_delay
    Reactions::UpdateRelevantScoresWorker.new.perform(id)
  end

  def reading_time
    reactable.reading_time if category == "readinglist"
  end

  def viewable_by
    user_id
  end

  def assign_points
    base_points = BASE_POINTS.fetch(category, 1.0)
    base_points = 0 if status == "invalid"
    base_points /= 2 if reactable_type == "User"
    base_points *= 2 if status == "confirmed"
    self.points = user ? (base_points * user.reputation_modifier) : -5
  end

  def permissions
    errors.add(:category, "is not valid.") if negative_reaction_from_untrusted_user?

    errors.add(:reactable_id, "is not valid.") if reactable_type == "Article" && !reactable&.published
  end

  def negative_reaction_from_untrusted_user?
    return if user&.any_admin? || user&.id == Settings::General.mascot_user_id

    negative? && !user.trusted
  end

  def notify_slack_channel_about_vomit_reaction
    Slack::Messengers::ReactionVomit.call(reaction: self)
  end
end
