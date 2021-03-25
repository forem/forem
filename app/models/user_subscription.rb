# This model handles a user (subscriber) subscribing to another user (author).
# We also record the source of the subscription (Article, Comment, etc.) via a
# polymorphic association (user_subscription_source/able).
class UserSubscription < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  counter_culture :subscriber, column_name: "subscribed_to_user_subscriptions_count"
  counter_culture :user_subscription_sourceable, column_name: "user_subscriptions_count"

  belongs_to :author, class_name: "User", inverse_of: :source_authored_user_subscriptions
  belongs_to :subscriber, class_name: "User", inverse_of: :subscribed_to_user_subscriptions
  belongs_to :user_subscription_sourceable, polymorphic: true, optional: true

  validates :author_id, presence: true

  validates :subscriber_email, presence: true
  validates :subscriber_id, presence: true, uniqueness: {
    scope: %i[subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id]
  }

  validates :user_subscription_sourceable_id, presence: true, on: :create
  validates :user_subscription_sourceable_id, presence: true, on: :update, if: :user_subscription_sourceable_type
  validates :user_subscription_sourceable_type, presence: true, on: :create
  validates :user_subscription_sourceable_type, presence: true, on: :update, if: :user_subscription_sourceable_id

  validates :user_subscription_sourceable_type, inclusion: { in: ALLOWED_TYPES }, on: :create
  validates :user_subscription_sourceable_type,
            inclusion: { in: ALLOWED_TYPES }, on: :update, if: :user_subscription_sourceable_id

  validate :tag_enabled
  validate :non_apple_auth_subscriber
  validate :active_user_subscription_source

  def self.build(source:, subscriber:)
    new(build_attributes(source, subscriber))
  end

  def self.make(source:, subscriber:)
    create(build_attributes(source, subscriber))
  end

  def self.build_attributes(source, subscriber)
    {
      user_subscription_sourceable: source,
      author_id: source&.user_id,
      subscriber_id: subscriber&.id,
      subscriber_email: subscriber&.email
    }
  end

  private

  def tag_enabled
    return unless user_subscription_sourceable
    return if liquid_tags_used.include?(UserSubscriptionTag)

    errors.add(:base, "User subscriptions are not enabled for the source.")
  end

  def liquid_tags_used
    MarkdownProcessor::Parser.new(
      user_subscription_sourceable.body_markdown,
      source: user_subscription_sourceable,
      user: user_subscription_sourceable.user,
    ).tags_used
  rescue StandardError # Can occur during parsing for improper tags or bad args
    []
  end

  def non_apple_auth_subscriber
    return unless subscriber_email&.end_with?("@privaterelay.appleid.com")

    errors.add(:subscriber_email, "Can't subscribe with an Apple private relay. Please update email.")
  end

  def active_user_subscription_source
    return unless user_subscription_sourceable

    source_active =
      # Don't create new user subscriptions for inactive sources
      # (i.e. unpublished Articles, deleted Comments, etc.)
      case user_subscription_sourceable_type
      when "Article"
        user_subscription_sourceable.published?
      when "Comment"
        !user_subscription_sourceable.deleted?
      else
        false
      end

    return if source_active

    errors.add(:base, "Source not found. Please make sure your #{user_subscription_sourceable_type} is active!")
  end
end
