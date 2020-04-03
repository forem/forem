class Reaction < ApplicationRecord
  include AlgoliaSearch
  include Searchable

  SEARCH_SERIALIZER = Search::ReactionSerializer
  SEARCH_CLASS = Search::Reaction

  CATEGORIES = %w[like readinglist unicorn thinking hands thumbsdown vomit].freeze
  REACTABLE_TYPES = %w[Comment Article User].freeze
  STATUSES = %w[valid invalid confirmed archived].freeze

  belongs_to :reactable, polymorphic: true
  belongs_to :user

  counter_culture :reactable,
                  column_name: proc { |model|
                    model.points.positive? ? "positive_reactions_count" : "reactions_count"
                  }
  counter_culture :user

  scope :positive, -> { where("points > ?", 0) }
  scope :readinglist, -> { where(category: "readinglist") }

  validates :category, inclusion: { in: CATEGORIES }
  validates :reactable_type, inclusion: { in: REACTABLE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: %i[reactable_id reactable_type category] }
  validate  :permissions

  after_create :notify_slack_channel_about_vomit_reaction, if: -> { category == "vomit" }
  before_save :assign_points
  after_create_commit :record_field_test_event
  after_commit :async_bust, :bust_reactable_cache, :update_reactable
  after_commit :index_to_elasticsearch, if: :indexable?, on: %i[create update]
  after_commit :remove_from_elasticsearch, if: :indexable?, on: [:destroy]
  after_save :index_to_algolia
  after_save :touch_user
  before_destroy :update_reactable_without_delay, unless: :destroyed_by_association
  before_destroy :bust_reactable_cache_without_delay
  before_destroy :remove_algolia

  algoliasearch index_name: "SecuredReactions_#{Rails.env}", auto_index: false, auto_remove: false do
    attribute :id, :reactable_user, :searchable_reactable_title, :searchable_reactable_path, :status, :reading_time,
              :searchable_reactable_text, :searchable_reactable_tags, :viewable_by, :reactable_tags, :reactable_published_date
    searchableAttributes %i[searchable_reactable_title searchable_reactable_text
                            searchable_reactable_tags reactable_user]
    tags do
      reactable_tags
    end
    attributesForFaceting ["filterOnly(viewable_by)", "filterOnly(status)"]
    customRanking ["desc(id)"]
  end

  def index_to_algolia
    index! if category == "readinglist" && reactable && reactable.published
  end

  class << self
    def count_for_article(id)
      Rails.cache.fetch("count_for_reactable-Article-#{id}", expires_in: 1.hour) do
        reactions = Reaction.where(reactable_id: id, reactable_type: "Article")
        counts = reactions.group(:category).count

        %w[like readinglist unicorn].map do |type|
          { category: type, count: counts.fetch(type, 0) }
        end
      end
    end

    def cached_any_reactions_for?(reactable, user, category)
      class_name = reactable.class.name == "ArticleDecorator" ? "Article" : reactable.class.name
      cache_name = "any_reactions_for-#{class_name}-#{reactable.id}-#{user.updated_at&.rfc3339}-#{category}"
      Rails.cache.fetch(cache_name, expires_in: 24.hours) do
        Reaction.where(reactable_id: reactable.id, reactable_type: class_name, user: user, category: category).any?
      end
    end
  end

  # no need to send notification if:
  # - reaction is negative
  # - receiver is the same user as the one who reacted
  # - receive_notification is disabled
  def skip_notification_for?(receiver)
    points.negative? ||
      (user_id == reactable.user_id) ||
      (receiver.is_a?(User) && reactable.receive_notifications == false)
  end

  def vomit_on_user?
    reactable_type == "User" && category == "vomit"
  end

  def reaction_on_organization_article?
    reactable_type == "Article" && reactable.organization.present?
  end

  def target_user
    if reactable_type == "User"
      reactable
    else
      reactable.user
    end
  end

  def negative?
    category == "vomit" || category == "thumbsdown"
  end

  private

  def indexable?
    category == "readinglist" && reactable && reactable.published
  end

  def touch_user
    user.touch
  end

  def update_reactable
    Reactions::UpdateReactableWorker.perform_async(id)
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
    Reactions::UpdateReactableWorker.new.perform(id)
  end

  def reading_time
    reactable.reading_time if category == "readinglist"
  end

  def remove_from_index
    remove_from_index!
  end

  def reactable_user
    return unless category == "readinglist"

    {
      username: reactable.user_username,
      name: reactable.user_name,
      profile_image_90: reactable.user.profile_image_90
    }
  end

  def reactable_published_date
    reactable.readable_publish_date if category == "readinglist"
  end

  def searchable_reactable_title
    reactable.title if category == "readinglist"
  end

  def searchable_reactable_text
    reactable.body_text[0..350] if category == "readinglist"
  end

  def searchable_reactable_tags
    reactable.cached_tag_list if category == "readinglist"
  end

  def searchable_reactable_path
    reactable.path if category == "readinglist"
  end

  def reactable_tags
    reactable.decorate.cached_tag_list_array if category == "readinglist"
  end

  def viewable_by
    user_id
  end

  BASE_POINTS = {
    "vomit" => -50.0,
    "thumbsdown" => -10.0
  }.freeze

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
    return if user&.any_admin?

    negative? && !user.trusted
  end

  def remove_algolia
    remove_from_index!
  end

  def record_field_test_event
    Users::RecordFieldTestEventWorker.perform_async(user_id, :user_home_feed, "user_creates_reaction")
  end

  def notify_slack_channel_about_vomit_reaction
    Slack::Messengers::ReactionVomit.call(reaction: self)
  end
end
