# This model handles a user (subscriber) subscribing to another user (author).
# We also record the source of the subscription (Article, Comment, etc.) via a
# polymorphic association (user_subscription_source/able).
class UserSubscription < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :author, class_name: "User", foreign_key: :author_id, inverse_of: :user_subscriptions
  belongs_to :subscriber, class_name: "User", foreign_key: :subscriber_id, inverse_of: :user_subscriptions
  belongs_to :user_subscription_sourceable, polymorphic: true

  validates :author_id, presence: true
  validates :subscriber_id, presence: true, uniqueness: { scope: %i[user_subscription_sourceable_type user_subscription_sourceable_id] }
  validates :user_subscription_sourceable_id, presence: true
  validates :user_subscription_sourceable_type, presence: true, inclusion: { in: ALLOWED_TYPES }
end
