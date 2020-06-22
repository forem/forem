# This model handles a user (subscriber) subscribing to another user (author).
# We also record the source of the subscription (Article, Comment, etc.) via a
# polymorphic association (user_subscription_source/able).
class UserSubscription < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :author, class_name: "User", inverse_of: :source_authored_user_subscriptions
  belongs_to :subscriber, class_name: "User", inverse_of: :subscribed_to_user_subscriptions
  belongs_to :user_subscription_sourceable, polymorphic: true

  validates :author_id, presence: true
  validates :subscriber_email, presence: true
  validates :subscriber_id, presence: true, uniqueness: { scope: %i[subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id] }
  validates :user_subscription_sourceable_id, presence: true
  validates :user_subscription_sourceable_type, presence: true, inclusion: { in: ALLOWED_TYPES }

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
end
