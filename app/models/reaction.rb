class Reaction < ApplicationRecord
  REACTABLE_TYPES = %w[Comment Article User].freeze
  STATUSES = %w[valid invalid confirmed archived].freeze

  belongs_to :reactable, polymorphic: true
  belongs_to :user

  counter_culture :reactable,
                  column_name: proc { |model|
                    ReactionCategory[model.category].visible_to_public? ? "public_reactions_count" : "reactions_count"
                  }
  counter_culture :user

  scope :public_category, -> { where(category: ReactionCategory.public.map(&:to_s)) }

  # Be wary, this is all things on the reading list, but for an end
  # user they might only see readinglist items that are published.
  # See https://github.com/forem/forem/issues/14796
  scope :readinglist, -> { where(category: "readinglist") }
  scope :for_articles, ->(ids) { only_articles.where(reactable_id: ids) }
  scope :only_articles, -> { where(reactable_type: "Article") }
  scope :eager_load_serialized_data, -> { includes(:reactable, :user) }
  scope :article_vomits, -> { where(category: "vomit", reactable_type: "Article") }
  scope :comment_vomits, -> { where(category: "vomit", reactable_type: "Comment") }
  scope :user_vomits, -> { where(category: "vomit", reactable_type: "User") }
  scope :valid_or_confirmed, -> { where(status: %w[valid confirmed]) }
  scope :related_negative_reactions_for_user, lambda { |user|
    article_vomits.where(reactable_id: user.article_ids)
      .or(comment_vomits.where(reactable_id: user.comment_ids))
      .or(user_vomits.where(user_id: user.id))
  }
  scope :privileged_category, -> { where(category: ReactionCategory.privileged.map(&:to_s)) }
  scope :for_user, ->(user) { where(reactable: user) }
  scope :unarchived, -> { where.not(status: "archived") }
  scope :from_user, ->(user) { where(user: user) }
  scope :readinglist_for_user, ->(user) { readinglist.unarchived.only_articles.from_user(user) }

  validates :category, inclusion: { in: ReactionCategory.all_slugs.map(&:to_s) }
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
  after_commit :record_field_test_event, on: %i[create]

  class << self
    def count_for_article(id)
      Rails.cache.fetch("count_for_reactable-Article-#{id}", expires_in: 10.hours) do
        reactions = Reaction.where(reactable_id: id, reactable_type: "Article")
        counts = reactions.group(:category).count

        reaction_types = %w[like readinglist]
        unless FeatureFlag.enabled?(:replace_unicorn_with_jump_to_comments)
          reaction_types << "unicorn"
        end

        reaction_types.map do |type|
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

    # @param user [User] the user who might be spamming the system
    # @param threshold [Integer] the number of strikes before they are spam
    # @param include_user_profile [Boolean] do we include the user's profile as part of the "check
    #        for spamminess"
    #
    # @return [TrueClass] yup, they're spamming the system.
    # @return [FalseClass] they're not (yet) spamming the system
    def user_has_been_given_too_many_spammy_article_reactions?(user:, threshold: 2, include_user_profile: false)
      threshold -= 1 if include_user_profile && user_has_spammy_profile_reaction?(user: user)
      article_vomits.where(reactable_id: user.articles.ids).size > threshold
    end

    # @param user [User] the user who might be spamming the system
    # @param threshold [Integer] the number of strikes before they are spam
    # @param include_user_profile [Boolean] do we include the user's profile as part of the "check
    #        for spamminess"
    #
    # @return [TrueClass] yup, they're spamming the system.
    # @return [FalseClass] they're not (yet) spamming the system
    def user_has_been_given_too_many_spammy_comment_reactions?(user:, threshold: 2, include_user_profile: false)
      threshold -= 1 if include_user_profile && user_has_spammy_profile_reaction?(user: user)
      comment_vomits.where(reactable_id: user.comments.ids).size > threshold
    end

    # @param user [User] the user who might be spamming the system
    def user_has_spammy_profile_reaction?(user:)
      user_vomits.exists?(reactable_id: user.id)
    end

    # @param category [String] the reaction category type, see the CATEGORIES var
    # @param reactable_id [Boolean] the ID of the item that was reacted on
    # @param reactable_type [String] the type of the item, see the REACTABLE_TYPES var
    # @param user [User] a moderator user

    # @return [Array] Reactions that contain a contradictory category to the category that was passed in,
    # example, if we pass in a "thumbsup", then we return reactions that have have a thumbsdown or vomit
    def contradictory_mod_reactions(category:, reactable_id:, reactable_type:, user:)
      negatives = ReactionCategory.negative_privileged.map(&:to_s)
      contradictory_category = negatives if category == "thumbsup"
      contradictory_category = "thumbsup" if category.in?(negatives)

      Reaction.where(reactable_id: reactable_id,
                     reactable_type: reactable_type,
                     user: user,
                     category: contradictory_category)
    end
  end

  # no need to send notification if:
  # - reaction is negative
  # - receiver is the same user as the one who reacted
  # - reaction status is marked invalid
  def skip_notification_for?(_receiver)
    reactor_id = case reactable
                 when User
                   reactable.id
                 else
                   reactable.user_id
                 end

    (status == "invalid") || points.negative? || (user_id == reactor_id)
  end

  def reaction_on_organization_article?
    reactable_type == "Article" && reactable.organization.present?
  end

  def target_user
    reactable_type == "User" ? reactable : reactable.user
  end

  delegate :negative?, :positive?, :visible_to_public?, to: :reaction_category, allow_nil: true

  def reaction_category
    ReactionCategory[category.to_sym]
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
    self.points = CalculateReactionPoints.call(self)
  end

  def permissions
    errors.add(:category, I18n.t("models.reaction.is_not_valid")) if negative_reaction_from_untrusted_user?
    return unless reactable_type == "Article" && !reactable&.published

    errors.add(:reactable_id, I18n.t("models.reaction.is_not_valid"))
  end

  def negative_reaction_from_untrusted_user?
    return if user&.any_admin? || user&.id == Settings::General.mascot_user_id

    negative? && !user.trusted?
  end

  def notify_slack_channel_about_vomit_reaction
    Slack::Messengers::ReactionVomit.call(reaction: self)
  end

  # @see AbExperiment::GoalConversionHandler
  def record_field_test_event
    # TODO: Remove once we know that this test is not over-heating the application.  That would be a
    # few days after the deploy to DEV of this change.
    return unless FeatureFlag.accessible?(:field_test_event_for_reactions)
    return if FieldTest.config["experiments"].nil?
    return unless visible_to_public?
    return unless reactable.is_a?(Article)
    return unless user_id

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, AbExperiment::GoalConversionHandler::USER_CREATES_ARTICLE_REACTION_GOAL)
  end
end
