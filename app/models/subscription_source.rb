class SubscriptionSource < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :author, class_name: "User", foreign_key: :author_id, inverse_of: :subscription_sources
  belongs_to :subscriber, class_name: "User", foreign_key: :subscriber_id, inverse_of: :subscription_sources
  belongs_to :subscription_sourceable, polymorphic: true

  validates :author_id, presence: true
  validates :subscriber_id, presence: true, uniqueness: { scope: %i[subscription_sourceable_type subscription_sourceable_id] }
  validates :subscription_sourceable_id, presence: true
  validates :subscription_sourceable_type, presence: true, inclusion: { in: ALLOWED_TYPES }
end
