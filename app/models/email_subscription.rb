class EmailSubscription < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :email_subscribable, polymorphic: true
  belongs_to :subscriber, class_name: "User", foreign_key: :user_id, inverse_of: :email_subscriptions

  validates :email_subscribable_type, presence: true
  validates :email_subscribable_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: %i[email_subscribable_type email_subscribable_id] }
  validates :email_subscribable_type, inclusion: { in: ALLOWED_TYPES }
end
