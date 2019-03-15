class PushNotificationSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :p256dh_key, presence: true, uniqueness: true
  validates :auth_key, presence: true, uniqueness: true
  validates :notification_type, presence: true, inclusion: { in: %w[browser] }
  belongs_to :user
end
