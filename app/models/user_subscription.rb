# This model handles a user (subscriber) subscribing to another user (author).
# We also record the source of the subscription (Article, Comment, etc.) via a
# polymorphic association (user_subscription_source/able).
class UserSubscription < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  counter_culture :subscriber, column_name: "subscribed_to_user_subscriptions_count"

  belongs_to :author, class_name: "User", inverse_of: :source_authored_user_subscriptions
  belongs_to :subscriber, class_name: "User", inverse_of: :subscribed_to_user_subscriptions
  belongs_to :user_subscription_sourceable, polymorphic: true

  validates :author_id, presence: true
  validates :subscriber_email, presence: true
  validates :subscriber_id, presence: true, uniqueness: { scope: %i[subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id] }
  validates :user_subscription_sourceable_id, presence: true
  validates :user_subscription_sourceable_type, presence: true, inclusion: { in: ALLOWED_TYPES }

  validate :active_user_subscription_source
  validate :tag_enabled
  validate :non_apple_auth_subscriber

  # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
  # validate :subscriber_email_is_current

  def self.build(source:, subscriber:, subscriber_email: nil)
    new(build_attributes(source, subscriber, subscriber_email))
  end

  def self.make(source:, subscriber:, subscriber_email: nil)
    create(build_attributes(source, subscriber, subscriber_email))
  end

  def self.build_attributes(source, subscriber, subscriber_email)
    {
      user_subscription_sourceable: source,
      author_id: source&.user_id,
      subscriber_id: subscriber&.id,
      subscriber_email: subscriber_email || subscriber&.email
    }
  end

  private

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

    errors.add(:base, "Inactive source.")
  end

  def tag_enabled
    return unless user_subscription_sourceable

    liquid_tags =
      case user_subscription_sourceable_type
      when "Article"
        user_subscription_sourceable.liquid_tags_used(:body)
      else
        user_subscription_sourceable.liquid_tags_used
      end

    return if liquid_tags.include?(UserSubscriptionTag)

    errors.add(:base, "User subscriptions are not enabled for the source.")
  end

  def non_apple_auth_subscriber
    return unless subscriber_email&.end_with?("@privaterelay.appleid.com")

    errors.add(:subscriber_email, "Can't subscribe with an Apple private relay. Please update email.")
  end

  # This checks if the email address the user saw/consented to share is the
  # same as their current email address. A mismatch occurs if a user updates
  # their email address in a new/separate tab and then tries to subscribe on
  # the old/stale tab without refreshing. In that case, the user would have
  # consented to share their old email address instead of the current one.
  def subscriber_email_is_current
    return if user_subscription_sourceable&.user&.email == subscriber_email

    errors.add(:subscriber_email, "Subscriber email mismatch.")
  end
end
